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
              List<MediaCollection> topResultListLocal =
                  resourceList
                      ?.where((mediaCollection) {
                        return mediaCollection.params == null;
                      })
                      .firstOrNull
                      ?.children
                      .cast() ??
                  [];

              MediaCollection? topCardGroupLocal = topResultListLocal.where((
                mediaCollection,
              ) {
                return mediaCollection.type == null;
              }).firstOrNull;

              List childEntries =
                  topResultListLocal
                      .where((mediaCollection) {
                        return mediaCollection.type != null;
                      })
                      .firstOrNull
                      ?.children ??
                  [];

              return ListView.separated(
                itemCount:
                    (topCardGroupLocal != null ? 1 : 0) +
                    (childEntries.isNotEmpty ? 1 : 0),
                separatorBuilder: (context, index) {
                  return SizedBox(height: 20);
                },
                itemBuilder: (context, index) {
                  if (topCardGroupLocal != null && index == 0) {
                    return _topPartCell(topCardGroupLocal);
                  }

                  return AdaptiveListView(
                    records: childEntries,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                  );
                },
              );
            },
      ),
    );
  }

  Widget _getTopCell(dynamic entry) {
    if (entry is FileInfo) {
      return GestureDetector(
        onTap: () {
          List<MediaCollection> topResultListLocal =
              controller.resourceList.value
                  ?.where((mediaCollectionArg) {
                    return mediaCollectionArg.params == null;
                  })
                  .firstOrNull
                  ?.children
                  .cast() ??
              [];

          List<FileInfo>? mediaQueue = topResultListLocal.firstOrNull?.children
              .whereType<FileInfo>()
              .toList();
          if (mediaQueue != null) {
            PlaybackNavigator.toPlay(mediaQueue: mediaQueue, mediaEntry: entry);
          }
        },
        behavior: HitTestBehavior.translucent,
        child: MediaCell(mediaDetails: entry),
      );
    } else if (entry is PerformerDetails) {
      return PerformerListCell(
        performerDetails: entry,
        action: Assets.images.common.optionsMuted.image(),
      );
    } else if (entry is MediaCollection) {
      return CollectionListCell(
        mediaCollection: entry,
        showMoreAction: true,
        action: Assets.images.common.optionsMuted.image(width: 24),
      );
    }
    return SizedBox();
  }

  Widget _topPartCell(MediaCollection topGroupArg) {
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
        itemCount: topGroupArg.children.length,
        separatorBuilder: (buildContext, itemIndex) {
          return SizedBox(height: 20);
        },
        itemBuilder: (buildContext, itemIndex) {
          final entry = topGroupArg.children[itemIndex];
          Widget? actionButtonLocal;
          if (entry is FileInfo) {
            final TransferMediaState downloadFileControllerLocal =
                TransferMediaState();
            actionButtonLocal = SharedButton(
              onPressed: () {
                downloadFileControllerLocal.saveStateChange();
              },
              fontSize: 16,
              isWhite: true,
              icon: SaveMediaView(
                mediaDetails: entry,
                icon: Assets.images.collection.saveAccent.path,
                controller: downloadFileControllerLocal,
              ),
              title: 'Offline'.translate,
            );
          } else if (entry is PerformerDetails) {
            final BookmarkPerformerState artistControllerLocal =
                BookmarkPerformerState(artistArg: entry);
            actionButtonLocal = SharedButton(
              onPressed: () {
                artistControllerLocal.favoriteStateChange();
              },
              fontSize: 16,
              isWhite: true,
              icon: BookmarkPerformerView(
                artist: entry,
                icon: Assets.images.collection.favoriteAccent.path,
                controller: artistControllerLocal,
              ),
              title: 'Like'.translate,
            );
          } else if (entry is MediaCollection) {
            final BookmarkCollectionState groupControllerLocal =
                BookmarkCollectionState(mediaCollectionArg: entry);
            actionButtonLocal = SharedButton(
              onPressed: () {
                groupControllerLocal.infoChange();
              },
              fontSize: 16,
              isWhite: true,
              icon: BookmarkCollectionView(
                mediaCollection: entry,
                icon: Assets.images.collection.favoriteAccent.path,
                controller: groupControllerLocal,
              ),
              title: 'Like'.translate,
            );
          }

          if (itemIndex == 0) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 56, child: _getTopCell(entry)),
                SizedBox(height: 18),
                SizedBox(
                  height: 42,
                  child: Row(
                    spacing: 22,
                    children: [
                      Expanded(
                        child: SharedButton(
                          onPressed: () {
                            List<MediaCollection> topResultListLocal =
                                controller.resourceList.value
                                    ?.where((mediaCollectionArg) {
                                      return mediaCollectionArg.params == null;
                                    })
                                    .firstOrNull
                                    ?.children
                                    .cast() ??
                                [];
                            List<FileInfo> mediaQueue = [];
                            for (final mediaCollection in topResultListLocal) {
                              mediaQueue.addAll(
                                mediaCollection.children.whereType<FileInfo>(),
                              );
                            }
                            PlaybackNavigator.toPlay(mediaQueue: mediaQueue);
                          },
                          fontSize: 16,
                          icon: Assets.images.collection.playlistPlay.image(),
                          title: 'Play'.translate,
                        ),
                      ),
                      if (actionButtonLocal != null)
                        Expanded(child: actionButtonLocal),
                    ],
                  ),
                ),
                SizedBox(height: 2),
              ],
            );
          }

          return SizedBox(height: 56, child: _getTopCell(entry));
        },
      ),
    );
  }
}
