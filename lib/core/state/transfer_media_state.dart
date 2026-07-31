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

  ValueNotifier<FileInfo?> fileInfoNotifier = ValueNotifier(null);
  late StreamSubscription _downloadSubscription;
  TransferMediaState() {
    _downloadSubscription = MediaTransferService.downloadStream.listen((
      newFileInfoInputArg,
    ) {
      if (newFileInfoInputArg.fileId == fileInfoNotifier.value?.fileId) {
        fileInfoNotifier.value?.downloadTaskId =
            newFileInfoInputArg.downloadTaskId;
        fileInfoNotifier.value?.downloadProgress =
            newFileInfoInputArg.downloadProgress;
        fileInfoNotifier.value?.downloadStatus =
            newFileInfoInputArg.downloadStatus;
        fileInfoNotifier.notifyListeners();
      }
    });
  }
  //下载终止状态更新流（比如下载完成，删除）
  static Stream<FileInfo> get downloadFinishAndRemoveStream =>
      _downloadFinishAndRemoveController.stream;

  @override
  void dispose() {
    _downloadSubscription.cancel();
    super.dispose();
  }

  void cancel() {
    FileInfo mediaEntry = fileInfoNotifier.value!;
    DownloadTaskStatus taskStatusLocal = DownloadTaskStatus.fromInt(
      mediaEntry.downloadStatus,
    );
    if (taskStatusLocal == DownloadTaskStatus.enqueued ||
        taskStatusLocal == DownloadTaskStatus.paused ||
        taskStatusLocal == DownloadTaskStatus.running) {
      ConfirmationDialog.show(
        displayTitle: 'Cancel'.translate,
        messageArg:
            'Are you sure you want to cancel download "${mediaEntry.name}"?'
                .translate,
        onConfirmArg: () {
          MediaTransferService.cancel(mediaEntry);
        },
      );
    }
  }

  static Future deleteAllDownloaded() async {
    List<FileInfo> mediaEntries = await MediaRepository.queryFileInfo(
      whereArg: 'download_status = ${DownloadTaskStatus.complete.index}',
    );
    for (final mediaDetails in mediaEntries) {
      await remove(mediaDetails);
    }
  }

  static Future deleteAllDownloadingFile() async {
    List<FileInfo> mediaEntries = await MediaRepository.queryFileInfo(
      whereArg:
          'download_status NOT IN (${DownloadTaskStatus.enqueued.index}, ${DownloadTaskStatus.running.index})',
    );
    for (final mediaDetails in mediaEntries) {
      await remove(mediaDetails);
    }
  }

  static Future initSdk() async {
    try {
      await MediaTransferService.initSdk();
      listenFileDownloadStatus();
      Future.delayed(Duration(seconds: 2)).then((ignoredResult) {
        resumeAllFileDownloadingTask();
      });
    } catch (_) {}
  }

  ///更新数据库，需要先行调用
  static listenFileDownloadStatus() {
    MediaTransferService.downloadStream.listen((mediaEntry) async {
      DownloadTaskStatus taskStatusLocal = DownloadTaskStatus.fromInt(
        mediaEntry.downloadStatus,
      );
      if ((taskStatusLocal == DownloadTaskStatus.enqueued &&
              mediaEntry.downloadTaskId != null) ||
          taskStatusLocal == DownloadTaskStatus.complete ||
          taskStatusLocal == DownloadTaskStatus.failed ||
          taskStatusLocal == DownloadTaskStatus.canceled ||
          taskStatusLocal == DownloadTaskStatus.paused) {
        await MediaRepository.insertFileInfo(mediaEntry);
      }
      if (taskStatusLocal == DownloadTaskStatus.complete) {
        _downloadFinishAndRemoveController.add(mediaEntry);
        MessageOverlay.showSuccess('Downloaded.'.translate);
      }
      if (taskStatusLocal == DownloadTaskStatus.failed) {
        MessageOverlay.showError('Download failed.'.translate);
      }
    });
  }

  ///删除下载
  ///删除下载只需要将其下载相关字段清空，不删除fileInfo而导致历史播放记录等数据被删除
  static Future remove(FileInfo mediaEntry) async {
    FileInfo? removeFileInfoLocal = await MediaTransferService.remove(
      mediaEntry,
    );
    if (removeFileInfoLocal != null) {
      await MediaRepository.insertFileInfo(removeFileInfoLocal);
      _downloadFinishAndRemoveController.add(removeFileInfoLocal);
    }
  }

  ///读取所有下载任务并继续
  static Future resumeAllFileDownloadingTask() async {
    List<FileInfo> mediaEntries = await MediaRepository.queryFileInfo(
      whereArg:
          'download_status IN (${DownloadTaskStatus.failed.index}, ${DownloadTaskStatus.enqueued.index})',
    );
    for (FileInfo mediaDetails in mediaEntries) {
      await resumeOrRetry(mediaDetails, isClickArg: false);
    }
  }

  ///继续或重试下载
  static Future resumeOrRetry(
    FileInfo mediaEntry, {
    bool isClickArg = true,
  }) async {
    FileInfo? resumeFileInfoLocal = await MediaTransferService.resumeOrRetry(
      mediaEntry,
      isClickArg: isClickArg,
    );
    if (resumeFileInfoLocal != null) {
      await MediaRepository.insertFileInfo(resumeFileInfoLocal);
    }
  }

  void saveStateChange() {
    if (fileInfoNotifier.value != null) {
      FileInfo mediaEntry = fileInfoNotifier.value!;
      DownloadTaskStatus taskStatusLocal = DownloadTaskStatus.fromInt(
        mediaEntry.downloadStatus,
      );
      if (taskStatusLocal == DownloadTaskStatus.complete) {
        ConfirmationDialog.show(
          displayTitle: 'Delete'.translate,
          messageArg:
              'Are you sure you want to delete "${mediaEntry.name}" from your device? This action cannot be undone.'
                  .translate,
          onConfirmArg: () {
            remove(mediaEntry);
          },
        );
      } else if (taskStatusLocal == DownloadTaskStatus.undefined ||
          taskStatusLocal == DownloadTaskStatus.failed ||
          taskStatusLocal == DownloadTaskStatus.canceled) {
        MediaTransferService.download(mediaEntry: mediaEntry);
      } else if (taskStatusLocal == DownloadTaskStatus.running) {
        MediaTransferService.pause(mediaEntry);
      } else if (taskStatusLocal == DownloadTaskStatus.paused) {
        resumeOrRetry(mediaEntry);
      } else if (taskStatusLocal == DownloadTaskStatus.enqueued) {
        cancel();
      }
    }
  }
}
