import 'package:flutter/cupertino.dart';
import 'package:echo_vault/core/state/bookmark_performer_state.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/core/models/performer_details.dart';

export 'package:echo_vault/core/state/bookmark_media_state.dart';

class BookmarkPerformerView extends StatelessWidget {
  final PerformerDetails artist;
  final BookmarkPerformerState? controller;
  final String? icon;
  final String? selectedIcon;
  const BookmarkPerformerView({
    super.key,
    required this.artist,
    this.controller,
    this.icon,
    this.selectedIcon,
  });

  @override
  Widget build(BuildContext context) {
    BookmarkPerformerState favoriteControllerLocal =
        controller ?? BookmarkPerformerState(artistArg: artist);

    return ValueListenableBuilder(
      valueListenable: favoriteControllerLocal.notifier,
      builder: (BuildContext context, PerformerDetails artist, Widget? child) {
        Widget nestedEntry = Image.asset(
          artist.isFavorite == 1
              ? (selectedIcon ?? Assets.images.collection.favoriteActive.path)
              : (icon ?? Assets.images.collection.favorite.path),
        );
        if (controller == null) {
          return CupertinoButton(
            onPressed: () {
              favoriteControllerLocal.toggleBookmark();
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
