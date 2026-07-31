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
    BookmarkPerformerState favoriteController =
        controller ?? BookmarkPerformerState(artist: artist);

    return ValueListenableBuilder(
      valueListenable: favoriteController.notifier,
      builder: (BuildContext context, PerformerDetails artist, Widget? child) {
        Widget child = Image.asset(
          artist.isFavorite == 1
              ? (selectedIcon ??
                    Assets.images.collection.favoriteActive.path)
              : (icon ?? Assets.images.collection.favorite.path),
        );
        if (controller == null) {
          return CupertinoButton(
            onPressed: () {
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
