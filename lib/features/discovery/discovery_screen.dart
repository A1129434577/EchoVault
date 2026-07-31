import 'dart:ui';

import 'package:ad/ad.dart';
import 'package:echo_vault/features/preferences/preferences_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/shared/dialogs/upgrade_dialog.dart';
import 'package:echo_vault/core/persistence/media_collection_repository.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/core/models/performer_details.dart';
import 'package:echo_vault/features/search/search_screen.dart';
import 'package:echo_vault/features/discovery/controllers/discovery_state.dart';
import 'package:echo_vault/features/discovery/suggestions_screen.dart';
import 'package:echo_vault/core/utilities/notification_helper.dart';
import 'package:echo_vault/shared/widgets/media/collection_list_view.dart';
import 'package:echo_vault/features/performers/performer_list_screen.dart';
import 'package:echo_vault/features/collections/collection_detail_screen.dart';
import 'package:echo_vault/shared/widgets/dialog_text_field.dart';
import 'package:echo_vault/features/performers/widgets/performer_part_grid_view.dart';
import 'package:echo_vault/shared/widgets/background_surface.dart';
import 'package:echo_vault/shared/widgets/media/media_h_grid_view.dart';
import 'package:echo_vault/features/playback/widgets/playback_bar.dart';
import 'package:echo_vault/shared/widgets/paged_refresh_view.dart';
import 'package:echo_vault/shared/widgets/section_heading_view.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final DiscoveryState controller = DiscoveryState.instance;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 3), () {
      AdvertisingId.id(true);
    });
    Future.delayed(Duration(seconds: 6), () {
      AdvertisingId.id(true);
    });
    Future.delayed(Duration(seconds: 2), () async {
      await AdHelper.configUmp();
      if ((await EventsInfoUtil.isFirstIn) == false) {
        NotificationHelper.init();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      UpgradeDialog.show();
    });
    controller.queryAllLocalData().then((e) async {
      controller.refreshController.callRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundSurface(
      child: PlaybackBar(
        builder: (BuildContext context, double barHeight) {
          return Scaffold(
            appBar: AppBar(
              titleSpacing: 0,
              title: _searchBar(),
              centerTitle: false,
            ),
            body: Column(
              children: [
                SizedBox(height: 18),
                Expanded(
                  child: PagedRefreshView(
                    onRefresh: () {
                      return controller.refreshResource();
                    },
                    onLoading: () {
                      return controller.loadMoreResource();
                    },
                    controller: controller.refreshController,
                    footerPadding: EdgeInsets.only(bottom: barHeight),
                    childBuilder: (context, physics) {
                      return ListView(
                        physics: physics,
                        clipBehavior: Clip.none,
                        children: [
                          ValueListenableBuilder(
                            valueListenable: controller.recommendList,
                            builder:
                                (
                                  BuildContext context,
                                  List<FileInfo> recommendList,
                                  Widget? child,
                                ) {
                                  return ValueListenableBuilder(
                                    valueListenable: controller.playlistList,
                                    builder:
                                        (
                                          BuildContext context,
                                          List<MediaCollection> playlistList,
                                          Widget? child,
                                        ) {
                                          return ValueListenableBuilder(
                                            valueListenable:
                                                controller.isYoutubeMusicEnable,
                                            builder:
                                                (
                                                  BuildContext context,
                                                  bool isYoutubeMusicEnable,
                                                  Widget? child,
                                                ) {
                                                  return Column(
                                                    spacing: 18,
                                                    children: [
                                                      if (recommendList
                                                          .isNotEmpty)
                                                        _recommendView(
                                                          recommendList,
                                                        ),
                                                      if (playlistList
                                                          .isNotEmpty)
                                                        _myPlaylistView(
                                                          playlistList,
                                                        ),
                                                      _myArtistsView(),
                                                      if (isYoutubeMusicEnable ==
                                                          false)
                                                        _topChartsView(),
                                                      _resourceViews(),
                                                    ],
                                                  );
                                                },
                                          );
                                        },
                                  );
                                },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _myArtistsView() {
    return Column(
      spacing: 12,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: ValueListenableBuilder(
            valueListenable: controller.isYoutubeMusicEnable,
            builder:
                (
                  BuildContext buildContext,
                  bool isYoutubeMusicEnableArg,
                  Widget? nestedEntry,
                ) {
                  return SectionHeadingView(
                    onTap: isYoutubeMusicEnableArg
                        ? () {
                            Get.to(
                              PerformerListScreen(
                                performers: controller.performers.value,
                                mediaCollection: MediaCollection(
                                  id: 'FEmusic_charts',
                                ),
                              ),
                            );
                          }
                        : null,
                    title: 'Artist'.translate,
                  );
                },
          ),
        ),
        ValueListenableBuilder(
          valueListenable: controller.performers,
          builder:
              (
                BuildContext buildContext,
                List<PerformerDetails> performersArg,
                Widget? nestedEntry,
              ) {
                if (performersArg.length > 6) {
                  performersArg = performersArg.sublist(0, 6);
                }
                return PerformerPartGridView(performers: performersArg);
              },
        ),
      ],
    );
  }

  Widget _myPlaylistView(List<MediaCollection> playlistListArg) {
    return Column(
      spacing: 12,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: SectionHeadingView(title: 'My Playlist'.translate),
        ),
        LayoutBuilder(
          builder: (BuildContext buildContext, BoxConstraints constraintsArg) {
            double itemWidthLocal = (constraintsArg.maxWidth - 10 * 3) / 7 * 2;
            double aspectRatioLocal = 100 / 88;
            return SizedBox(
              height: itemWidthLocal / 100 * 88 + 25,
              child: GridView.builder(
                padding: EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  mainAxisSpacing: 10,
                  mainAxisExtent: itemWidthLocal,
                  crossAxisCount: 1,
                ),
                itemCount: playlistListArg.length,
                itemBuilder: (BuildContext buildContext, int itemIndex) {
                  MediaCollection mediaCollectionLocal =
                      playlistListArg[itemIndex];
                  return GestureDetector(
                    onTap: () {
                      CollectionDetailScreenHelper.to(
                        mediaCollectionArg: mediaCollectionLocal,
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AspectRatio(
                          aspectRatio: aspectRatioLocal,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Assets.images.media.albumPlaceholder.image(),
                              NetworkImageWidget(
                                url: mediaCollectionLocal.thumbnail,
                                fit: BoxFit.fill,
                                radius: 12,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          mediaCollectionLocal.displayName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _recommendView(List<FileInfo> suggestedItems) {
    return Column(
      spacing: 12,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: SectionHeadingView(
            title: 'Recommend Radio'.translate,
            onTap: () {
              Get.to(
                SuggestionsScreen(fileList: controller.recommendList.value),
              );
            },
          ),
        ),
        MediaHGridView(fileList: suggestedItems),
      ],
    );
  }

  Widget _resourceViews() {
    return ValueListenableBuilder(
      valueListenable: controller.resourceFileGroupList,
      builder:
          (
            BuildContext buildContext,
            List<MediaCollection> resourceFileGroupListArg,
            Widget? nestedEntry,
          ) {
            return CollectionListView(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              mediaCollections: resourceFileGroupListArg,
            );
          },
    );
  }

  Widget _searchBar() {
    return Container(
      height: 48,
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        spacing: 15,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Get.to(SearchScreen(tag: SearchScreen.homeTag));
              },
              child: DialogTextField(
                enabled: false,
                borderRadius: 24,
                hintText: 'Search for music'.translate,
                borderSide: BorderSide(width: 1.5, color: Color(0xff337DFF)),
                suffixIcon: Container(
                  alignment: Alignment.center,
                  width: 48,
                  child: Assets.images.search.historySearch.image(width: 24),
                ),
              ),
            ),
          ),
          CupertinoButton(
            onPressed: () {
              Get.to(PreferencesScreen());
            },
            sizeStyle: CupertinoButtonSize.small,
            padding: EdgeInsets.zero,
            child: Assets.images.common.settings.image(width: 24),
          ),
        ],
      ),
    );
  }

  Widget _topChartsView() {
    List<String> iconsLocal = [
      Assets.images.charts.chartsGeneral.path,
      Assets.images.charts.chartsWeekly.path,
      Assets.images.charts.chartsDaily.path,
    ];
    return Column(
      spacing: 12,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: SectionHeadingView(title: 'Top Charts'.translate),
        ),
        ValueListenableBuilder(
          valueListenable: controller.topChartsList,
          builder:
              (
                BuildContext buildContext,
                List<MediaCollection> topChartsListArg,
                Widget? nestedEntry,
              ) {
                return LayoutBuilder(
                  builder:
                      (
                        BuildContext buildContext,
                        BoxConstraints constraintsArg,
                      ) {
                        double itemWidthLocal =
                            (constraintsArg.maxWidth - 12 * 2) / 7 * 3;
                        double aspectRatioLocal = 1;
                        return SizedBox(
                          height: itemWidthLocal * aspectRatioLocal,
                          child: GridView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            scrollDirection: Axis.horizontal,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  mainAxisSpacing: 12,
                                  mainAxisExtent: itemWidthLocal,
                                  crossAxisCount: 1,
                                ),
                            itemCount: topChartsListArg.length,
                            itemBuilder:
                                (BuildContext buildContext, int itemIndex) {
                                  MediaCollection mediaCollectionLocal =
                                      topChartsListArg[itemIndex];
                                  return GestureDetector(
                                    onTap: () {
                                      CollectionDetailScreenHelper.to(
                                        mediaCollectionArg:
                                            mediaCollectionLocal,
                                      );
                                    },
                                    child: Container(
                                      alignment: Alignment.bottomCenter,
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: AssetImage(
                                            iconsLocal[itemIndex],
                                          ),
                                          fit: BoxFit.fill,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        clipBehavior: Clip.hardEdge,
                                        borderRadius: BorderRadius.only(
                                          bottomLeft: Radius.circular(6),
                                          bottomRight: Radius.circular(6),
                                        ),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(
                                            sigmaX: 3,
                                            sigmaY: 3,
                                          ),
                                          child: Container(
                                            height: 56,
                                            color: Colors.black.withAlpha(
                                              (255 * 0.15).round(),
                                            ),
                                            padding: EdgeInsets.all(6),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    spacing: 4,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        mediaCollectionLocal
                                                            .name,
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      if (mediaCollectionLocal
                                                              .detail !=
                                                          null)
                                                        Text(
                                                          mediaCollectionLocal
                                                              .detail!,
                                                          style: TextStyle(
                                                            fontSize: 9,
                                                            fontWeight:
                                                                FontWeight.w400,
                                                            color: Colors.white
                                                                .withAlpha(
                                                                  (255 * 0.5)
                                                                      .round(),
                                                                ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  alignment:
                                                      Alignment.bottomCenter,
                                                  child: Assets
                                                      .images
                                                      .media
                                                      .overlayPlay
                                                      .image(width: 20),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                          ),
                        );
                      },
                );
              },
        ),
      ],
    );
  }
}
