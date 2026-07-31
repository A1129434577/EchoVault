import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/core/persistence/media_collection_repository.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/core/models/performer_details.dart';
import 'package:echo_vault/features/performers/controllers/performer_detail_state.dart';
import 'package:echo_vault/features/performers/widgets/bookmark_performer_view.dart';
import 'package:echo_vault/features/playback/playback_screen.dart';
import 'package:echo_vault/features/playback/widgets/playback_bar.dart';
import 'package:echo_vault/shared/widgets/navigation_bar_views.dart';
import 'package:echo_vault/shared/widgets/resource_state_view.dart';
import 'package:echo_vault/shared/widgets/shared_button.dart';
import 'package:echo_vault/shared/widgets/media/collection_list_view.dart';
import 'package:echo_vault/shared/widgets/paged_refresh_view.dart';

class PerformerDetailScreenHelper {
  static String routeName = '/$_PerformerDetailScreen';
  static to({required PerformerDetails performerProfile}) {
    Get.to(
      arguments: performerProfile,
      preventDuplicates: false,
      _PerformerDetailScreen(performerDetails: performerProfile),
    );
  }
}

class _PerformerDetailScreen extends StatefulWidget {
  final PerformerDetails performerDetails;
  const _PerformerDetailScreen({super.key, required this.performerDetails});

  @override
  State<_PerformerDetailScreen> createState() => _PerformerDetailScreenState();
}

class _PerformerDetailScreenState extends State<_PerformerDetailScreen> {
  late final PerformerDetails performerDetails = widget.performerDetails;
  late final PerformerDetailState controller = PerformerDetailState(
    performerDetails: performerDetails,
  );

  final ValueNotifier<bool> _isHeaderClosed = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();
  late VoidCallback _scrollControllerListener;

  @override
  void initState() {
    super.initState();

    _scrollControllerListener = () {
      _isHeaderClosed.value = (_scrollController.offset >= 90);
    };
    _scrollController.addListener(_scrollControllerListener);
    controller.fetchData();
  }

