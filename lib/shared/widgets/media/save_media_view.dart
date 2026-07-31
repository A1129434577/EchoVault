import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:player_base/models/file_info.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/core/state/transfer_media_state.dart';
import 'package:echo_vault/shared/widgets/progress_view.dart';

export 'package:echo_vault/core/state/transfer_media_state.dart';

class SaveMediaView extends StatelessWidget {
  final FileInfo? mediaDetails;
  final TransferMediaState? controller;
  final String? icon;
  final String? selectedIcon;
  const SaveMediaView({
    super.key,
    required this.mediaDetails,
    this.controller,
    this.icon,
    this.selectedIcon,
  });

  @override
  Widget build(BuildContext context) {
    TransferMediaState downloadControllerLocal =
        controller ?? TransferMediaState();
    downloadControllerLocal.fileInfoNotifier.value = mediaDetails;

    return ValueListenableBuilder(
      valueListenable: downloadControllerLocal.fileInfoNotifier,
      builder: (BuildContext context, FileInfo? mediaDetails, Widget? child) {
        Widget nestedEntry = Image.asset(
          icon ?? Assets.images.collection.saveControl.path,
        );
        DownloadTaskStatus taskStatusLocal = DownloadTaskStatus.fromInt(
          mediaDetails?.downloadStatus ?? 0,
        );
        if (taskStatusLocal == DownloadTaskStatus.complete) {
          nestedEntry = Image.asset(
            selectedIcon ?? Assets.images.collection.savedState.path,
          );
        } else if (taskStatusLocal == DownloadTaskStatus.enqueued) {
          nestedEntry = ProgressView();
        } else if (taskStatusLocal == DownloadTaskStatus.running) {
          nestedEntry = LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return Padding(
                padding: EdgeInsetsGeometry.all(constraints.maxHeight * 0.1),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xff1D75FF)),
                  backgroundColor: Color(
                    0xff1D75FF,
                  ).withAlpha((255 * 0.35).round()),
                  value: (mediaDetails?.downloadProgress ?? 0) / 100,
                ),
              );
            },
          );
        } else if (taskStatusLocal == DownloadTaskStatus.paused) {
          nestedEntry = LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.pause, size: constraints.maxHeight / 2),
                  Padding(
                    padding: EdgeInsetsGeometry.all(
                      constraints.maxHeight * 0.1,
                    ),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xff1D75FF),
                      ),
                      backgroundColor: Color(
                        0xff1D75FF,
                      ).withAlpha((255 * 0.35).round()),
                      value: (mediaDetails?.downloadProgress ?? 0) / 100,
                    ),
                  ),
                ],
              );
            },
          );
        }
        nestedEntry = AspectRatio(aspectRatio: 1, child: nestedEntry);
        if (controller == null) {
          return CupertinoButton(
            onPressed: () {
              downloadControllerLocal.handleSaveState();
            },
            onLongPress: () {
              downloadControllerLocal.cancel();
            },
            sizeStyle: CupertinoButtonSize.small,
            padding: EdgeInsets.zero,
            child: nestedEntry,
          );
        }
        return nestedEntry;
      },
    );
  }
}
