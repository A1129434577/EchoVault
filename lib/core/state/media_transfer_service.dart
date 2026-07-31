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
@pragma('vm:entry-point')
class MediaTransferService {
  static const String _downloaderSendPortName = 'flutter_downloader_send_port';

  static Future initSdk() async {
    await FlutterDownloader.initialize(debug: true, ignoreSsl: true);
    IsolateNameServer.removePortNameMapping(_downloaderSendPortName);
    ReceivePort receivePort = ReceivePort();
    IsolateNameServer.registerPortWithName(
      receivePort.sendPort,
      _downloaderSendPortName,
    );
    receivePort.listen((dynamic data) async {
      String taskId = data[0];
      DownloadTaskStatus newStatus = DownloadTaskStatus.fromInt(data[1]);
      //进度0-1
      int newProgress = data[2];

      FileInfo? mediaDetails = downloadingFilesMap[taskId];
      if (mediaDetails == null) {
        List<FileInfo> mediaItems = await MediaRepository.queryFileInfo(
          where: 'download_task_id = "$taskId"',
        );
        if (mediaItems.isNotEmpty) {
          mediaDetails = mediaItems.first;
          downloadingFilesMap[taskId] = mediaDetails;
        }
      }
      if (mediaDetails != null) {
        if (newStatus == DownloadTaskStatus.complete) {
          compute((rootIsolateToken) async {
            BackgroundIsolateBinaryMessenger.ensureInitialized(
              rootIsolateToken,
            );
            //下载完成后将文件拷贝至对应文件夹
            File tempFile = File(await mediaDetails!.tempFilePath);
            if (tempFile.existsSync()) {
              tempFile.copySync(await mediaDetails.filePath);
              tempFile.deleteSync();
            }
          }, RootIsolateToken.instance!);
        }
        mediaDetails.downloadProgress = newProgress;
        mediaDetails.downloadStatus = newStatus.index;
        _downloaderController.add(mediaDetails);

        if (newStatus == DownloadTaskStatus.complete ||
            newStatus == DownloadTaskStatus.failed ||
            newStatus == DownloadTaskStatus.canceled) {
          downloadingFilesMap.remove(taskId);
        }
      }

      FileInfo? cacheFileInfo = cachingFilesMap[taskId];
      if (cacheFileInfo != null) {
        if (newStatus == DownloadTaskStatus.complete) {
          compute((rootIsolateToken) async {
            BackgroundIsolateBinaryMessenger.ensureInitialized(
              rootIsolateToken,
            );
            //下载完成后将文件拷贝至对应文件夹
            File tempFile = File(await cacheFileInfo.tempFilePath);
            if (tempFile.existsSync()) {
              tempFile.copySync(await cacheFileInfo.cacheFilePath);
              tempFile.deleteSync();
            }
          }, RootIsolateToken.instance!);
        }
        if (newStatus == DownloadTaskStatus.complete ||
            newStatus == DownloadTaskStatus.failed ||
            newStatus == DownloadTaskStatus.canceled) {
          cachingFilesMap.remove(taskId);
        }
      }
    });
    FlutterDownloader.registerCallback(downloadCallback);
  }

  @pragma('vm:entry-point')
  static void downloadCallback(String id, int status, int progress) {
    final SendPort? send = IsolateNameServer.lookupPortByName(
      _downloaderSendPortName,
    );
    send?.send([id, status, progress]);
  }

  //下载中的文件taskId:FileInfo
  static Map<String, FileInfo> downloadingFilesMap = {};
  //缓存中的文件taskId:FileInfo
  static Map<String, FileInfo> cachingFilesMap = {};

  //下载详细状态更新流
  static Stream<FileInfo> get downloadStream => _downloaderController.stream;
  static final StreamController<FileInfo> _downloaderController =
      StreamController.broadcast();

  //下载开始流
  static Stream<TransferStartInfo> get downloadStartStream =>
      _downloaderStartController.stream;
  static final StreamController<TransferStartInfo> _downloaderStartController =
      StreamController.broadcast();

  ///有时候文件下载成功，但是未同步到FileInfo，直接使用其文件
  static Future<String?> syncTaskToFileInfo(
    FileInfo mediaDetails, {
    bool cache = false,
  }) async {
    List<DownloadTask>?
    taskList = await FlutterDownloader.loadTasksWithRawQuery(
      query:
          'SELECT * FROM task WHERE task_id = "${mediaDetails.downloadTaskId}"',
    );
    if (taskList?.isNotEmpty == true) {
      DownloadTask transferTask = taskList!.first;
      if (transferTask.status == DownloadTaskStatus.complete) {
        String filePath = await mediaDetails.filePath;
        if (cache) {
          filePath = await mediaDetails.cacheFilePath;
        }
        File tempFile = File(await mediaDetails.tempFilePath);
        if (tempFile.existsSync()) {
          compute((rootIsolateToken) async {
            BackgroundIsolateBinaryMessenger.ensureInitialized(
              rootIsolateToken,
            );
            tempFile.copySync(filePath);
            tempFile.deleteSync();
          }, RootIsolateToken.instance!);
          return filePath;
        }
      }
    }
    return null;
  }

