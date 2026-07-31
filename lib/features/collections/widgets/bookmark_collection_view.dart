import 'package:flutter/cupertino.dart';
import 'package:echo_vault/core/state/bookmark_collection_state.dart';
import 'package:echo_vault/core/persistence/media_collection_repository.dart';
import 'package:echo_vault/generated/assets.dart';

export 'package:echo_vault/core/state/bookmark_media_state.dart';

class BookmarkCollectionView extends StatelessWidget {
  final MediaCollection mediaCollection;
  final BookmarkCollectionState? controller;
  final String? icon;
  final String? selectedIcon;
  const BookmarkCollectionView({
    super.key,
    required this.mediaCollection,
    this.controller,
    this.icon,
    this.selectedIcon,
  });

  @override
  Widget build(BuildContext context) {
    BookmarkCollectionState favoriteControllerLocal =
        controller ??
        BookmarkCollectionState(mediaCollectionArg: mediaCollection);

    return ValueListenableBuilder(
      valueListenable: favoriteControllerLocal.notifier,
      builder:
          (
            BuildContext context,
            MediaCollection musicCollection,
            Widget? child,
          ) {
            Widget nestedEntry = Image.asset(
              musicCollection.isFavorite == 1
                  ? (selectedIcon ??
                        Assets.images.collection.favoriteActive.path)
                  : (icon ?? Assets.images.collection.favorite.path),
            );
            if (controller == null) {
              return CupertinoButton(
                onPressed: () {
                  favoriteControllerLocal.updateCollection();
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
