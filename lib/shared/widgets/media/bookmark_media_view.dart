import 'package:flutter/cupertino.dart';
import 'package:player_base/models/file_info.dart';
import 'package:echo_vault/core/state/bookmark_media_state.dart';
import 'package:echo_vault/generated/assets.dart';

export 'package:echo_vault/core/state/bookmark_media_state.dart';

class BookmarkMediaView extends StatelessWidget {
  final FileInfo? mediaDetails;
  final BookmarkMediaState? controller;
  final String? icon;
  final String? selectedIcon;
  const BookmarkMediaView({
    super.key,
    required this.mediaDetails,
    this.controller,
    this.icon,
    this.selectedIcon,
  });

  @override
  Widget build(BuildContext context) {
    BookmarkMediaState favoriteControllerLocal =
        controller ?? BookmarkMediaState();
    favoriteControllerLocal.notifier.value = mediaDetails;

    return ValueListenableBuilder(
      valueListenable: favoriteControllerLocal.notifier,
      builder: (BuildContext context, FileInfo? mediaDetails, Widget? child) {
        Widget nestedEntry = Image.asset(
          mediaDetails?.isFavorite == 1
              ? (selectedIcon ?? Assets.images.collection.favoriteActive.path)
              : (icon ?? Assets.images.collection.favorite.path),
        );
        if (controller == null) {
          return CupertinoButton(
            onPressed: () {
              favoriteControllerLocal.favoriteStateChange();
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