  ///下载
  static Future<String?> download({
    required FileInfo mediaDetails,
    bool isClick = true,
  }) async {
    _downloaderStartController.add(
      TransferStartInfo(mediaDetails: mediaDetails, isClick: isClick),
    );

    mediaDetails.downloadStatus = DownloadTaskStatus.enqueued.index;
    _downloaderController.add(mediaDetails);

    String filePath = await mediaDetails.filePath;
    String cachePath = await mediaDetails.cacheFilePath;

    File file = File(filePath);
    if (file.existsSync()) {
      //文件已下载
      mediaDetails.downloadStatus = DownloadTaskStatus.complete.index;
      _downloaderController.add(mediaDetails);
      return null;
    }
    File cacheFile = File(cachePath);
    if (cacheFile.existsSync()) {
      compute((rootIsolateToken) async {
        BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
        cacheFile.copySync(filePath);
        cacheFile.deleteSync();
      }, RootIsolateToken.instance!);
      mediaDetails.downloadStatus = DownloadTaskStatus.complete.index;
      _downloaderController.add(mediaDetails);
      return filePath;
    }

    String? resultPath = await syncTaskToFileInfo(mediaDetails);
    if (resultPath != null) {
      mediaDetails.downloadStatus = DownloadTaskStatus.complete.index;
      _downloaderController.add(mediaDetails);
      return resultPath;
    }
    PlaybackHttpTransport httpClient = PlaybackHttpTransport();
    String? url = await httpClient.getFileUrl(fileInfo: mediaDetails);
    if (url == null) {
      await Future.delayed(Duration(milliseconds: 200));
      url = await httpClient.getFileUrl(fileInfo: mediaDetails);
    }
    if (url == null) {
      await Future.delayed(Duration(milliseconds: 200));
      url = await httpClient.getFileUrl(fileInfo: mediaDetails);
    }
    if (url == null) {
      mediaDetails.downloadStatus = DownloadTaskStatus.failed.index;
      _downloaderController.add(mediaDetails);
      //文件下载地址获取失败
      return null;
    }

    Completer<String?> completer = Completer();
    StreamSubscription? flutterDownloadSub;
    flutterDownloadSub = downloadStream.listen((newFileInfo) async {
      if (mediaDetails.fileId == newFileInfo.fileId) {
        if (newFileInfo.downloadStatus == DownloadTaskStatus.complete.index ||
            newFileInfo.downloadStatus == DownloadTaskStatus.failed.index ||
            newFileInfo.downloadStatus == DownloadTaskStatus.canceled.index) {
          flutterDownloadSub?.cancel();
          if (completer.isCompleted == false) {
            if (newFileInfo.downloadStatus ==
                DownloadTaskStatus.complete.index) {
              completer.complete(filePath);
            } else {
              completer.complete();
            }
          }
        }
      }
    });

    String savedDir = await FileInfo.filesTempDirectoryPath;
    String? downloadTaskId = await FlutterDownloader.enqueue(
      url: url,
      headers: {},
      savedDir: savedDir,
      fileName: mediaDetails.fileName,
      showNotification: false,
      openFileFromNotification: false,
    );
    mediaDetails.downloadTaskId = downloadTaskId;
    if (downloadTaskId != null) {
      downloadingFilesMap[downloadTaskId] = mediaDetails;
    }
    return completer.future;
  }

  ///缓存
  static Future<String?> cache({
    required FileInfo mediaDetails,
    PlayerHttpClientInterface? httpClient,
  }) async {
    String filePath = await mediaDetails.filePath;
    String cachePath = await mediaDetails.cacheFilePath;

    File file = File(filePath);
    if (file.existsSync()) {
      return filePath;
    }
    File cacheFile = File(cachePath);
    if (cacheFile.existsSync()) {
      return cachePath;
    }

    String? resultPath = await syncTaskToFileInfo(mediaDetails, cache: true);
    if (resultPath != null) {
      return resultPath;
    }

    String? url = await httpClient?.getFileUrl(fileInfo: mediaDetails);
    url ??= await httpClient?.getFileUrl(fileInfo: mediaDetails);
    url ??= await httpClient?.getFileUrl(fileInfo: mediaDetails);
    if (url == null) {
      return null;
    }

    String savedDir = await FileInfo.filesTempDirectoryPath;
    String? cacheDownloadTaskId = await FlutterDownloader.enqueue(
      url: url,
      headers: {},
      savedDir: savedDir,
      fileName: mediaDetails.fileName,
      showNotification: false,
      openFileFromNotification: false,
    );
    mediaDetails.cacheDownloadTaskId = cacheDownloadTaskId;
    if (cacheDownloadTaskId != null) {
      cachingFilesMap[cacheDownloadTaskId] = mediaDetails;
    }
    return cacheDownloadTaskId;
  }

