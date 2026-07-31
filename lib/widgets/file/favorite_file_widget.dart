import 'package:flutter/cupertino.dart';
import 'package:player_base/models/file_info.dart';
import 'package:echo_vault/controllers/favorite_file_controller.dart';
import 'package:echo_vault/generated/assets.dart';

export 'package:echo_vault/controllers/favorite_file_controller.dart';

class FavoriteFileWidget extends StatelessWidget {
  final FileInfo? fileInfo;
  final FavoriteFileController? controller;
  final String? icon;
  final String? selectedIcon;
  const FavoriteFileWidget({
    super.key,
    required this.fileInfo,
    this.controller,
    this.icon,
    this.selectedIcon,
  });

  @override
  Widget build(BuildContext context) {
    FavoriteFileController favoriteController = controller??FavoriteFileController();
    favoriteController.notifier.value = fileInfo;

    return ValueListenableBuilder(
      valueListenable: favoriteController.notifier,
      builder: (BuildContext context, FileInfo? fileInfo, Widget? child) {
        Widget child = Image.asset(fileInfo?.isFavorite == 1
            ? (selectedIcon ?? Assets.images.collection.favoriteActive.path)
            : (icon ?? Assets.images.collection.favorite.path));
        if(controller==null){
          return CupertinoButton(
            onPressed: (){
              favoriteController.favoriteStateChange();
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
