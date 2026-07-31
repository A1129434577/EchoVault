import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/core/persistence/media_repository.dart';
import 'package:echo_vault/core/networking/playback_http_transport.dart';

///所有有返回FileInfo的方法都需要外部更新数据库
///其他需要更新数据库的下载状态：
///enqueued且downloadTaskId!=null
///complete、failed、canceled、paused
///强杀app的话DownloadTask的状态变成了canceled
///下载和缓存路径都是先放入temp文件夹，防止因暂停下载等状态时文件不完整，但是却判断文件为已下载的情况
@pragma('vm:item-point')
class MediaTransferService {
  static const String _downloaderSendPortName = 'flutter_downloader_send_port';

  //下载中的文件taskId:FileInfo
  static Map<String, FileInfo> downloadingFilesMap = {};
  //缓存中的文件taskId:FileInfo
  static Map<String, FileInfo> cachingFilesMap = {};
  static final StreamController<FileInfo> _downloaderController =
      StreamController.broadcast();
  static final StreamController<TransferStartInfo> _downloaderStartController =
      StreamController.broadcast();

  //下载开始流
  static Stream<TransferStartInfo> get downloadStartStream =>
      _downloaderStartController.stream;

  //下载详细状态更新流
  static Stream<FileInfo> get downloadStream => _downloaderController.stream;

  ///缓存
  static Future<String?> cache({
    required FileInfo mediaEntry,
    PlayerHttpClientInterface? httpClientArg,
  }) async {
    String filePathLocal = await mediaEntry.filePath;
    String cachedMediaPath = await mediaEntry.cacheFilePath;

    File fileLocal = File(filePathLocal);
    if (fileLocal.existsSync()) {
      return filePathLocal;
    }
    File cacheFileLocal = File(cachedMediaPath);
    if (cacheFileLocal.existsSync()) {
      return cachedMediaPath;
    }

    String? resultPathLocal = await syncTaskToFileInfo(
      mediaEntry,
      cacheArg: true,
    );
    if (resultPathLocal != null) {
      return resultPathLocal;
    }

    String? resourceUrl = await httpClientArg?.getFileUrl(fileInfo: mediaEntry);
    resourceUrl ??= await httpClientArg?.getFileUrl(fileInfo: mediaEntry);
    resourceUrl ??= await httpClientArg?.getFileUrl(fileInfo: mediaEntry);
    if (resourceUrl == null) {
      return null;
    }

    String destinationDirectory = await FileInfo.filesTempDirectoryPath;
    String? cacheDownloadTaskIdLocal = await FlutterDownloader.enqueue(
      url: resourceUrl,
      headers: {},
      savedDir: destinationDirectory,
      fileName: mediaEntry.fileName,
      showNotification: false,
      openFileFromNotification: false,
    );
    mediaEntry.cacheDownloadTaskId = cacheDownloadTaskIdLocal;
    if (cacheDownloadTaskIdLocal != null) {
      cachingFilesMap[cacheDownloadTaskIdLocal] = mediaEntry;
    }
    return cacheDownloadTaskIdLocal;
  }

  ///取消下载
  static Future cancel(FileInfo mediaEntry) async {
    List<DownloadTask>?
    taskListLocal = await FlutterDownloader.loadTasksWithRawQuery(
      query:
          'SELECT * FROM task WHERE task_id = "${mediaEntry.downloadTaskId}"',
    );
    if (taskListLocal?.isNotEmpty == true) {
      DownloadTask transferTaskLocal = taskListLocal!.first;
      if (transferTaskLocal.status == DownloadTaskStatus.enqueued ||
          transferTaskLocal.status == DownloadTaskStatus.running ||
          transferTaskLocal.status == DownloadTaskStatus.paused) {
        await FlutterDownloader.cancel(taskId: transferTaskLocal.taskId);
        if (transferTaskLocal.status == DownloadTaskStatus.paused) {
          //暂停的任务好像取消没反应，这里直接通知出去处理一次
          mediaEntry.downloadStatus = DownloadTaskStatus.canceled.index;
          _downloaderController.add(mediaEntry);
        }
      } else {
        remove(mediaEntry);
      }
    } else {
      mediaEntry.downloadStatus = DownloadTaskStatus.canceled.index;
      _downloaderController.add(mediaEntry);
    }
  }

