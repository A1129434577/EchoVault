import 'package:flutter/cupertino.dart';
import 'package:echo_vault/controllers/favorite_group_controller.dart';
import 'package:echo_vault/datebase/file_group_data_operate.dart';
import 'package:echo_vault/generated/assets.dart';

export 'package:echo_vault/controllers/favorite_file_controller.dart';

class FavoriteGroupWidget extends StatelessWidget {
  final FileGroup fileGroup;
  final FavoriteGroupController? controller;
  final String? icon;
  final String? selectedIcon;
  const FavoriteGroupWidget({
    super.key,
    required this.fileGroup,
    this.controller,
    this.icon,
    this.selectedIcon,
  });

  @override
  Widget build(BuildContext context) {
    FavoriteGroupController favoriteController = controller??FavoriteGroupController(fileGroup: fileGroup);

    return ValueListenableBuilder(
      valueListenable: favoriteController.notifier,
      builder: (BuildContext context, FileGroup musicGroup, Widget? child) {
        Widget child = Image.asset((musicGroup.isFavorite==1)?(selectedIcon??Assets.otherLikeS):(icon??Assets.otherLike));
        if(controller==null){
          return CupertinoButton(
            onPressed: (){
              favoriteController.infoChange();
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

