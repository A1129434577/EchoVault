import 'dart:math';

import 'package:flutter/material.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/shared/dialogs/new_collection_dialog.dart';
import 'package:echo_vault/core/persistence/media_collection_repository.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/features/playback/widgets/playback_bar.dart';
import 'package:echo_vault/shared/widgets/resource_state_view.dart';
import 'package:echo_vault/shared/widgets/media/collection_list_view.dart';
import 'package:echo_vault/features/playback/playback_screen.dart';
import 'package:echo_vault/features/collections/controllers/collection_detail_state.dart';
import 'package:echo_vault/shared/widgets/navigation_bar_views.dart';
import 'package:echo_vault/shared/widgets/background_surface.dart';
import 'package:echo_vault/shared/widgets/shared_button.dart';
import 'package:echo_vault/features/collections/widgets/bookmark_collection_view.dart';
import 'package:echo_vault/shared/widgets/paged_refresh_view.dart';

class CollectionDetailScreenHelper {
  static String screenRoute = '/$_CollectionDetailScreen';
  static to({required MediaCollection mediaCollectionArg}) {
    Get.to(
      arguments: mediaCollectionArg,
      preventDuplicates: false,
      _CollectionDetailScreen(mediaCollection: mediaCollectionArg),
    );
  }
}

class _CollectionDetailScreen extends StatefulWidget {
  final MediaCollection mediaCollection;
  const _CollectionDetailScreen({super.key, required this.mediaCollection});