  ///下载
  static Future<String?> download({
    required FileInfo mediaEntry,
    bool isClickArg = true,
  }) async {
    _downloaderStartController.add(
      TransferStartInfo(mediaDetails: mediaEntry, isClick: isClickArg),
    );

    mediaEntry.downloadStatus = DownloadTaskStatus.enqueued.index;
    _downloaderController.add(mediaEntry);

    String filePathLocal = await mediaEntry.filePath;
    String cachedMediaPath = await mediaEntry.cacheFilePath;

    File fileLocal = File(filePathLocal);
    if (fileLocal.existsSync()) {
      //文件已下载
      mediaEntry.downloadStatus = DownloadTaskStatus.complete.index;
      _downloaderController.add(mediaEntry);
      return null;
    }
    File cacheFileLocal = File(cachedMediaPath);
    if (cacheFileLocal.existsSync()) {
      compute((rootIsolateTokenInputArg) async {
        BackgroundIsolateBinaryMessenger.ensureInitialized(
          rootIsolateTokenInputArg,
        );
        cacheFileLocal.copySync(filePathLocal);
        cacheFileLocal.deleteSync();
      }, RootIsolateToken.instance!);
      mediaEntry.downloadStatus = DownloadTaskStatus.complete.index;
      _downloaderController.add(mediaEntry);
      return filePathLocal;
    }

    String? resultPathLocal = await syncTaskToFileInfo(mediaEntry);
    if (resultPathLocal != null) {
      mediaEntry.downloadStatus = DownloadTaskStatus.complete.index;
      _downloaderController.add(mediaEntry);
      return resultPathLocal;
    }
    PlaybackHttpTransport httpClientLocal = PlaybackHttpTransport();
    String? resourceUrl = await httpClientLocal.getFileUrl(
      fileInfo: mediaEntry,
    );
    if (resourceUrl == null) {
      await Future.delayed(Duration(milliseconds: 200));
      resourceUrl = await httpClientLocal.getFileUrl(fileInfo: mediaEntry);
    }
    if (resourceUrl == null) {
      await Future.delayed(Duration(milliseconds: 200));
      resourceUrl = await httpClientLocal.getFileUrl(fileInfo: mediaEntry);
    }
    if (resourceUrl == null) {
      mediaEntry.downloadStatus = DownloadTaskStatus.failed.index;
      _downloaderController.add(mediaEntry);
      //文件下载地址获取失败
      return null;
    }

    Completer<String?> completerLocal = Completer();
    StreamSubscription? flutterDownloadSubLocal;
    flutterDownloadSubLocal = downloadStream.listen((
      newFileInfoInputArg,
    ) async {
      if (mediaEntry.fileId == newFileInfoInputArg.fileId) {
        if (newFileInfoInputArg.downloadStatus ==
                DownloadTaskStatus.complete.index ||
            newFileInfoInputArg.downloadStatus ==
                DownloadTaskStatus.failed.index ||
            newFileInfoInputArg.downloadStatus ==
                DownloadTaskStatus.canceled.index) {
          flutterDownloadSubLocal?.cancel();
          if (completerLocal.isCompleted == false) {
            if (newFileInfoInputArg.downloadStatus ==
                DownloadTaskStatus.complete.index) {
              completerLocal.complete(filePathLocal);
            } else {
              completerLocal.complete();
            }
          }
        }
      }
    });

    String destinationDirectory = await FileInfo.filesTempDirectoryPath;
    String? downloadTaskIdLocal = await FlutterDownloader.enqueue(
      url: resourceUrl,
      headers: {},
      savedDir: destinationDirectory,
      fileName: mediaEntry.fileName,
      showNotification: false,
      openFileFromNotification: false,
    );
    mediaEntry.downloadTaskId = downloadTaskIdLocal;
    if (downloadTaskIdLocal != null) {
      downloadingFilesMap[downloadTaskIdLocal] = mediaEntry;
    }
    return completerLocal.future;
  }

  @pragma('vm:item-point')
  static void downloadCallback(
    String idArg,
    int currentStatus,
    int progressArg,
  ) {
    final SendPort? sendLocal = IsolateNameServer.lookupPortByName(
      _downloaderSendPortName,
    );
    sendLocal?.send([idArg, currentStatus, progressArg]);
  }

