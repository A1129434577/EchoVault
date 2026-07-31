import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/shared/dialogs/confirmation_dialog.dart';
import 'package:echo_vault/core/persistence/media_repository.dart';
import 'package:echo_vault/core/state/media_transfer_service.dart';
import 'package:echo_vault/core/utilities/message_overlay.dart';

class TransferMediaState with ChangeNotifier {
  static final StreamController<FileInfo> _downloadFinishAndRemoveController =
      StreamController.broadcast();
  //下载终止状态更新流（比如下载完成，删除）
  static Stream<FileInfo> get downloadFinishAndRemoveStream =>
      _downloadFinishAndRemoveController.stream;

  static Future initSdk() async {
    try {
      await MediaTransferService.initSdk();
      listenFileDownloadStatus();
      Future.delayed(Duration(seconds: 2)).then((_) {
        resumeAllFileDownloadingTask();
      });
    } catch (_) {}
  }

  ///更新数据库，需要先行调用
  static listenFileDownloadStatus() {
    MediaTransferService.downloadStream.listen((mediaDetails) async {
      DownloadTaskStatus taskStatus = DownloadTaskStatus.fromInt(
        mediaDetails.downloadStatus,
      );
      if ((taskStatus == DownloadTaskStatus.enqueued &&
              mediaDetails.downloadTaskId != null) ||
          taskStatus == DownloadTaskStatus.complete ||
          taskStatus == DownloadTaskStatus.failed ||
          taskStatus == DownloadTaskStatus.canceled ||
          taskStatus == DownloadTaskStatus.paused) {
        await MediaRepository.insertFileInfo(mediaDetails);
      }
      if (taskStatus == DownloadTaskStatus.complete) {
        _downloadFinishAndRemoveController.add(mediaDetails);
        MessageOverlay.showSuccess('Downloaded.'.translate);
      }
      if (taskStatus == DownloadTaskStatus.failed) {
        MessageOverlay.showError('Download failed.'.translate);
      }
    });
  }

  ///继续或重试下载
  static Future resumeOrRetry(
    FileInfo mediaDetails, {
    bool isClick = true,
  }) async {
    FileInfo? resumeFileInfo = await MediaTransferService.resumeOrRetry(
      mediaDetails,
      isClick: isClick,
    );
    if (resumeFileInfo != null) {
      await MediaRepository.insertFileInfo(resumeFileInfo);
    }
  }

  ///删除下载
  ///删除下载只需要将其下载相关字段清空，不删除fileInfo而导致历史播放记录等数据被删除
  static Future remove(FileInfo mediaDetails) async {
    FileInfo? removeFileInfo = await MediaTransferService.remove(mediaDetails);
    if (removeFileInfo != null) {
      await MediaRepository.insertFileInfo(removeFileInfo);
      _downloadFinishAndRemoveController.add(removeFileInfo);
    }
  }

  ///读取所有下载任务并继续
  static Future resumeAllFileDownloadingTask() async {
    List<FileInfo> mediaItems = await MediaRepository.queryFileInfo(
      where:
          'download_status IN (${DownloadTaskStatus.failed.index}, ${DownloadTaskStatus.enqueued.index})',
    );
    for (FileInfo mediaDetails in mediaItems) {
      await resumeOrRetry(mediaDetails, isClick: false);
    }
  }

  static Future deleteAllDownloaded() async {
    List<FileInfo> mediaItems = await MediaRepository.queryFileInfo(
      where: 'download_status = ${DownloadTaskStatus.complete.index}',
    );
    for (final mediaDetails in mediaItems) {
      await remove(mediaDetails);
    }
  }

  static Future deleteAllDownloadingFile() async {
    List<FileInfo> mediaItems = await MediaRepository.queryFileInfo(
      where:
          'download_status NOT IN (${DownloadTaskStatus.enqueued.index}, ${DownloadTaskStatus.running.index})',
    );
    for (final mediaDetails in mediaItems) {
      await remove(mediaDetails);
    }
  }

  ValueNotifier<FileInfo?> fileInfoNotifier = ValueNotifier(null);
  late StreamSubscription _downloadSubscription;
  TransferMediaState() {
    _downloadSubscription = MediaTransferService.downloadStream.listen((
      newFileInfo,
    ) {
      if (newFileInfo.fileId == fileInfoNotifier.value?.fileId) {
        fileInfoNotifier.value?.downloadTaskId = newFileInfo.downloadTaskId;
        fileInfoNotifier.value?.downloadProgress = newFileInfo.downloadProgress;
        fileInfoNotifier.value?.downloadStatus = newFileInfo.downloadStatus;
        fileInfoNotifier.notifyListeners();
      }
    });
  }

  void saveStateChange() {
    if (fileInfoNotifier.value != null) {
      FileInfo mediaDetails = fileInfoNotifier.value!;
      DownloadTaskStatus taskStatus = DownloadTaskStatus.fromInt(
        mediaDetails.downloadStatus,
      );
      if (taskStatus == DownloadTaskStatus.complete) {
        ConfirmationDialog.show(
          title: 'Delete'.translate,
          message:
              'Are you sure you want to delete "${mediaDetails.name}" from your device? This action cannot be undone.'
                  .translate,
          onConfirm: () {
            remove(mediaDetails);
          },
        );
      } else if (taskStatus == DownloadTaskStatus.undefined ||
          taskStatus == DownloadTaskStatus.failed ||
          taskStatus == DownloadTaskStatus.canceled) {
        MediaTransferService.download(mediaDetails: mediaDetails);
      } else if (taskStatus == DownloadTaskStatus.running) {
        MediaTransferService.pause(mediaDetails);
      } else if (taskStatus == DownloadTaskStatus.paused) {
        resumeOrRetry(mediaDetails);
      } else if (taskStatus == DownloadTaskStatus.enqueued) {
        cancel();
      }
    }
  }

  void cancel() {
    FileInfo mediaDetails = fileInfoNotifier.value!;
    DownloadTaskStatus taskStatus = DownloadTaskStatus.fromInt(
      mediaDetails.downloadStatus,
    );
    if (taskStatus == DownloadTaskStatus.enqueued ||
        taskStatus == DownloadTaskStatus.paused ||
        taskStatus == DownloadTaskStatus.running) {
      ConfirmationDialog.show(
        title: 'Cancel'.translate,
        message:
            'Are you sure you want to cancel download "${mediaDetails.name}"?'
                .translate,
        onConfirm: () {
          MediaTransferService.cancel(mediaDetails);
        },
      );
    }
  }

  @override
  void dispose() {
    _downloadSubscription.cancel();
    super.dispose();
  }
}