  @override
  Widget build(BuildContext context) {
    double topHeightLocal = 90;
    return Stack(
      children: [
        FractionallySizedBox(
          widthFactor: 1,
          child: SizedBox(
            height:
                topHeightLocal +
                kToolbarHeight +
                MediaQuery.of(context).padding.top +
                20,
            child: ValueListenableBuilder(
              valueListenable: controller.hdThumbnail,
              builder:
                  (BuildContext context, String hdThumbnail, Widget? child) {
                    return NetworkImageWidget(
                      url: hdThumbnail,
                      defaultView: Assets.images.artist.artistBackdrop.image(
                        fit: BoxFit.fill,
                      ),
                    );
                  },
            ),
          ),
        ),
        ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Container(),
          ),
        ),
        PlaybackBar(
          builder: (BuildContext context, double barHeight) {
            return Scaffold(
              appBar: AppBar(
                leading: AppBlackBackButton(
                  icon: Assets.images.artist.navBackLight.path,
                ),
                title: ValueListenableBuilder(
                  valueListenable: _isHeaderClosed,
                  builder:
                      (
                        BuildContext context,
                        bool isHeaderClosed,
                        Widget? child,
                      ) {
                        return Visibility(
                          visible: isHeaderClosed,
                          child: Text(
                            performerDetails.name,
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      },
                ),
                actionsPadding: EdgeInsets.only(right: 16),
                actions: [
                  SizedBox(
                    width: 24,
                    child: BookmarkPerformerView(
                      artist: performerDetails,
                      icon: Assets.images.collection.favoriteLight.path,
                    ),
                  ),
                ],
              ),
              body: NestedScrollView(
                controller: _scrollController,
                headerSliverBuilder:
                    (BuildContext context, bool innerBoxIsScrolled) {
                      return [
                        SliverAppBar(
                          expandedHeight: topHeightLocal,
                          leading: Container(),
                          flexibleSpace: FlexibleSpaceBar(
                            background: Container(
                              padding: EdgeInsets.only(
                                left: 12,
                                right: 12,
                                bottom: 10,
                              ),
                              child: Row(
                                spacing: 16,
                                children: [
                                  SizedBox(
                                    height: 48,
                                    width: 48,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Assets.images.artist.profileAvatar
                                            .image(),
                                        Container(
                                          clipBehavior: Clip.hardEdge,
                                          decoration: BoxDecoration(
                                            border: BoxBorder.all(
                                              width: 1.5,
                                              color: Color(0xffB8D2FF),
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                          ),
                                          child: ValueListenableBuilder(
                                            valueListenable:
                                                controller.hdThumbnail,
                                            builder:
                                                (
                                                  BuildContext context,
                                                  String hdThumbnail,
                                                  Widget? child,
                                                ) {
                                                  return NetworkImageWidget(
                                                    url: hdThumbnail,
                                                    radius: 24,
                                                  );
                                                },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      performerDetails.name,
                                      maxLines: 2,
                                      textAlign: TextAlign.start,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 22,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ];
                    },
                body: ValueListenableBuilder(
                  valueListenable: _isHeaderClosed,
                  builder:
                      (
                        BuildContext context,
                        bool isHeaderClosed,
                        Widget? child,
                      ) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(isHeaderClosed ? 0 : 20),
                              topRight: Radius.circular(
                                isHeaderClosed ? 0 : 20,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              SizedBox(height: 24),
                              _actionsView(),
                              SizedBox(height: 24),
                              Expanded(
                                child: PagedRefreshView(
                                  onRefresh: () async {
                                    await controller.fetchData();
                                  },
                                  controller: controller.refreshController,
                                  childBuilder: (context, physics) {
                                    return ValueListenableBuilder(
                                      valueListenable: controller.state,
                                      builder:
                                          (
                                            BuildContext context,
                                            ResourceStatus state,
                                            Widget? child,
                                          ) {
                                            return ResourceStateView(
                                              state:
                                                  controller
                                                          .resourceList
                                                          .value
                                                          ?.isNotEmpty ==
                                                      true
                                                  ? ResourceStatus.source
                                                  : state,
                                              action: () {
                                                controller.fetchData();
                                              },
                                              child: CollectionListView(
                                                physics: physics,
                                                padding: EdgeInsets.only(
                                                  bottom: barHeight,
                                                ),
                                                mediaCollections:
                                                    controller
                                                        .resourceList
                                                        .value ??
                                                    [],
                                              ),
                                            );
                                          },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollControllerListener);
    controller.dispose();
    super.dispose();
  }

  Widget _actionsView() {
    return Container(
      height: 42,
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        spacing: 24,
        children: [
          Expanded(
            child: SharedButton(
              onPressed: () {
                MediaCollection? mediaCollectionLocal = controller
                    .resourceList
                    .value
                    ?.where(
                      (mediaCollectionArg) =>
                          mediaCollectionArg.type ==
                          MediaCollectionShowType.listMusic,
                    )
                    .firstOrNull;
                if (mediaCollectionLocal?.children.isNotEmpty == true) {
                  PlaybackNavigator.toPlay(
                    mediaQueue: mediaCollectionLocal!.children.cast(),
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
                MediaCollection? mediaCollectionLocal = controller
                    .resourceList
                    .value
                    ?.where(
                      (mediaCollectionArg) =>
                          mediaCollectionArg.type ==
                          MediaCollectionShowType.listMusic,
                    )
                    .firstOrNull;
                if (mediaCollectionLocal?.children.isNotEmpty == true) {
                  List<FileInfo> entries = mediaCollectionLocal!.children
                      .cast();
                  Random randomLocal = Random();
                  int randomIndexLocal = randomLocal.nextInt(entries.length);
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
  }
}
