import 'package:flutter/cupertino.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/shared/dialogs/collection_options_panel.dart';
import 'package:echo_vault/core/persistence/media_collection_repository.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/features/collections/collection_detail_screen.dart';

class CollectionListCell extends StatelessWidget {
  final MediaCollection mediaCollection;
  final bool showMoreAction;
  final Widget? action;
  final VoidCallback? onTap;
  const CollectionListCell({
    super.key,
    required this.mediaCollection,
    this.showMoreAction = false,
    this.action,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap!.call();
        } else {
          CollectionDetailScreenHelper.to(mediaCollection: mediaCollection);
        }
      },
      behavior: HitTestBehavior.translucent,
      child: Row(
        spacing: 12,
        children: [
          SizedBox(
            width: 60,
            height: 56,
            child: Stack(
              children: [
                Positioned.fill(
                  top: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xffD8E2F1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                AspectRatio(
                  aspectRatio: 1,
                  child: NetworkImageWidget(
                    url: mediaCollection.thumbnail,
                    radius: 6,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mediaCollection.displayName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  mediaCollection.detail != null
                      ? mediaCollection.detail!
                      : '${mediaCollection.children.length} songs',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xff141414).withAlpha((255 * 0.6).round()),
                  ),
                ),
              ],
            ),
          ),
          if (showMoreAction)
            action ??
                CupertinoButton(
                  onPressed: () {
                    CollectionOptionsPanel.show(
                      musicCollection: mediaCollection,
                    );
                  },
                  sizeStyle: CupertinoButtonSize.small,
                  padding: EdgeInsets.zero,
                  child: Assets.images.collection.listOptions.image(
                    height: 24,
                  ),
                ),
        ],
      ),
    );
  }
}