  ///暂停下载
  static Future pause(FileInfo mediaDetails) async {
    List<DownloadTask>?
    taskList = await FlutterDownloader.loadTasksWithRawQuery(
      query:
          'SELECT * FROM task WHERE task_id = "${mediaDetails.downloadTaskId}"',
    );
    if (taskList?.isNotEmpty == true) {
      DownloadTask transferTask = taskList!.first;
      if (transferTask.status == DownloadTaskStatus.running ||
          transferTask.status == DownloadTaskStatus.enqueued) {
        await FlutterDownloader.pause(taskId: transferTask.taskId);
      }
    }
  }

  ///继续或重试下载
  static Future<FileInfo?> resumeOrRetry(
    FileInfo mediaDetails, {
    bool isClick = true,
  }) async {
    List<DownloadTask>?
    taskList = await FlutterDownloader.loadTasksWithRawQuery(
      query:
          'SELECT * FROM task WHERE task_id = "${mediaDetails.downloadTaskId}"',
    );
    if (taskList?.isNotEmpty == true) {
      DownloadTask transferTask = taskList!.first;
      if (transferTask.status == DownloadTaskStatus.complete) {
        //如果发现已经完成，直接更新状态
        String filePath = await mediaDetails.filePath;
        File tempFile = File(await mediaDetails.tempFilePath);
        if (tempFile.existsSync()) {
          compute((rootIsolateToken) async {
            BackgroundIsolateBinaryMessenger.ensureInitialized(
              rootIsolateToken,
            );
            tempFile.copySync(filePath);
            tempFile.deleteSync();
          }, RootIsolateToken.instance!);
          mediaDetails.downloadStatus = DownloadTaskStatus.complete.index;
          _downloaderController.add(mediaDetails);
          return mediaDetails;
        }
      } else if (transferTask.status == DownloadTaskStatus.paused) {
        String? newTaskId = await FlutterDownloader.resume(
          taskId: transferTask.taskId,
        );
        mediaDetails.downloadTaskId = newTaskId;
        if (newTaskId != null) {
          downloadingFilesMap[newTaskId] = mediaDetails;
        }
        return mediaDetails;
      } else if (transferTask.status == DownloadTaskStatus.canceled ||
          transferTask.status == DownloadTaskStatus.enqueued) {
        download(mediaDetails: mediaDetails, isClick: isClick);
      } else if (transferTask.status == DownloadTaskStatus.failed) {
        // String? newTaskId = await FlutterDownloader.retry(taskId: transferTask.taskId);
        // mediaDetails.downloadTaskId = newTaskId;
        // if(newTaskId!=null) {
        //   downloadingFilesMap[newTaskId] = mediaDetails;
        // }
        // return mediaDetails;

        //内部的获取url失败也是被通知成failed了，所以直接重新下载
        download(mediaDetails: mediaDetails, isClick: isClick);
      }
    } else {
      download(mediaDetails: mediaDetails, isClick: isClick);
    }
    return null;
  }

  ///取消下载
  static Future cancel(FileInfo mediaDetails) async {
    List<DownloadTask>?
    taskList = await FlutterDownloader.loadTasksWithRawQuery(
      query:
          'SELECT * FROM task WHERE task_id = "${mediaDetails.downloadTaskId}"',
    );
    if (taskList?.isNotEmpty == true) {
      DownloadTask transferTask = taskList!.first;
      if (transferTask.status == DownloadTaskStatus.enqueued ||
          transferTask.status == DownloadTaskStatus.running ||
          transferTask.status == DownloadTaskStatus.paused) {
        await FlutterDownloader.cancel(taskId: transferTask.taskId);
        if (transferTask.status == DownloadTaskStatus.paused) {
          //暂停的任务好像取消没反应，这里直接通知出去处理一次
          mediaDetails.downloadStatus = DownloadTaskStatus.canceled.index;
          _downloaderController.add(mediaDetails);
        }
      } else {
        remove(mediaDetails);
      }
    } else {
      mediaDetails.downloadStatus = DownloadTaskStatus.canceled.index;
      _downloaderController.add(mediaDetails);
    }
  }

  ///删除下载
  static Future<FileInfo?> remove(FileInfo mediaDetails) async {
    if (mediaDetails.downloadTaskId != null) {
      await FlutterDownloader.remove(taskId: mediaDetails.downloadTaskId!);
    }
    String filePath = await mediaDetails.filePath;
    File file = File(filePath);
    if (file.existsSync()) {
      await file.delete();
    }
    mediaDetails.downloadTaskId = null;
    mediaDetails.downloadProgress = null;
    mediaDetails.downloadStatus = DownloadTaskStatus.undefined.index;
    _downloaderController.add(mediaDetails);
    return mediaDetails;
  }
}

class TransferStartInfo {
  final bool isClick;
  final FileInfo mediaDetails;
  const TransferStartInfo({this.isClick = true, required this.mediaDetails});
}
