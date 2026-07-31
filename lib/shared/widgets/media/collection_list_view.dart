import 'package:flutter/cupertino.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/core/persistence/media_collection_repository.dart';
import 'package:echo_vault/core/models/performer_details.dart';
import 'package:echo_vault/features/discovery/collection_more_screen.dart';
import 'package:echo_vault/features/performers/widgets/performer_part_grid_view.dart';
import 'package:echo_vault/shared/widgets/media/adaptive_list_view.dart';
import 'package:echo_vault/shared/widgets/media/media_h_grid_view.dart';
import 'package:echo_vault/shared/widgets/media/video_part_grid_view.dart';
import 'package:echo_vault/features/collections/widgets/collection_part_grid_view.dart';
import 'package:echo_vault/shared/widgets/section_heading_view.dart';

class CollectionListView extends StatelessWidget {
  final List<MediaCollection> mediaCollections;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final ScrollController? controller;
  final EdgeInsets? padding;

  const CollectionListView({
    super.key,
    this.mediaCollections = const [],
    this.shrinkWrap = false,
    this.physics,
    this.controller,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: shrinkWrap,
      itemCount: mediaCollections.length,
      physics: physics,
      controller: controller,
      padding: padding,
      separatorBuilder: (context, index) {
        return SizedBox(height: 18);
      },
      itemBuilder: (context, index) {
        MediaCollection mediaCollectionLocal = mediaCollections[index];

        return Column(
          spacing: 12,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (mediaCollectionLocal.type != null &&
                mediaCollectionLocal.name.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: SectionHeadingView(
                  title: mediaCollectionLocal.name,
                  onTap: mediaCollectionLocal.id != null
                      ? () {
                          Get.to(
                            CollectionMoreScreen(
                              mediaCollection: mediaCollectionLocal,
                            ),
                            arguments: mediaCollectionLocal,
                            preventDuplicates: false,
                          );
                        }
                      : null,
                ),
              ),
            if (mediaCollectionLocal.type ==
                    MediaCollectionShowType.listMusic ||
                mediaCollectionLocal.type == null)
              AdaptiveListView(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                records: mediaCollectionLocal.children.cast<FileInfo>(),
              ),
            if (mediaCollectionLocal.type ==
                MediaCollectionShowType.responsiveListMusic)
              MediaHGridView(
                fileList: mediaCollectionLocal.children.cast<FileInfo>(),
              ),
            if (mediaCollectionLocal.type ==
                MediaCollectionShowType.twoRowVideo)
              VideoPartGridView(
                fileList: mediaCollectionLocal.children.cast<FileInfo>(),
              ),
            if (mediaCollectionLocal.type ==
                MediaCollectionShowType.twoRowArtist)
              PerformerPartGridView(
                performers: mediaCollectionLocal.children
                    .cast<PerformerDetails>(),
              ),
            if (mediaCollectionLocal.type ==
                MediaCollectionShowType.twoRowPlaylist)
              CollectionPartGridView(
                playlistList: mediaCollectionLocal.children
                    .cast<MediaCollection>(),
              ),
          ],
        );
      },
    );
  }
}
