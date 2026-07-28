import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/datebase/file_info_data_operate.dart';
import 'package:echo_vault/network/player_http_client.dart';

///所有有返回FileInfo的方法都需要外部更新数据库
///其他需要更新数据库的下载状态：
///enqueued且downloadTaskId!=null
///complete、failed、canceled、paused
///强杀app的话DownloadTask的状态变成了canceled
///下载和缓存路径都是先放入temp文件夹，防止因暂停下载等状态时文件不完整，但是却判断文件为已下载的情况
@pragma('vm:entry-point')
class FileDownloader{
  static const String _downloaderSendPortName = 'flutter_downloader_send_port';

  static Future initSdk() async {
    await FlutterDownloader.initialize(
      debug: true,
      ignoreSsl: true,
    );
    IsolateNameServer.removePortNameMapping(_downloaderSendPortName);
    ReceivePort receivePort = ReceivePort();
    IsolateNameServer.registerPortWithName(receivePort.sendPort, _downloaderSendPortName);
    receivePort.listen((dynamic data) async {
      String taskId = data[0];
      DownloadTaskStatus newStatus = DownloadTaskStatus.fromInt(data[1]);
      //进度0-1
      int newProgress = data[2];

      FileInfo? fileInfo = downloadingFilesMap[taskId];
      if(fileInfo == null){
        List<FileInfo> fileInfoList = await FileInfoDataOperate.queryFileInfo(where: 'download_task_id = "$taskId"');
        if(fileInfoList.isNotEmpty){
          fileInfo = fileInfoList.first;
          downloadingFilesMap[taskId] = fileInfo;
        }
      }
      if(fileInfo!=null){
        if (newStatus==DownloadTaskStatus.complete) {
          compute((rootIsolateToken) async {
            BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
            //下载完成后将文件拷贝至对应文件夹
            File tempFile = File(await fileInfo!.tempFilePath);
            if(tempFile.existsSync()) {
              tempFile.copySync(await fileInfo.filePath);
              tempFile.deleteSync();
            }
          }, RootIsolateToken.instance!);
        }
        fileInfo.downloadProgress = newProgress;
        fileInfo.downloadStatus = newStatus.index;
        _downloaderController.add(fileInfo);

        if (newStatus == DownloadTaskStatus.complete ||
            newStatus == DownloadTaskStatus.failed ||
            newStatus == DownloadTaskStatus.canceled) {
          downloadingFilesMap.remove(taskId);
        }
      }

      FileInfo? cacheFileInfo = cachingFilesMap[taskId];
      if (cacheFileInfo!=null){
        if(newStatus==DownloadTaskStatus.complete) {
          compute((rootIsolateToken) async {
            BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
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
    final SendPort? send = IsolateNameServer.lookupPortByName(_downloaderSendPortName);
    send?.send([id, status, progress]);
  }

  //下载中的文件taskId:FileInfo
  static Map<String, FileInfo> downloadingFilesMap = {};
  //缓存中的文件taskId:FileInfo
  static Map<String, FileInfo> cachingFilesMap = {};

  //下载详细状态更新流
  static Stream<FileInfo> get downloadStream => _downloaderController.stream;
  static final StreamController<FileInfo> _downloaderController = StreamController.broadcast();

  //下载开始流
  static Stream<DownloadStartInfo> get downloadStartStream => _downloaderStartController.stream;
  static final StreamController<DownloadStartInfo> _downloaderStartController = StreamController.broadcast();

  ///有时候文件下载成功，但是未同步到FileInfo，直接使用其文件
  static Future<String?> syncTaskToFileInfo(FileInfo fileInfo, {bool cache=false}) async {
    List<DownloadTask>? taskList = await FlutterDownloader.loadTasksWithRawQuery(
      query: 'SELECT * FROM task WHERE task_id = "${fileInfo.downloadTaskId}"',
    );
    if (taskList?.isNotEmpty == true) {
      DownloadTask downloadTask = taskList!.first;
      if(downloadTask.status == DownloadTaskStatus.complete){
        String filePath = await fileInfo.filePath;
        if(cache){
          filePath = await fileInfo.cacheFilePath;
        }
        File tempFile = File(await fileInfo.tempFilePath);
        if(tempFile.existsSync()) {
          compute((rootIsolateToken) async {
            BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
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
    required FileInfo fileInfo,
    bool isClick = true,
  }) async {
    _downloaderStartController.add(DownloadStartInfo(fileInfo: fileInfo, isClick: isClick));

    fileInfo.downloadStatus = DownloadTaskStatus.enqueued.index;
    _downloaderController.add(fileInfo);

    String filePath = await fileInfo.filePath;
    String cachePath = await fileInfo.cacheFilePath;

    File file = File(filePath);
    if (file.existsSync()) {
      //文件已下载
      fileInfo.downloadStatus = DownloadTaskStatus.complete.index;
      _downloaderController.add(fileInfo);
      return null;
    }
    File cacheFile = File(cachePath);
    if(cacheFile.existsSync()){
      compute((rootIsolateToken) async {
        BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
        cacheFile.copySync(filePath);
        cacheFile.deleteSync();
      }, RootIsolateToken.instance!);
      fileInfo.downloadStatus = DownloadTaskStatus.complete.index;
      _downloaderController.add(fileInfo);
      return filePath;
    }

    String? resultPath = await syncTaskToFileInfo(fileInfo);
    if(resultPath != null){
      fileInfo.downloadStatus = DownloadTaskStatus.complete.index;
      _downloaderController.add(fileInfo);
      return resultPath;
    }
    PlayerHttpClient httpClient = PlayerHttpClient();
    String? url = await httpClient.getFileUrl(fileInfo: fileInfo);
    if(url == null){
      await Future.delayed(Duration(milliseconds: 200));
      url = await httpClient.getFileUrl(fileInfo: fileInfo);
    }
    if(url == null){
      await Future.delayed(Duration(milliseconds: 200));
      url = await httpClient.getFileUrl(fileInfo: fileInfo);
    }
    if(url == null) {
      fileInfo.downloadStatus = DownloadTaskStatus.failed.index;
      _downloaderController.add(fileInfo);
      //文件下载地址获取失败
      return null;
    }

    Completer<String?> completer = Completer();
    StreamSubscription? flutterDownloadSub;
    flutterDownloadSub = downloadStream.listen((newFileInfo) async {
      if(fileInfo.fileId == newFileInfo.fileId) {
        if (newFileInfo.downloadStatus == DownloadTaskStatus.complete.index ||
            newFileInfo.downloadStatus == DownloadTaskStatus.failed.index ||
            newFileInfo.downloadStatus == DownloadTaskStatus.canceled.index) {
          flutterDownloadSub?.cancel();
          if (completer.isCompleted == false) {
            if (newFileInfo.downloadStatus == DownloadTaskStatus.complete.index) {
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
      fileName: fileInfo.fileName,
      showNotification: false,
      openFileFromNotification: false,
    );
    fileInfo.downloadTaskId = downloadTaskId;
    if(downloadTaskId!=null){
      downloadingFilesMap[downloadTaskId] = fileInfo;
    }
    return completer.future;
  }

  ///缓存
  static Future<String?> cache({
    required FileInfo fileInfo,
    PlayerHttpClientInterface? httpClient,
  }) async {
    String filePath = await fileInfo.filePath;
    String cachePath = await fileInfo.cacheFilePath;

    File file = File(filePath);
    if (file.existsSync()) {
      return filePath;
    }
    File cacheFile = File(cachePath);
    if(cacheFile.existsSync()){
      return cachePath;
    }

    String? resultPath = await syncTaskToFileInfo(fileInfo, cache: true);
    if(resultPath != null){
      return resultPath;
    }

    String? url = await httpClient?.getFileUrl(fileInfo: fileInfo);
    url ??= await httpClient?.getFileUrl(fileInfo: fileInfo);
    url ??= await httpClient?.getFileUrl(fileInfo: fileInfo);
    if(url == null) {
      return null;
    }

    String savedDir = await FileInfo.filesTempDirectoryPath;
    String? cacheDownloadTaskId = await FlutterDownloader.enqueue(
      url: url,
      headers: {},
      savedDir: savedDir,
      fileName: fileInfo.fileName,
      showNotification: false,
      openFileFromNotification: false,
    );
    fileInfo.cacheDownloadTaskId = cacheDownloadTaskId;
    if(cacheDownloadTaskId!=null){
      cachingFilesMap[cacheDownloadTaskId] = fileInfo;
    }
    return cacheDownloadTaskId;
  }

  ///暂停下载
  static Future pause(FileInfo fileInfo) async {
    List<DownloadTask>? taskList = await FlutterDownloader.loadTasksWithRawQuery(
      query: 'SELECT * FROM task WHERE task_id = "${fileInfo.downloadTaskId}"',
    );
    if(taskList?.isNotEmpty == true) {
      DownloadTask downloadTask = taskList!.first;
      if (downloadTask.status == DownloadTaskStatus.running ||
          downloadTask.status == DownloadTaskStatus.enqueued) {
        await FlutterDownloader.pause(taskId: downloadTask.taskId);
      }
    }
  }

  ///继续或重试下载
  static Future<FileInfo?> resumeOrRetry(FileInfo fileInfo, {bool isClick=true}) async {
    List<DownloadTask>? taskList = await FlutterDownloader.loadTasksWithRawQuery(
      query: 'SELECT * FROM task WHERE task_id = "${fileInfo.downloadTaskId}"',
    );
    if (taskList?.isNotEmpty == true) {
      DownloadTask downloadTask = taskList!.first;
      if(downloadTask.status == DownloadTaskStatus.complete){
        //如果发现已经完成，直接更新状态
        String filePath = await fileInfo.filePath;
        File tempFile = File(await fileInfo.tempFilePath);
        if(tempFile.existsSync()) {
          compute((rootIsolateToken) async {
            BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
            tempFile.copySync(filePath);
            tempFile.deleteSync();
          }, RootIsolateToken.instance!);
          fileInfo.downloadStatus = DownloadTaskStatus.complete.index;
          _downloaderController.add(fileInfo);
          return fileInfo;
        }
      }
      else if (downloadTask.status == DownloadTaskStatus.paused) {
        String? newTaskId = await FlutterDownloader.resume(taskId: downloadTask.taskId);
        fileInfo.downloadTaskId = newTaskId;
        if(newTaskId!=null) {
          downloadingFilesMap[newTaskId] = fileInfo;
        }
        return fileInfo;
      }
      else if (downloadTask.status == DownloadTaskStatus.canceled ||
          downloadTask.status == DownloadTaskStatus.enqueued) {
        download(fileInfo: fileInfo, isClick: isClick);
      }
      else if (downloadTask.status == DownloadTaskStatus.failed) {
        // String? newTaskId = await FlutterDownloader.retry(taskId: downloadTask.taskId);
        // fileInfo.downloadTaskId = newTaskId;
        // if(newTaskId!=null) {
        //   downloadingFilesMap[newTaskId] = fileInfo;
        // }
        // return fileInfo;

        //内部的获取url失败也是被通知成failed了，所以直接重新下载
        download(fileInfo: fileInfo, isClick: isClick);
      }
    }
    else{
      download(fileInfo: fileInfo, isClick: isClick);
    }
    return null;
  }

  ///取消下载
  static Future cancel(FileInfo fileInfo) async {
    List<DownloadTask>? taskList = await FlutterDownloader.loadTasksWithRawQuery(
      query: 'SELECT * FROM task WHERE task_id = "${fileInfo.downloadTaskId}"',
    );
    if (taskList?.isNotEmpty == true) {
      DownloadTask downloadTask = taskList!.first;
      if (downloadTask.status == DownloadTaskStatus.enqueued ||
          downloadTask.status == DownloadTaskStatus.running ||
          downloadTask.status == DownloadTaskStatus.paused) {
        await FlutterDownloader.cancel(taskId: downloadTask.taskId);
        if(downloadTask.status == DownloadTaskStatus.paused){
          //暂停的任务好像取消没反应，这里直接通知出去处理一次
          fileInfo.downloadStatus = DownloadTaskStatus.canceled.index;
          _downloaderController.add(fileInfo);
        }
      }else{
        remove(fileInfo);
      }
    }else{
      fileInfo.downloadStatus = DownloadTaskStatus.canceled.index;
      _downloaderController.add(fileInfo);
    }
  }

  ///删除下载
  static Future<FileInfo?> remove(FileInfo fileInfo) async {
    if(fileInfo.downloadTaskId != null) {
      await FlutterDownloader.remove(taskId: fileInfo.downloadTaskId!);
    }
    String filePath = await fileInfo.filePath;
    File file = File(filePath);
    if (file.existsSync()) {
      await file.delete();
    }
    fileInfo.downloadTaskId = null;
    fileInfo.downloadProgress = null;
    fileInfo.downloadStatus = DownloadTaskStatus.undefined.index;
    _downloaderController.add(fileInfo);
    return fileInfo;
  }
}

class DownloadStartInfo {
  final bool isClick;
  final FileInfo fileInfo;
  const DownloadStartInfo({
    this.isClick = true,
    required this.fileInfo,
  });
}