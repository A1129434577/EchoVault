import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:player_base/models/file_info.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/controllers/download_file_controller.dart';
import 'package:echo_vault/widgets/loading_widget.dart';

export 'package:echo_vault/controllers/download_file_controller.dart';


class SaveFileWidget extends StatelessWidget {
  final FileInfo? fileInfo;
  final DownloadFileController? controller;
  final String? icon;
  final String? selectedIcon;
  const SaveFileWidget({
    super.key,
    required this.fileInfo,
    this.controller,
    this.icon,
    this.selectedIcon,
  });

  @override
  Widget build(BuildContext context) {
    DownloadFileController downloadController = controller??DownloadFileController();
    downloadController.fileInfoNotifier.value = fileInfo;

    return ValueListenableBuilder(
      valueListenable: downloadController.fileInfoNotifier,
      builder: (BuildContext context, FileInfo? fileInfo, Widget? child) {
        Widget child = Image.asset(icon ?? Assets.other.saveControl.path);
        DownloadTaskStatus taskStatus = DownloadTaskStatus.fromInt(fileInfo?.downloadStatus??0);
        if(taskStatus == DownloadTaskStatus.complete) {
          child = Image.asset(selectedIcon ?? Assets.other.savedState.path);
        } else if(taskStatus == DownloadTaskStatus.enqueued){
          child = LoadingWidget();
        }else if(taskStatus == DownloadTaskStatus.running){
          child = LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return Padding(
                padding: EdgeInsetsGeometry.all(
                  constraints.maxHeight*0.1,
                ),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xff1D75FF)),
                  backgroundColor: Color(0xff1D75FF).withAlpha((255*0.35).round()),
                  value: (fileInfo?.downloadProgress??0)/100,
                ),
              );
            },

          );
        }else if(taskStatus == DownloadTaskStatus.paused){
          child = LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.pause, size: constraints.maxHeight/2,),
                  Padding(
                    padding: EdgeInsetsGeometry.all(
                      constraints.maxHeight*0.1,
                    ),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xff1D75FF)),
                      backgroundColor: Color(0xff1D75FF).withAlpha((255*0.35).round()),
                      value: (fileInfo?.downloadProgress??0)/100,
                    ),
                  ),
                ],
              );
            },

          );
        }
        child = AspectRatio(
          aspectRatio: 1,
          child: child,
        );
        if(controller == null){
          return CupertinoButton(
            onPressed: (){
              downloadController.saveStateChange();
            },
            onLongPress: (){
              downloadController.cancel();
            },
            sizeStyle: CupertinoButtonSize.small,
            padding: EdgeInsets.zero,
            child: child,
          );
        }
        return child;
      },
    );
  }
}
