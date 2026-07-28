
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/alerts/confirm_alert.dart';
import 'package:echo_vault/datebase/file_info_data_operate.dart';
import 'package:echo_vault/controllers/file_downloader.dart';
import 'package:echo_vault/network/player_http_client.dart';
import 'package:echo_vault/utils/toast_util.dart';

class DownloadFileController with ChangeNotifier {

  static final StreamController<FileInfo> _downloadFinishAndRemoveController = StreamController.broadcast();
  //下载终止状态更新流（比如下载完成，删除）
  static Stream<FileInfo> get downloadFinishAndRemoveStream => _downloadFinishAndRemoveController.stream;

  static Future initSdk() async {
    try{
      await FileDownloader.initSdk();
      listenFileDownloadStatus();
      Future.delayed(Duration(seconds: 2)).then((_){
        resumeAllFileDownloadingTask();
      });
    }catch(_){}
  }

  ///更新数据库，需要先行调用
  static listenFileDownloadStatus(){
    FileDownloader.downloadStream.listen((fileInfo) async {
      DownloadTaskStatus taskStatus = DownloadTaskStatus.fromInt(fileInfo.downloadStatus);
      if((taskStatus == DownloadTaskStatus.enqueued && fileInfo.downloadTaskId != null) ||
          taskStatus == DownloadTaskStatus.complete ||
          taskStatus == DownloadTaskStatus.failed ||
          taskStatus == DownloadTaskStatus.canceled ||
          taskStatus == DownloadTaskStatus.paused) {
        await FileInfoDataOperate.insertFileInfo(fileInfo);
      }
      if(taskStatus == DownloadTaskStatus.complete){
        _downloadFinishAndRemoveController.add(fileInfo);
        ToastUtil.showSuccess('Downloaded.'.translate);
      }
      if(taskStatus == DownloadTaskStatus.failed){
        ToastUtil.showError('Download failed.'.translate);
      }
    });
  }

  ///继续或重试下载
  static Future resumeOrRetry(FileInfo fileInfo, {bool isClick = true}) async {
    FileInfo? resumeFileInfo = await FileDownloader.resumeOrRetry(fileInfo, isClick: isClick);
    if(resumeFileInfo != null){
      await FileInfoDataOperate.insertFileInfo(resumeFileInfo);
    }
  }

  ///删除下载
  ///删除下载只需要将其下载相关字段清空，不删除fileInfo而导致历史播放记录等数据被删除
  static Future remove(FileInfo fileInfo) async {
    FileInfo? removeFileInfo = await FileDownloader.remove(fileInfo);
    if(removeFileInfo != null) {
      await FileInfoDataOperate.insertFileInfo(removeFileInfo);
      _downloadFinishAndRemoveController.add(removeFileInfo);
    }
  }

  ///读取所有下载任务并继续
  static Future resumeAllFileDownloadingTask() async {
    List<FileInfo> fileInfoList = await FileInfoDataOperate.queryFileInfo(where: 'download_status IN (${DownloadTaskStatus.failed.index}, ${DownloadTaskStatus.enqueued.index})');
    for (FileInfo fileInfo in fileInfoList) {
      await resumeOrRetry(fileInfo, isClick: false);
    }
  }

  static Future deleteAllDownloaded() async {
    List<FileInfo> fileInfoList = await FileInfoDataOperate.queryFileInfo(where: 'download_status = ${DownloadTaskStatus.complete.index}');
    for(final fileInfo in fileInfoList){
      await remove(fileInfo);
    }
  }

  static Future deleteAllDownloadingFile() async {
    List<FileInfo> fileInfoList = await FileInfoDataOperate.queryFileInfo(where: 'download_status NOT IN (${DownloadTaskStatus.enqueued.index}, ${DownloadTaskStatus.running.index})');
    for(final fileInfo in fileInfoList){
      await remove(fileInfo);
    }
  }

  ValueNotifier<FileInfo?> fileInfoNotifier = ValueNotifier(null);
  late StreamSubscription _downloadSubscription;
  DownloadFileController(){
    _downloadSubscription = FileDownloader.downloadStream.listen((newFileInfo){
      if(newFileInfo.fileId == fileInfoNotifier.value?.fileId){
        fileInfoNotifier.value?.downloadTaskId = newFileInfo.downloadTaskId;
        fileInfoNotifier.value?.downloadProgress = newFileInfo.downloadProgress;
        fileInfoNotifier.value?.downloadStatus = newFileInfo.downloadStatus;
        fileInfoNotifier.notifyListeners();
      }
    });
  }

  void saveStateChange(){
    if(fileInfoNotifier.value != null) {
      FileInfo fileInfo = fileInfoNotifier.value!;
      DownloadTaskStatus taskStatus = DownloadTaskStatus.fromInt(fileInfo.downloadStatus);
      if(taskStatus == DownloadTaskStatus.complete) {
        ConfirmAlert.show(
          title: 'Delete'.translate,
          message: 'Are you sure you want to delete "${fileInfo.name}" from your device? This action cannot be undone.'.translate,
          onConfirm: (){
            remove(fileInfo);
          }
        );
      } else if (taskStatus == DownloadTaskStatus.undefined ||
          taskStatus == DownloadTaskStatus.failed ||
          taskStatus == DownloadTaskStatus.canceled) {
        FileDownloader.download(fileInfo: fileInfo);
      } else if (taskStatus == DownloadTaskStatus.running) {
        FileDownloader.pause(fileInfo);
      } else if (taskStatus == DownloadTaskStatus.paused) {
        resumeOrRetry(fileInfo);
      } else if(taskStatus == DownloadTaskStatus.enqueued){
        cancel();
      }
    }
  }

  void cancel(){
    FileInfo fileInfo = fileInfoNotifier.value!;
    DownloadTaskStatus taskStatus = DownloadTaskStatus.fromInt(fileInfo.downloadStatus);
    if (taskStatus == DownloadTaskStatus.enqueued ||
        taskStatus == DownloadTaskStatus.paused ||
        taskStatus == DownloadTaskStatus.running) {
      ConfirmAlert.show(
          title: 'Cancel'.translate,
          message: 'Are you sure you want to cancel download "${fileInfo.name}"?'.translate,
          onConfirm: (){
            FileDownloader.cancel(fileInfo);
          }
      );
    }
  }

  @override
  void dispose() {
    _downloadSubscription.cancel();
    super.dispose();
  }

}