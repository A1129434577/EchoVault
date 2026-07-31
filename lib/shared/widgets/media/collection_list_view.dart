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
        MediaCollection mediaCollection = mediaCollections[index];

        return Column(
          spacing: 12,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (mediaCollection.type != null && mediaCollection.name.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: SectionHeadingView(
                  title: mediaCollection.name,
                  onTap: mediaCollection.id != null
                      ? () {
                          Get.to(
                            CollectionMoreScreen(
                              mediaCollection: mediaCollection,
                            ),
                            arguments: mediaCollection,
                            preventDuplicates: false,
                          );
                        }
                      : null,
                ),
              ),
            if (mediaCollection.type == MediaCollectionShowType.listMusic ||
                mediaCollection.type == null)
              AdaptiveListView(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                records: mediaCollection.children.cast<FileInfo>(),
              ),
            if (mediaCollection.type ==
                MediaCollectionShowType.responsiveListMusic)
              MediaHGridView(
                fileList: mediaCollection.children.cast<FileInfo>(),
              ),
            if (mediaCollection.type == MediaCollectionShowType.twoRowVideo)
              VideoPartGridView(
                fileList: mediaCollection.children.cast<FileInfo>(),
              ),
            if (mediaCollection.type == MediaCollectionShowType.twoRowArtist)
              PerformerPartGridView(
                performers: mediaCollection.children.cast<PerformerDetails>(),
              ),
            if (mediaCollection.type == MediaCollectionShowType.twoRowPlaylist)
              CollectionPartGridView(
                playlistList: mediaCollection.children.cast<MediaCollection>(),
              ),
          ],
        );
      },
    );
  }
}