  static Future initSdk() async {
    await FlutterDownloader.initialize(debug: true, ignoreSsl: true);
    IsolateNameServer.removePortNameMapping(_downloaderSendPortName);
    ReceivePort receivePortLocal = ReceivePort();
    IsolateNameServer.registerPortWithName(
      receivePortLocal.sendPort,
      _downloaderSendPortName,
    );
    receivePortLocal.listen((dynamic payload) async {
      String taskIdLocal = payload[0];
      DownloadTaskStatus newStatusLocal = DownloadTaskStatus.fromInt(
        payload[1],
      );
      //进度0-1
      int newProgressLocal = payload[2];

      FileInfo? mediaEntry = downloadingFilesMap[taskIdLocal];
      if (mediaEntry == null) {
        List<FileInfo> mediaEntries = await MediaRepository.queryFileInfo(
          whereArg: 'download_task_id = "$taskIdLocal"',
        );
        if (mediaEntries.isNotEmpty) {
          mediaEntry = mediaEntries.first;
          downloadingFilesMap[taskIdLocal] = mediaEntry;
        }
      }
      if (mediaEntry != null) {
        if (newStatusLocal == DownloadTaskStatus.complete) {
          compute((rootIsolateTokenInputArg) async {
            BackgroundIsolateBinaryMessenger.ensureInitialized(
              rootIsolateTokenInputArg,
            );
            //下载完成后将文件拷贝至对应文件夹
            File tempFileLocal = File(await mediaEntry!.tempFilePath);
            if (tempFileLocal.existsSync()) {
              tempFileLocal.copySync(await mediaEntry.filePath);
              tempFileLocal.deleteSync();
            }
          }, RootIsolateToken.instance!);
        }
        mediaEntry.downloadProgress = newProgressLocal;
        mediaEntry.downloadStatus = newStatusLocal.index;
        _downloaderController.add(mediaEntry);

        if (newStatusLocal == DownloadTaskStatus.complete ||
            newStatusLocal == DownloadTaskStatus.failed ||
            newStatusLocal == DownloadTaskStatus.canceled) {
          downloadingFilesMap.remove(taskIdLocal);
        }
      }

      FileInfo? cacheFileInfoLocal = cachingFilesMap[taskIdLocal];
      if (cacheFileInfoLocal != null) {
        if (newStatusLocal == DownloadTaskStatus.complete) {
          compute((rootIsolateTokenInputArg) async {
            BackgroundIsolateBinaryMessenger.ensureInitialized(
              rootIsolateTokenInputArg,
            );
            //下载完成后将文件拷贝至对应文件夹
            File tempFileLocal = File(await cacheFileInfoLocal.tempFilePath);
            if (tempFileLocal.existsSync()) {
              tempFileLocal.copySync(await cacheFileInfoLocal.cacheFilePath);
              tempFileLocal.deleteSync();
            }
          }, RootIsolateToken.instance!);
        }
        if (newStatusLocal == DownloadTaskStatus.complete ||
            newStatusLocal == DownloadTaskStatus.failed ||
            newStatusLocal == DownloadTaskStatus.canceled) {
          cachingFilesMap.remove(taskIdLocal);
        }
      }
    });
    FlutterDownloader.registerCallback(downloadCallback);
  }

  ///暂停下载
  static Future pause(FileInfo mediaEntry) async {
    List<DownloadTask>?
    taskListLocal = await FlutterDownloader.loadTasksWithRawQuery(
      query:
          'SELECT * FROM task WHERE task_id = "${mediaEntry.downloadTaskId}"',
    );
    if (taskListLocal?.isNotEmpty == true) {
      DownloadTask transferTaskLocal = taskListLocal!.first;
      if (transferTaskLocal.status == DownloadTaskStatus.running ||
          transferTaskLocal.status == DownloadTaskStatus.enqueued) {
        await FlutterDownloader.pause(taskId: transferTaskLocal.taskId);
      }
    }
  }

  ///删除下载
  static Future<FileInfo?> remove(FileInfo mediaEntry) async {
    if (mediaEntry.downloadTaskId != null) {
      await FlutterDownloader.remove(taskId: mediaEntry.downloadTaskId!);
    }
    String filePathLocal = await mediaEntry.filePath;
    File fileLocal = File(filePathLocal);
    if (fileLocal.existsSync()) {
      await fileLocal.delete();
    }
    mediaEntry.downloadTaskId = null;
    mediaEntry.downloadProgress = null;
    mediaEntry.downloadStatus = DownloadTaskStatus.undefined.index;
    _downloaderController.add(mediaEntry);
    return mediaEntry;
  }

