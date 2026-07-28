import 'package:flutter/material.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/ads/ads_manager.dart';
import 'package:echo_vault/alerts/create_playlist_alert.dart';
import 'package:echo_vault/datebase/file_group_data_operate.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/models/artist_info.dart';
import 'package:echo_vault/modules/artist/artist_list_page.dart';
import 'package:echo_vault/modules/library/controllers/library_controller.dart';
import 'package:echo_vault/modules/playlist/playlist_detail_page.dart';
import 'package:echo_vault/modules/playlist/widgets/playlist_list_cell.dart';
import 'package:echo_vault/widgets/bg_container.dart';
import 'package:echo_vault/modules/player/widgets/play_bar.dart';
import 'package:echo_vault/widgets/section_title_widget.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final LibraryController _libraryController = LibraryController();

  @override
  void initState() {
    super.initState();
    _queryData();
  }

  Future _queryData() async {
    await _libraryController.querySavedList();
    await _libraryController.queryLikedList();
    await _libraryController.queryArtistList();
    await _libraryController.queryMusicGroupList();
  }

  @override
  Widget build(BuildContext context) {
    return BgContainer(
      child: Scaffold(
        appBar: AppBar(
          leadingWidth: 100,
          leading: Padding(
            padding: EdgeInsetsGeometry.only(left: 16),
            child:  SectionTitleWidget(title: 'Library'),
          ),
        ),
        body: PlayBar(
          builder: (BuildContext context, double barHeight){
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
                            Expanded(child: SectionTitleWidget(title: 'Playlist'.translate)),
                            GestureDetector(
                              onTap: (){
                                CreatePlaylistAlert.show();
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
                                    Image.asset(Assets.otherLAdd, height: 12),
                                    Text(
                                      'New list'.translate,
                                      style: TextStyle(
                                        fontSize: 10,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if(adInfo?.ad != null || adInfo?.adView != null)Container(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          child: AspectRatio(
                            aspectRatio: 300/250,
                            child: NativePartAdView(
                              adInfo: adInfo!,
                              onCloseButtonClick: (){
                                _libraryController.libraryNatoAd.value = null;
                                AdHelper.loadSceneAdIfNull(scene: AdsManagerScene.libraryNative, detailScene: AdsManagerDetailScene.library);
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

  Widget _topViews(){
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double width = constraints.maxWidth*3/7;
        return Row(
          spacing: 12,
          children: [
            ValueListenableBuilder(
              valueListenable: _libraryController.savedList,
              builder: (BuildContext context, List<FileInfo> savedList, Widget? child) {
                return SizedBox(
                  width: width,
                  child: AspectRatio(
                    aspectRatio: 156/172,
                    child: GestureDetector(
                      onTap: () async {
                        _libraryController.isSavedNewly = false;
                        _libraryController.querySavedList();
                        FileGroup savedMusicGroup = FileGroup(
                          name: 'Offline Songs'.translate,
                          thumbnail: Assets.otherAlbumCover,
                          children: savedList,
                        );
                        PlaylistDetailPageUtil.to(fileGroup: savedMusicGroup);
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
                                child: _libraryController.isSavedNewly?Container(
                                  height: 8,
                                  width: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xffFF2929),
                                  ),
                                ):null,
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: 0.75,
                              child: AspectRatio(
                                aspectRatio: 88/78,
                                child: savedList.isEmpty?
                                Image.asset(Assets.otherLSaved):
                                Container(
                                  padding: EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    color: Color(0xffD8E2F1),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: NetworkImageWidget(
                                    url: savedList.first.thumbnail,
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
                                  style: TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${savedList.length}',
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xff141414).withAlpha((255*0.5).round()),
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
                height: width/156*172,
                child: Column(
                  spacing: 12,
                  children: [
                    Expanded(
                      child: ValueListenableBuilder(
                        valueListenable: _libraryController.likedList,
                        builder: (BuildContext context, List<FileInfo> likedList, Widget? child) {
                          return GestureDetector(
                            onTap: (){
                              _libraryController.isLikedNewly = false;
                              _libraryController.queryLikedList();
                              FileGroup lickFileGroup = FileGroup(
                                name: 'Favorite Songs'.translate,
                                thumbnail: Assets.otherAlbumCover,
                                children: likedList,
                              );
                              PlaylistDetailPageUtil.to(fileGroup: lickFileGroup);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: EdgeInsets.only(left: 12, bottom: 20),
                              child: Column(
                                children: [
                                  Container(
                                    height: 20,
                                    alignment: Alignment.centerRight,
                                    padding: EdgeInsets.only(top: 8, right: 8),
                                    child: _libraryController.isLikedNewly?Container(
                                      height: 8,
                                      width: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xffFF2929),
                                      ),
                                    ):null,
                                  ),
                                  Expanded(
                                    child: Row(
                                      spacing: 10,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        AspectRatio(
                                          aspectRatio: 50/42,
                                          child: likedList.isEmpty?
                                          Image.asset(Assets.otherLLike):
                                          Container(
                                            padding: EdgeInsets.only(right: 8),
                                            decoration: BoxDecoration(
                                              color: Color(0xffD8E2F1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: NetworkImageWidget(
                                              url: likedList.first.thumbnail,
                                              radius: 8,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            'Like'.translate,
                                            style: TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${likedList.length}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xff141414).withAlpha((255*0.5).round()),
                                          ),
                                        ),
                                        SizedBox(width: 2),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: ValueListenableBuilder(
                        valueListenable: _libraryController.artistList,
                        builder: (BuildContext context, List<ArtistInfo> artistList, Widget? child) {
                          return GestureDetector(
                            onTap: (){
                              _libraryController.isArtistNewly = false;
                              _libraryController.queryArtistList();
                              Get.to(ArtistListPage(artistList: artistList));
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: EdgeInsets.only(left: 12, bottom: 20),
                              child: Column(
                                children: [
                                  Container(
                                    height: 20,
                                    alignment: Alignment.centerRight,
                                    padding: EdgeInsets.only(top: 8, right: 8),
                                    child: _libraryController.isArtistNewly?Container(
                                      height: 8,
                                      width: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xffFF2929),
                                      ),
                                    ):null,
                                  ),
                                  Expanded(
                                    child: Row(
                                      spacing: 10,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.asset(Assets.otherLArtist),
                                        Expanded(
                                          child: Text(
                                            'Artist'.translate,
                                            style: TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${artistList.length}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xff141414).withAlpha((255*0.5).round()),
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
            )
          ],
        );
      },
    );
  }

  Widget _playlistListView(double barHeight){
    return ValueListenableBuilder(
      valueListenable: _libraryController.fileGroupList,
      builder: (BuildContext context, List<FileGroup> musicGroupList, Widget? child) {
        return ListView.separated(
          shrinkWrap: true,
          itemCount: musicGroupList.length,
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsetsGeometry.only(bottom: barHeight),
          separatorBuilder:(context, index){
            return SizedBox(height: 24);
          },
          itemBuilder: (context, index){
            FileGroup musicGroup = musicGroupList[index];
            return PlaylistListCell(
              fileGroup: musicGroup,
              showMoreAction: musicGroup.id?.startsWith(CreatePlaylistAlert.createPlaylistNamePrefix)==true,
            );
          },
        );
      },

    );
  }
}
