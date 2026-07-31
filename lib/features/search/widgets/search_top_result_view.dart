import 'package:flutter/material.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/core/state/bookmark_performer_state.dart';
import 'package:echo_vault/core/state/bookmark_collection_state.dart';
import 'package:echo_vault/core/persistence/media_collection_repository.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/core/models/performer_details.dart';
import 'package:echo_vault/features/performers/widgets/performer_list_cell.dart';
import 'package:echo_vault/features/performers/widgets/bookmark_performer_view.dart';
import 'package:echo_vault/features/search/controllers/search_state.dart';
import 'package:echo_vault/features/discovery/controllers/discovery_state.dart';
import 'package:echo_vault/features/playback/playback_screen.dart';
import 'package:echo_vault/features/collections/widgets/bookmark_collection_view.dart';
import 'package:echo_vault/features/collections/widgets/collection_list_cell.dart';
import 'package:echo_vault/shared/widgets/shared_button.dart';
import 'package:echo_vault/shared/widgets/media/adaptive_list_view.dart';
import 'package:echo_vault/shared/widgets/media/media_cell.dart';
import 'package:echo_vault/shared/widgets/media/save_media_view.dart';
import 'package:echo_vault/shared/widgets/paged_refresh_view.dart';

class SearchTopResultView extends StatelessWidget {
  final SearchState controller;
  const SearchTopResultView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return PagedRefreshView(
      onLoading: DiscoveryState.instance.isYoutubeMusicEnable.value
          ? null
          : () async {
              return controller.loadMoreYTData();
            },
      controller: controller.refreshController,
      child: ValueListenableBuilder(
        valueListenable: controller.resourceList,
        builder:
            (
              BuildContext context,
              List<MediaCollection>? resourceList,
              Widget? child,
            ) {
              List<MediaCollection> topResultList =
                  resourceList
                      ?.where((mediaCollection) {
                        return mediaCollection.params == null;
                      })
                      .firstOrNull
                      ?.children
                      .cast() ??
                  [];

              MediaCollection? topCardGroup = topResultList.where((
                mediaCollection,
              ) {
                return mediaCollection.type == null;
              }).firstOrNull;

              List children =
                  topResultList
                      .where((mediaCollection) {
                        return mediaCollection.type != null;
                      })
                      .firstOrNull
                      ?.children ??
                  [];

              return ListView.separated(
                itemCount:
                    (topCardGroup != null ? 1 : 0) +
                    (children.isNotEmpty ? 1 : 0),
                separatorBuilder: (context, index) {
                  return SizedBox(height: 20);
                },
                itemBuilder: (context, index) {
                  if (topCardGroup != null && index == 0) {
                    return _topPartCell(topCardGroup);
                  }

                  return AdaptiveListView(
                    records: children,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                  );
                },
              );
            },
      ),
    );
  }

  Widget _topPartCell(MediaCollection topGroup) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      margin: EdgeInsets.symmetric(horizontal: 12),
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: ListView.separated(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: topGroup.children.length,
        separatorBuilder: (context, index) {
          return SizedBox(height: 20);
        },
        itemBuilder: (context, index) {
          final item = topGroup.children[index];
          Widget? actionButton;
          if (item is FileInfo) {
            final TransferMediaState downloadFileController =
                TransferMediaState();
            actionButton = SharedButton(
              onPressed: () {
                downloadFileController.saveStateChange();
              },
              fontSize: 16,
              isWhite: true,
              icon: SaveMediaView(
                mediaDetails: item,
                icon: Assets.images.collection.saveAccent.path,
                controller: downloadFileController,
              ),
              title: 'Offline'.translate,
            );
          } else if (item is PerformerDetails) {
            final BookmarkPerformerState artistController =
                BookmarkPerformerState(artist: item);
            actionButton = SharedButton(
              onPressed: () {
                artistController.favoriteStateChange();
              },
              fontSize: 16,
              isWhite: true,
              icon: BookmarkPerformerView(
                artist: item,
                icon: Assets.images.collection.favoriteAccent.path,
                controller: artistController,
              ),
              title: 'Like'.translate,
            );
          } else if (item is MediaCollection) {
            final BookmarkCollectionState groupController =
                BookmarkCollectionState(mediaCollection: item);
            actionButton = SharedButton(
              onPressed: () {
                groupController.infoChange();
              },
              fontSize: 16,
              isWhite: true,
              icon: BookmarkCollectionView(
                mediaCollection: item,
                icon: Assets.images.collection.favoriteAccent.path,
                controller: groupController,
              ),
              title: 'Like'.translate,
            );
          }

          if (index == 0) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 56, child: _getTopCell(item)),
                SizedBox(height: 18),
                SizedBox(
                  height: 42,
                  child: Row(
                    spacing: 22,
                    children: [
                      Expanded(
                        child: SharedButton(
                          onPressed: () {
                            List<MediaCollection> topResultList =
                                controller.resourceList.value
                                    ?.where((mediaCollection) {
                                      return mediaCollection.params == null;
                                    })
                                    .firstOrNull
                                    ?.children
                                    .cast() ??
                                [];
                            List<FileInfo> fileList = [];
                            for (final mediaCollection in topResultList) {
                              fileList.addAll(
                                mediaCollection.children.whereType<FileInfo>(),
                              );
                            }
                            PlaybackNavigator.toPlay(fileList: fileList);
                          },
                          fontSize: 16,
                          icon: Assets.images.collection.playlistPlay
                              .image(),
                          title: 'Play'.translate,
                        ),
                      ),
                      if (actionButton != null) Expanded(child: actionButton),
                    ],
                  ),
                ),
                SizedBox(height: 2),
              ],
            );
          }

          return SizedBox(height: 56, child: _getTopCell(item));
        },
      ),
    );
  }

  Widget _getTopCell(dynamic item) {
    if (item is FileInfo) {
      return GestureDetector(
        onTap: () {
          List<MediaCollection> topResultList =
              controller.resourceList.value
                  ?.where((mediaCollection) {
                    return mediaCollection.params == null;
                  })
                  .firstOrNull
                  ?.children
                  .cast() ??
              [];

          List<FileInfo>? fileList = topResultList.firstOrNull?.children
              .whereType<FileInfo>()
              .toList();
          if (fileList != null) {
            PlaybackNavigator.toPlay(fileList: fileList, mediaDetails: item);
          }
        },
        behavior: HitTestBehavior.translucent,
        child: MediaCell(mediaDetails: item),
      );
    } else if (item is PerformerDetails) {
      return PerformerListCell(
        performerDetails: item,
        action: Assets.images.common.optionsMuted.image(),
      );
    } else if (item is MediaCollection) {
      return CollectionListCell(
        mediaCollection: item,
        showMoreAction: true,
        action: Assets.images.common.optionsMuted.image(width: 24),
      );
    }
    return SizedBox();
  }
}