  ///继续或重试下载
  static Future<FileInfo?> resumeOrRetry(
    FileInfo mediaEntry, {
    bool isClickArg = true,
  }) async {
    List<DownloadTask>?
    taskListLocal = await FlutterDownloader.loadTasksWithRawQuery(
      query:
          'SELECT * FROM task WHERE task_id = "${mediaEntry.downloadTaskId}"',
    );
    if (taskListLocal?.isNotEmpty == true) {
      DownloadTask transferTaskLocal = taskListLocal!.first;
      if (transferTaskLocal.status == DownloadTaskStatus.complete) {
        //如果发现已经完成，直接更新状态
        String filePathLocal = await mediaEntry.filePath;
        File tempFileLocal = File(await mediaEntry.tempFilePath);
        if (tempFileLocal.existsSync()) {
          compute((rootIsolateTokenInputArg) async {
            BackgroundIsolateBinaryMessenger.ensureInitialized(
              rootIsolateTokenInputArg,
            );
            tempFileLocal.copySync(filePathLocal);
            tempFileLocal.deleteSync();
          }, RootIsolateToken.instance!);
          mediaEntry.downloadStatus = DownloadTaskStatus.complete.index;
          _downloaderController.add(mediaEntry);
          return mediaEntry;
        }
      } else if (transferTaskLocal.status == DownloadTaskStatus.paused) {
        String? newTaskIdLocal = await FlutterDownloader.resume(
          taskId: transferTaskLocal.taskId,
        );
        mediaEntry.downloadTaskId = newTaskIdLocal;
        if (newTaskIdLocal != null) {
          downloadingFilesMap[newTaskIdLocal] = mediaEntry;
        }
        return mediaEntry;
      } else if (transferTaskLocal.status == DownloadTaskStatus.canceled ||
          transferTaskLocal.status == DownloadTaskStatus.enqueued) {
        download(mediaEntry: mediaEntry, isClickArg: isClickArg);
      } else if (transferTaskLocal.status == DownloadTaskStatus.failed) {
        // String? newTaskId = await FlutterDownloader.retry(taskId: transferTask.taskId);
        // mediaDetails.downloadTaskId = newTaskId;
        // if(newTaskId!=null) {
        //   downloadingFilesMap[newTaskId] = mediaDetails;
        // }
        // return mediaDetails;

        //内部的获取url失败也是被通知成failed了，所以直接重新下载
        download(mediaEntry: mediaEntry, isClickArg: isClickArg);
      }
    } else {
      download(mediaEntry: mediaEntry, isClickArg: isClickArg);
    }
    return null;
  }

  ///有时候文件下载成功，但是未同步到FileInfo，直接使用其文件
  static Future<String?> syncTaskToFileInfo(
    FileInfo mediaEntry, {
    bool cacheArg = false,
  }) async {
    List<DownloadTask>?
    taskListLocal = await FlutterDownloader.loadTasksWithRawQuery(
      query:
          'SELECT * FROM task WHERE task_id = "${mediaEntry.downloadTaskId}"',
    );
    if (taskListLocal?.isNotEmpty == true) {
      DownloadTask transferTaskLocal = taskListLocal!.first;
      if (transferTaskLocal.status == DownloadTaskStatus.complete) {
        String filePathLocal = await mediaEntry.filePath;
        if (cacheArg) {
          filePathLocal = await mediaEntry.cacheFilePath;
        }
        File tempFileLocal = File(await mediaEntry.tempFilePath);
        if (tempFileLocal.existsSync()) {
          compute((rootIsolateTokenInputArg) async {
            BackgroundIsolateBinaryMessenger.ensureInitialized(
              rootIsolateTokenInputArg,
            );
            tempFileLocal.copySync(filePathLocal);
            tempFileLocal.deleteSync();
          }, RootIsolateToken.instance!);
          return filePathLocal;
        }
      }
    }
    return null;
  }
}

class TransferStartInfo {
  final bool isClick;
  final FileInfo mediaDetails;
  const TransferStartInfo({this.isClick = true, required this.mediaDetails});
}