  @override
  State<_CollectionDetailScreen> createState() =>
      _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<_CollectionDetailScreen> {
  late final MediaCollection mediaCollection = widget.mediaCollection;
  late final CollectionDetailState controller = CollectionDetailState(
    mediaCollection: mediaCollection,
  );

  final ScrollController _scrollController = ScrollController();
  late final bool _isSelfBuiltPlaylist =
      mediaCollection.id == null ||
      mediaCollection.id?.startsWith(
            NewCollectionDialog.generatedCollectionPrefix,
          ) ==
          true;
  final ValueNotifier<bool> _isHeaderClosed = ValueNotifier(false);
  late VoidCallback _scrollControllerListener;

  @override
  void initState() {
    super.initState();
    _scrollControllerListener = () {
      _isHeaderClosed.value = (_scrollController.offset >= 120);
    };
    _scrollController.addListener(_scrollControllerListener);

    if (_isSelfBuiltPlaylist) {
      controller.resourceList.value = [mediaCollection];
    }

    if (!_isSelfBuiltPlaylist) {
      controller.fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundSurface(
      child: PlaybackBar(
        builder: (BuildContext context, double barHeight) {
          return Scaffold(
            appBar: AppBar(
              leading: AppBlackBackButton(),
              title: ValueListenableBuilder(
                valueListenable: _isHeaderClosed,
                builder:
                    (BuildContext context, bool isHeaderClosed, Widget? child) {
                      return Visibility(
                        visible: isHeaderClosed,
                        child: Text(mediaCollection.displayName),
                      );
                    },
              ),
              actionsPadding: EdgeInsets.only(right: 16),
              actions: [
                if (_isSelfBuiltPlaylist == false)
                  SizedBox(
                    width: 24,
                    child: BookmarkCollectionView(
                      mediaCollection: mediaCollection,
                    ),
                  ),
              ],
            ),
            body: NestedScrollView(
              controller: _scrollController,
              headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 150,
                    leading: Container(),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        padding: EdgeInsets.only(
                          left: 12,
                          right: 12,
                          bottom: 22,
                        ),
                        child: Row(
                          spacing: 16,
                          children: [
                            AspectRatio(
                              aspectRatio: (128 + 8) / 128,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    top: 8,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Color(0xffD8E2F1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                  AspectRatio(
                                    aspectRatio: 1,
                                    child: NetworkImageWidget(
                                      radius: 8,
                                      url: mediaCollection.thumbnail,
                                      fit: BoxFit.fill,
                                      defaultView: Assets
                                          .images
                                          .media
                                          .albumPlaceholder
                                          .image(fit: BoxFit.fill),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                spacing: 12,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mediaCollection.displayName,
                                    maxLines: 2,
                                    textAlign: TextAlign.start,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  ValueListenableBuilder(
                                    valueListenable: controller.resourceList,
                                    builder:
                                        (
                                          BuildContext context,
                                          List<MediaCollection>? resourceList,
                                          Widget? child,
                                        ) {
                                          return Text(
                                            '${mediaCollection.children.isNotEmpty ? mediaCollection.children.length : ''} Songs${mediaCollection.detail != null ? ' • ${mediaCollection.detail}' : ''}',
                                            textAlign: TextAlign.start,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                              color: Color(
                                                0xff121212,
                                              ).withAlpha((255 * 0.75).round()),
                                            ),
                                          );
                                        },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ];
              },
              body: Column(
                children: [
                  _actionsView(),
                  SizedBox(height: 22),
                  Expanded(child: _fileListView(barHeight)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollControllerListener);
    controller.dispose();
    super.dispose();
  }

  Widget _actionsView() {
    return ValueListenableBuilder(
      valueListenable: controller.resourceList,
      builder:
          (
            BuildContext buildContext,
            List<MediaCollection>? currentValue,
            Widget? nestedEntry,
          ) {
            if (mediaCollection.children.isEmpty) {
              return SizedBox();
            }
            return Container(
              height: 48,
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                spacing: 20,
                children: [
                  Expanded(
                    child: SharedButton(
                      onPressed: () {
                        if (mediaCollection.children.isNotEmpty) {
                          PlaybackNavigator.toPlay(
                            mediaQueue: mediaCollection.children.cast(),
                            playModeArg: PlayerPlayMode.loop,
                          );
                        }
                      },
                      fontSize: 16,
                      icon: Assets.images.collection.playlistPlay.image(),
                      title: 'Play'.translate,
                    ),
                  ),
                  Expanded(
                    child: SharedButton(
                      onPressed: () {
                        if (mediaCollection.children.isNotEmpty) {
                          List<FileInfo> entries = mediaCollection.children
                              .cast();
                          Random randomLocal = Random();
                          int randomIndexLocal = randomLocal.nextInt(
                            entries.length,
                          );
                          PlaybackNavigator.toPlay(
                            mediaQueue: entries,
                            playModeArg: PlayerPlayMode.shuffle,
                            mediaEntry: entries[randomIndexLocal],
                          );
                        }
                      },
                      fontSize: 16,
                      isWhite: true,
                      icon: Assets.images.collection.playlistShuffle.image(),
                      title: 'Shuffle'.translate,
                    ),
                  ),
                ],
              ),
            );
          },
    );
  }

  Widget _fileListView(double barHeightArg) {
    return PagedRefreshView(
      onRefresh: _isSelfBuiltPlaylist
          ? null
          : () {
              return controller.fetchData();
            },
      // onLoading: mediaCollection.playlistType==CollectionType.LOCKUP_CONTENT_TYPE_PLAYLIST.name||
      //     mediaCollection.playlistType==CollectionType.LOCKUP_CONTENT_TYPE_ALBUM.name?() {
      //   return controller.loadMoreYTData();
      // }:null,
      isEmpty: _isSelfBuiltPlaylist && mediaCollection.children.isEmpty,
      controller: controller.refreshController,
      childBuilder: (buildContext, physicsInputArg) {
        return ValueListenableBuilder(
          valueListenable: controller.state,
          builder:
              (
                BuildContext buildContext,
                ResourceStatus stateArg,
                Widget? nestedEntry,
              ) {
                return ResourceStateView(
                  state: controller.resourceList.value?.isNotEmpty == true
                      ? ResourceStatus.source
                      : stateArg,
                  action: () {
                    controller.fetchData();
                  },
                  child: CollectionListView(
                    physics: physicsInputArg,
                    padding: EdgeInsets.only(bottom: barHeightArg),
                    mediaCollections: controller.resourceList.value ?? [],
                  ),
                );
              },
        );
      },
    );
  }
}
