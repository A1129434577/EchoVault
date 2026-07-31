import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/datebase/file_group_data_operate.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/models/artist_info.dart';
import 'package:echo_vault/modules/artist/controllers/artist_detail_controller.dart';
import 'package:echo_vault/modules/artist/widgets/favorite_artist_widget.dart';
import 'package:echo_vault/modules/player/player_page.dart';
import 'package:echo_vault/modules/player/widgets/play_bar.dart';
import 'package:echo_vault/widgets/app_bar_widgets.dart';
import 'package:echo_vault/widgets/base_status_widget.dart';
import 'package:echo_vault/widgets/common_button.dart';
import 'package:echo_vault/widgets/file/group_list_view.dart';
import 'package:echo_vault/widgets/refresh_load_widget.dart';

class ArtistDetailPageUtil{
  static String routeName = '/$_ArtistDetailPage';
  static to({required ArtistInfo artistInfo}){
    Get.to(
      arguments: artistInfo,
      preventDuplicates: false,
      _ArtistDetailPage(artistInfo: artistInfo),
    );
  }
}

class _ArtistDetailPage extends StatefulWidget {
  final ArtistInfo artistInfo;
  const _ArtistDetailPage({
    super.key,
    required this.artistInfo,
  });

  @override
  State<_ArtistDetailPage> createState() => _ArtistDetailPageState();
}

class _ArtistDetailPageState extends State<_ArtistDetailPage> {
  late final ArtistInfo artistInfo = widget.artistInfo;
  late final ArtistDetailController controller = ArtistDetailController(artistInfo: artistInfo);

  final ValueNotifier<bool> _isHeaderClosed = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();
  late VoidCallback _scrollControllerListener;

  @override
  void initState() {
    super.initState();

    _scrollControllerListener = (){
      _isHeaderClosed.value = (_scrollController.offset >= 90);
    };
    _scrollController.addListener(_scrollControllerListener);
    controller.queryData();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollControllerListener);
    controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    double topHeight = 90;
    return Stack(
      children: [
        FractionallySizedBox(
          widthFactor: 1,
          child: SizedBox(
            height: topHeight+kToolbarHeight+MediaQuery.of(context).padding.top+20,
            child: ValueListenableBuilder(
              valueListenable: controller.hdThumbnail,
              builder: (BuildContext context, String hdThumbnail, Widget? child) {
                return NetworkImageWidget(
                  url: hdThumbnail,
                  defaultView: Assets.images.artist.artistBackdrop.image( fit: BoxFit.fill,),
                );
              },
            ),
          )
        ),
        ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Container(),
          ),
        ),
        PlayBar(
          builder: (BuildContext context, double barHeight) {
            return
              Scaffold(
                appBar: AppBar(
                  leading: AppBlackBackButton(icon: Assets.images.artist.navBackLight.path),
                  title: ValueListenableBuilder(
                    valueListenable: _isHeaderClosed,
                    builder: (BuildContext context, bool isHeaderClosed, Widget? child) {
                      return Visibility(
                        visible: isHeaderClosed,
                        child: Text(artistInfo.name, style: TextStyle(color: Colors.white)),
                      );
                    },
                  ),
                  actionsPadding: EdgeInsets.only(right: 16),
                  actions: [
                    SizedBox(
                      width: 24,
                      child: FavoriteArtistWidget(
                        artist: artistInfo,
                        icon: Assets.images.collection.favoriteLight.path,
                      ),
                    ),
                  ],
                ),
                body: NestedScrollView(
                  controller: _scrollController,
                  headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                    return [
                      SliverAppBar(
                        expandedHeight: topHeight,
                        leading: Container(),
                        flexibleSpace: FlexibleSpaceBar(
                          background: Container(
                            padding: EdgeInsets.only(left: 12, right: 12, bottom: 10),
                            child: Row(
                              spacing: 16,
                              children: [
                                SizedBox(
                                  height: 48,
                                  width: 48,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Assets.images.artist.profileAvatar.image(),
                                      Container(
                                        clipBehavior: Clip.hardEdge,
                                        decoration: BoxDecoration(
                                          border: BoxBorder.all(
                                            width: 1.5,
                                            color: Color(0xffB8D2FF),
                                          ),
                                          borderRadius: BorderRadius.circular(24),
                                        ),
                                        child: ValueListenableBuilder(
                                          valueListenable: controller.hdThumbnail,
                                          builder: (BuildContext context, String hdThumbnail, Widget? child) {
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
                                    artistInfo.name,
                                    maxLines: 2,
                                    textAlign: TextAlign.start,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 22,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      )
                    ];
                  },
                  body:ValueListenableBuilder(
                    valueListenable: _isHeaderClosed,
                    builder: (BuildContext context, bool isHeaderClosed, Widget? child) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(isHeaderClosed?0:20),
                            topRight: Radius.circular(isHeaderClosed?0:20),
                          ),
                        ),
                        child: Column(
                          children: [
                            SizedBox(height: 24),
                            _actionsView(),
                            SizedBox(height: 24),
                            Expanded(
                              child: RefreshLoadWidget(
                                onRefresh: () async {
                                  await controller.queryData();
                                },
                                controller: controller.refreshController,
                                childBuilder: (context, physics){
                                  return ValueListenableBuilder(
                                    valueListenable: controller.state,
                                    builder: (BuildContext context, ResourceStatus state, Widget? child) {
                                      return BaseStatusWidget(
                                        state: controller.resourceList.value?.isNotEmpty==true?ResourceStatus.source:state,
                                        action: (){
                                          controller.queryData();
                                        },
                                        child: GroupListView(
                                          physics: physics,
                                          padding: EdgeInsets.only(bottom: barHeight),
                                          fileGroupList: controller.resourceList.value??[],
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

  Widget _actionsView(){
    return Container(
      height: 42,
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        spacing: 24,
        children: [
          Expanded(
            child: CommonButton(
              onPressed: (){
                FileGroup? fileGroup = controller.resourceList.value?.where((fileGroup)=>fileGroup.type==FileGroupShowType.listMusic).firstOrNull;
                if(fileGroup?.children.isNotEmpty==true) {
                  PlayHelper.toPlay(
                    fileList: fileGroup!.children.cast(),
                    playMode: PlayerPlayMode.loop,
                  );
                }
              },
              fontSize: 16,
              icon: Assets.images.collection.playlistPlay.image(),
              title: 'Play'.translate,
            ),
          ),
          Expanded(
            child: CommonButton(
              onPressed:(){
                FileGroup? fileGroup = controller.resourceList.value?.where((fileGroup)=>fileGroup.type==FileGroupShowType.listMusic).firstOrNull;
                if(fileGroup?.children.isNotEmpty==true) {
                  List<FileInfo> list = fileGroup!.children.cast();
                  Random random = Random();
                  int randomIndex = random.nextInt(list.length);
                  PlayHelper.toPlay(
                    fileList: list,
                    playMode: PlayerPlayMode.shuffle,
                    fileInfo: list[randomIndex],
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
