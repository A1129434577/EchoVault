import 'package:flutter/material.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/core/monetization/advertising_coordinator.dart';
import 'package:echo_vault/shared/dialogs/new_collection_dialog.dart';
import 'package:echo_vault/core/persistence/media_collection_repository.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/core/models/performer_details.dart';
import 'package:echo_vault/features/performers/performer_list_screen.dart';
import 'package:echo_vault/features/catalog/controllers/catalog_state.dart';
import 'package:echo_vault/features/collections/collection_detail_screen.dart';
import 'package:echo_vault/features/collections/widgets/collection_list_cell.dart';
import 'package:echo_vault/shared/widgets/background_surface.dart';
import 'package:echo_vault/features/playback/widgets/playback_bar.dart';
import 'package:echo_vault/shared/widgets/section_heading_view.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final CatalogState _libraryController = CatalogState();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundSurface(
      child: Scaffold(
        appBar: AppBar(
          leadingWidth: 100,
          leading: Padding(
            padding: EdgeInsetsGeometry.only(left: 16),
            child: SectionHeadingView(title: 'Library'),
          ),
        ),
        body: PlaybackBar(
          builder: (BuildContext context, double barHeight) {
            return Padding(
              padding: EdgeInsetsGeometry.symmetric(horizontal: 16),
              child: ValueListenableBuilder(
                valueListenable: _libraryController.libraryNatoAd,
                builder: (BuildContext context, AdInfo? adInfo, Widget? child) {
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        _topViews(),
                        SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: SectionHeadingView(
                                title: 'Playlist'.translate,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                NewCollectionDialog.show();
                              },
                              child: Container(
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Color(0xffD2E7FF),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Row(
                                  spacing: 3,
                                  children: [
                                    Assets.images.collection.listAdd.image(
                                      height: 12,
                                    ),
                                    Text(
                                      'New list'.translate,
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (adInfo?.ad != null || adInfo?.adView != null)
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            alignment: Alignment.center,
                            child: AspectRatio(
                              aspectRatio: 300 / 250,
                              child: NativePartAdView(
                                adInfo: adInfo!,
                                onCloseButtonClick: () {
                                  _libraryController.libraryNatoAd.value = null;
                                  AdHelper.loadSceneAdIfNull(
                                    scene: AdvertisingScene.libraryNative,
                                    detailScene: AdvertisingDetailScene.library,
                                  );
                                },
                              ),
                            ),
                          ),
                        _playlistListView(barHeight),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _playlistListView(double barHeightArg) {
    return ValueListenableBuilder(
      valueListenable: _libraryController.mediaCollections,
      builder:
          (
            BuildContext buildContext,
            List<MediaCollection> musicGroupListArg,
            Widget? nestedEntry,
          ) {
            return ListView.separated(
              shrinkWrap: true,
              itemCount: musicGroupListArg.length,
              physics: NeverScrollableScrollPhysics(),
              padding: EdgeInsetsGeometry.only(bottom: barHeightArg),
              separatorBuilder: (buildContext, itemIndex) {
                return SizedBox(height: 24);
              },
              itemBuilder: (buildContext, itemIndex) {
                MediaCollection musicCollectionLocal =
                    musicGroupListArg[itemIndex];
                return CollectionListCell(
                  mediaCollection: musicCollectionLocal,
                  showMoreAction:
                      musicCollectionLocal.id?.startsWith(
                        NewCollectionDialog.createPlaylistNamePrefix,
                      ) ==
                      true,
                );
              },
            );
          },
    );
  }

  Future _fetchData() async {
    await _libraryController.fetchSavedList();
    await _libraryController.fetchLikedList();
    await _libraryController.fetchArtistList();
    await _libraryController.fetchMusicGroupList();
  }

  Widget _topViews() {
    return LayoutBuilder(
      builder: (BuildContext buildContext, BoxConstraints constraintsArg) {
        double widthLocal = constraintsArg.maxWidth * 3 / 7;
        return Row(
          spacing: 12,
          children: [
            ValueListenableBuilder(
              valueListenable: _libraryController.savedList,
              builder:
                  (
                    BuildContext buildContext,
                    List<FileInfo> savedListArg,
                    Widget? nestedEntry,
                  ) {
                    return SizedBox(
                      width: widthLocal,
                      child: AspectRatio(
                        aspectRatio: 156 / 172,
                        child: GestureDetector(
                          onTap: () async {
                            _libraryController.isSavedNewly = false;
                            _libraryController.fetchSavedList();
                            MediaCollection savedMusicGroupLocal =
                                MediaCollection(
                                  name: 'Offline Songs'.translate,
                                  thumbnail:
                                      Assets.images.media.albumPlaceholder.path,
                                  children: savedListArg,
                                );
                            CollectionDetailScreenHelper.to(
                              mediaCollectionArg: savedMusicGroupLocal,
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: EdgeInsets.only(left: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Flexible(
                                  flex: 1,
                                  child: Container(
                                    alignment: Alignment.centerRight,
                                    padding: EdgeInsets.only(top: 8, right: 10),
                                    child: _libraryController.isSavedNewly
                                        ? Container(
                                            height: 8,
                                            width: 8,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xffFF2929),
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: 0.75,
                                  child: AspectRatio(
                                    aspectRatio: 88 / 78,
                                    child: savedListArg.isEmpty
                                        ? Assets.images.collection.listSaved
                                              .image()
                                        : Container(
                                            padding: EdgeInsets.only(right: 10),
                                            decoration: BoxDecoration(
                                              color: Color(0xffD8E2F1),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            child: NetworkImageWidget(
                                              url: savedListArg.first.thumbnail,
                                              radius: 14,
                                            ),
                                          ),
                                  ),
                                ),
                                SizedBox(height: 12),
                                Row(
                                  children: [
                                    Text(
                                      'Offline'.translate,
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '${savedListArg.length}',
                                        textAlign: TextAlign.end,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(
                                            0xff141414,
                                          ).withAlpha((255 * 0.5).round()),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                  ],
                                ),
                                Flexible(flex: 1, child: SizedBox()),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
            ),
            Expanded(
              child: SizedBox(
                height: widthLocal / 156 * 172,
                child: Column(
                  spacing: 12,
                  children: [
                    Expanded(
                      child: ValueListenableBuilder(
                        valueListenable: _libraryController.likedList,
                        builder:
                            (
                              BuildContext buildContext,
                              List<FileInfo> likedListArg,
                              Widget? nestedEntry,
                            ) {
                              return GestureDetector(
                                onTap: () {
                                  _libraryController.isLikedNewly = false;
                                  _libraryController.fetchLikedList();
                                  MediaCollection lickFileGroupLocal =
                                      MediaCollection(
                                        name: 'Favorite Songs'.translate,
                                        thumbnail: Assets
                                            .images
                                            .media
                                            .albumPlaceholder
                                            .path,
                                        children: likedListArg,
                                      );
                                  CollectionDetailScreenHelper.to(
                                    mediaCollectionArg: lickFileGroupLocal,
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: EdgeInsets.only(
                                    left: 12,
                                    bottom: 20,
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        height: 20,
                                        alignment: Alignment.centerRight,
                                        padding: EdgeInsets.only(
                                          top: 8,
                                          right: 8,
                                        ),
                                        child: _libraryController.isLikedNewly
                                            ? Container(
                                                height: 8,
                                                width: 8,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Color(0xffFF2929),
                                                ),
                                              )
                                            : null,
                                      ),
                                      Expanded(
                                        child: Row(
                                          spacing: 10,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            AspectRatio(
                                              aspectRatio: 50 / 42,
                                              child: likedListArg.isEmpty
                                                  ? Assets
                                                        .images
                                                        .collection
                                                        .listFavorite
                                                        .image()
                                                  : Container(
                                                      padding: EdgeInsets.only(
                                                        right: 8,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Color(
                                                          0xffD8E2F1,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: NetworkImageWidget(
                                                        url: likedListArg
                                                            .first
                                                            .thumbnail,
                                                        radius: 8,
                                                      ),
                                                    ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                'Like'.translate,
                                                style: TextStyle(fontSize: 14),
                                              ),
                                            ),
                                            Text(
                                              '${likedListArg.length}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xff141414)
                                                    .withAlpha(
                                                      (255 * 0.5).round(),
                                                    ),
                                              ),
                                            ),
                                            SizedBox(width: 2),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                      ),
                    ),
                    Expanded(
                      child: ValueListenableBuilder(
                        valueListenable: _libraryController.performers,
                        builder:
                            (
                              BuildContext buildContext,
                              List<PerformerDetails> performersArg,
                              Widget? nestedEntry,
                            ) {
                              return GestureDetector(
                                onTap: () {
                                  _libraryController.isArtistNewly = false;
                                  _libraryController.fetchArtistList();
                                  Get.to(
                                    PerformerListScreen(
                                      performers: performersArg,
                                    ),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: EdgeInsets.only(
                                    left: 12,
                                    bottom: 20,
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        height: 20,
                                        alignment: Alignment.centerRight,
                                        padding: EdgeInsets.only(
                                          top: 8,
                                          right: 8,
                                        ),
                                        child: _libraryController.isArtistNewly
                                            ? Container(
                                                height: 8,
                                                width: 8,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Color(0xffFF2929),
                                                ),
                                              )
                                            : null,
                                      ),
                                      Expanded(
                                        child: Row(
                                          spacing: 10,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Assets.images.collection.listArtist
                                                .image(),
                                            Expanded(
                                              child: Text(
                                                'Artist'.translate,
                                                style: TextStyle(fontSize: 14),
                                              ),
                                            ),
                                            Text(
                                              '${performersArg.length}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xff141414)
                                                    .withAlpha(
                                                      (255 * 0.5).round(),
                                                    ),
                                              ),
                                            ),
                                            SizedBox(width: 2),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
