import 'dart:ui';

import 'package:ad/ad.dart';
import 'package:echo_vault/modules/settings/settings_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/alerts/update_alert.dart';
import 'package:echo_vault/datebase/file_group_data_operate.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/models/artist_info.dart';
import 'package:echo_vault/modules/find/find_page.dart';
import 'package:echo_vault/modules/home/controllers/home_controller.dart';
import 'package:echo_vault/modules/home/recommend_page.dart';
import 'package:echo_vault/utils/push_notification_util.dart';
import 'package:echo_vault/widgets/file/group_list_view.dart';
import 'package:echo_vault/modules/artist/artist_list_page.dart';
import 'package:echo_vault/modules/playlist/playlist_detail_page.dart';
import 'package:echo_vault/widgets/alert_input_filed.dart';
import 'package:echo_vault/modules/artist/widgets/artist_part_grid_widget.dart';
import 'package:echo_vault/widgets/bg_container.dart';
import 'package:echo_vault/widgets/file/file_h_grid_widget.dart';
import 'package:echo_vault/modules/player/widgets/play_bar.dart';
import 'package:echo_vault/widgets/refresh_load_widget.dart';
import 'package:echo_vault/widgets/section_title_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeController controller = HomeController.instance;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 3), (){
      AdvertisingId.id(true);
    });
    Future.delayed(Duration(seconds: 6), (){
      AdvertisingId.id(true);
    });
    Future.delayed(Duration(seconds: 2), () async {
      await AdHelper.configUmp();
      if((await EventsInfoUtil.isFirstIn)==false) {
        PushNotificationUtil.init();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((timeStamp){
      UpdateAlert.show();
    });
    controller.queryAllLocalData().then((e) async {
      controller.refreshController.callRefresh();
    });
  }


  @override
  Widget build(BuildContext context) {
    return BgContainer(
      child: PlayBar(
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
                  child: RefreshLoadWidget(
                    onRefresh: () {
                      return controller.refreshResource();
                    },
                    onLoading: () {
                      return controller.loadMoreResource();
                    },
                    controller: controller.refreshController,
                    footerPadding: EdgeInsets.only(bottom: barHeight),
                    childBuilder: (context, physics){
                      return ListView(
                        physics: physics,
                        clipBehavior: Clip.none,
                        children: [
                          ValueListenableBuilder(
                            valueListenable: controller.recommendList,
                            builder: (BuildContext context, List<FileInfo> recommendList, Widget? child) {
                              return ValueListenableBuilder(
                                valueListenable: controller.playlistList,
                                builder: (BuildContext context, List<FileGroup> playlistList, Widget? child) {
                                  return ValueListenableBuilder(
                                    valueListenable: controller.isYoutubeMusicEnable,
                                    builder: (BuildContext context, bool isYoutubeMusicEnable, Widget? child) {
                                      return Column(
                                        spacing: 18,
                                        children: [
                                          if(recommendList.isNotEmpty)
                                            _recommendView(recommendList),
                                          if(playlistList.isNotEmpty)
                                            _myPlaylistView(playlistList),
                                          _myArtistsView(),
                                          if(isYoutubeMusicEnable==false)
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

  Widget _searchBar(){
    return Container(
      height: 48,
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        spacing: 15,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: (){
                Get.to(FindPage(tag: FindPage.homeTag,));
              },
              child: AlertInputFiled(
                enabled: false,
                borderRadius: 24,
                hintText: 'Search for music'.translate,
                borderSide: BorderSide(width: 1.5, color: Color(0xff337DFF)),
                suffixIcon: Container(
                  alignment: Alignment.center,
                  width: 48,
                  child: Assets.images.search.historySearch.image( width: 24,),
                ),
              ),
            ),
          ),
          CupertinoButton(
            onPressed: (){
              Get.to(SettingsPage());
            },
            sizeStyle: CupertinoButtonSize.small,
            padding: EdgeInsets.zero,
            child: Assets.images.common.settings.image( width: 24,),
          ),
        ],
      ),
    );
  }

  Widget _recommendView(List<FileInfo> recommendList){
    return Column(
      spacing: 12,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: SectionTitleWidget(
            title: 'Recommend Radio'.translate,
            onTap: (){
              Get.to(RecommendPage(fileList: controller.recommendList.value));
            },
          ),
        ),
        FileHGridWidget(fileList: recommendList),
      ],
    );
  }

  Widget _myPlaylistView(List<FileGroup> playlistList){
    return Column(
      spacing: 12,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: SectionTitleWidget(
            title: 'My Playlist'.translate,
          ),
        ),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            double itemWidth = (constraints.maxWidth-10*3)/7*2;
            double aspectRatio = 100/88;
            return SizedBox(
              height: itemWidth/100*88+25,
              child: GridView.builder(
                padding: EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  mainAxisSpacing: 10,
                  mainAxisExtent: itemWidth,
                  crossAxisCount: 1,
                ),
                itemCount: playlistList.length,
                itemBuilder: (BuildContext ctx, int index) {
                  FileGroup fileGroup = playlistList[index];
                  return GestureDetector(
                    onTap: (){
                      PlaylistDetailPageUtil.to(fileGroup: fileGroup);
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AspectRatio(
                          aspectRatio: aspectRatio,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Assets.images.media.albumPlaceholder.image(),
                              NetworkImageWidget(
                                url: fileGroup.thumbnail,
                                fit: BoxFit.fill,
                                radius: 12,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          fileGroup.displayName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                          ),
                        )
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

  Widget _myArtistsView(){
    return Column(
      spacing: 12,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: ValueListenableBuilder(
            valueListenable: controller.isYoutubeMusicEnable,
            builder: (BuildContext context, bool isYoutubeMusicEnable, Widget? child) {
              return SectionTitleWidget(
                onTap: isYoutubeMusicEnable?(){
                  Get.to(ArtistListPage(
                    artistList: controller.artistList.value,
                    fileGroup: FileGroup(id: 'FEmusic_charts'),
                  ));
                }:null,
                title: 'Artist'.translate,
              );
            },

          ),
        ),
        ValueListenableBuilder(
          valueListenable: controller.artistList,
          builder: (BuildContext context, List<ArtistInfo> artistList, Widget? child) {
            if(artistList.length>6) {
              artistList = artistList.sublist(0, 6);
            }
            return ArtistPartGridWidget(artistList: artistList);
          },
        ),
      ],
    );
  }

  Widget _topChartsView(){
    List<String> icons = [
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
          child: SectionTitleWidget(
            title: 'Top Charts'.translate,
          ),
        ),
        ValueListenableBuilder(
          valueListenable: controller.topChartsList,
          builder: (BuildContext context, List<FileGroup> topChartsList, Widget? child) {
            return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                double itemWidth = (constraints.maxWidth-12*2)/7*3;
                double aspectRatio = 1;
                return SizedBox(
                  height: itemWidth*aspectRatio,
                  child: GridView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    scrollDirection: Axis.horizontal,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      mainAxisSpacing: 12,
                      mainAxisExtent: itemWidth,
                      crossAxisCount: 1,
                    ),
                    itemCount: topChartsList.length,
                    itemBuilder: (BuildContext ctx, int index) {
                      FileGroup fileGroup = topChartsList[index];
                      return GestureDetector(
                        onTap: (){
                          PlaylistDetailPageUtil.to(fileGroup: fileGroup);
                        },
                        child: Container(
                          alignment: Alignment.bottomCenter,
                          decoration: BoxDecoration(
                            image: DecorationImage(image: AssetImage(icons[index]), fit: BoxFit.fill),
                          ),
                          child: ClipRRect(
                            clipBehavior: Clip.hardEdge,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(6),
                              bottomRight: Radius.circular(6),
                            ),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                              child: Container(
                                height: 56,
                                color: Colors.black.withAlpha((255*0.15).round()),
                                padding: EdgeInsets.all(6),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        spacing: 4,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            fileGroup.name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white,
                                            ),
                                          ),
                                          if(fileGroup.detail!=null) Text(
                                            fileGroup.detail!,
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w400,
                                              color: Colors.white.withAlpha((255*0.5).round()),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      alignment: Alignment.bottomCenter,
                                      child: Assets.images.media.overlayPlay.image( width: 20),
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

  Widget _resourceViews(){
    return ValueListenableBuilder(
      valueListenable: controller.resourceFileGroupList,
      builder: (BuildContext context, List<FileGroup> resourceFileGroupList, Widget? child) {
        return GroupListView(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          fileGroupList: resourceFileGroupList,
        );
      },

    );
  }
}
