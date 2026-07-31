import 'dart:math';

import 'package:flutter/material.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/alerts/create_playlist_alert.dart';
import 'package:echo_vault/datebase/file_group_data_operate.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/modules/player/widgets/play_bar.dart';
import 'package:echo_vault/widgets/base_status_widget.dart';
import 'package:echo_vault/widgets/file/group_list_view.dart';
import 'package:echo_vault/modules/player/player_page.dart';
import 'package:echo_vault/modules/playlist/controllers/playlist_detail_controller.dart';
import 'package:echo_vault/widgets/app_bar_widgets.dart';
import 'package:echo_vault/widgets/bg_container.dart';
import 'package:echo_vault/widgets/common_button.dart';
import 'package:echo_vault/modules/playlist/widgets/favorite_group_widget.dart';
import 'package:echo_vault/widgets/refresh_load_widget.dart';

class PlaylistDetailPageUtil {
  static String routeName = '/$_PlaylistDetailPage';
  static to({required FileGroup fileGroup}){
    Get.to(
      arguments: fileGroup,
      preventDuplicates: false,
      _PlaylistDetailPage(fileGroup: fileGroup),
    );
  }
}

class _PlaylistDetailPage extends StatefulWidget {
  final FileGroup fileGroup;
  const _PlaylistDetailPage({
    super.key,
    required this.fileGroup,
  });

  @override
  State<_PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<_PlaylistDetailPage> {
  late final FileGroup fileGroup = widget.fileGroup;
  late final PlaylistDetailController controller = PlaylistDetailController(fileGroup: fileGroup);

  final ScrollController _scrollController = ScrollController();
  late final bool _isSelfBuiltPlaylist = fileGroup.id == null || fileGroup.id?.startsWith(CreatePlaylistAlert.createPlaylistNamePrefix)==true;
  final ValueNotifier<bool> _isHeaderClosed = ValueNotifier(false);
  late VoidCallback _scrollControllerListener;

  @override
  void initState() {
    super.initState();
    _scrollControllerListener = (){
      _isHeaderClosed.value = (_scrollController.offset >= 120);
    };
    _scrollController.addListener(_scrollControllerListener);

    if(_isSelfBuiltPlaylist) {
      controller.resourceList.value = [fileGroup];
    }

    if(!_isSelfBuiltPlaylist) {
      controller.queryData();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollControllerListener);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BgContainer(
      child: PlayBar(
        builder: (BuildContext context, double barHeight) {
          return Scaffold(
            appBar: AppBar(
              leading: AppBlackBackButton(),
              title: ValueListenableBuilder(
                valueListenable: _isHeaderClosed,
                builder: (BuildContext context, bool isHeaderClosed, Widget? child) {
                  return Visibility(
                    visible: isHeaderClosed,
                    child: Text(fileGroup.displayName),
                  );
                },
              ),
              actionsPadding: EdgeInsets.only(right: 16),
              actions: [
                if(_isSelfBuiltPlaylist==false)
                  SizedBox(
                    width: 24,
                    child: FavoriteGroupWidget(fileGroup: fileGroup),
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
                        padding: EdgeInsets.only(left: 12, right: 12, bottom: 22),
                        child: Row(
                          spacing: 16,
                          children: [
                            AspectRatio(
                              aspectRatio: (128+8)/128,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    top: 8,
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: Color(0xffD8E2F1),
                                          borderRadius: BorderRadius.circular(8)
                                      ),
                                    ),
                                  ),
                                  AspectRatio(
                                    aspectRatio: 1,
                                    child: NetworkImageWidget(
                                      radius: 8,
                                      url: fileGroup.thumbnail,
                                      fit: BoxFit.fill,
                                      defaultView: Assets.other.albumPlaceholder.image( fit: BoxFit.fill),
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
                                    fileGroup.displayName,
                                    maxLines: 2,
                                    textAlign: TextAlign.start,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                  ValueListenableBuilder(
                                    valueListenable: controller.resourceList,
                                    builder: (BuildContext context, List<FileGroup>? resourceList, Widget? child) {
                                      return Text(
                                        '${fileGroup.children.isNotEmpty?fileGroup.children.length:''} Songs${fileGroup.detail!=null?' • ${fileGroup.detail}':''}',
                                        textAlign: TextAlign.start,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          color: Color(0xff121212).withAlpha((255*0.75).round()),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  )
                ];
              },
              body: Column(
                children: [
                  _actionsView(),
                  SizedBox(height: 22),
                  Expanded(
                    child: _fileListView(barHeight),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _actionsView(){
    return ValueListenableBuilder(
      valueListenable: controller.resourceList,
      builder: (BuildContext context, List<FileGroup>? value, Widget? child) {
        if(fileGroup.children.isEmpty){
          return SizedBox();
        }
        return Container(
          height: 48,
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            spacing: 20,
            children: [
              Expanded(
                child: CommonButton(
                  onPressed: (){
                    if(fileGroup.children.isNotEmpty) {
                      PlayHelper.toPlay(
                        fileList: fileGroup.children.cast(),
                        playMode: PlayerPlayMode.loop,
                      );
                    }
                  },
                  fontSize: 16,
                  icon: Assets.other.playlistPlay.image(),
                  title: 'Play'.translate,
                ),
              ),
              Expanded(
                child: CommonButton(
                  onPressed:(){
                    if(fileGroup.children.isNotEmpty) {
                      List<FileInfo> list = fileGroup.children.cast();
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
                  icon: Assets.other.playlistShuffle.image(),
                  title: 'Shuffle'.translate,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _fileListView(double barHeight){
    return RefreshLoadWidget(
      onRefresh: _isSelfBuiltPlaylist?null:() {
        return controller.queryData();
      },
      // onLoading: fileGroup.playlistType==PlaylistType.LOCKUP_CONTENT_TYPE_PLAYLIST.name||
      //     fileGroup.playlistType==PlaylistType.LOCKUP_CONTENT_TYPE_ALBUM.name?() {
      //   return controller.loadMoreYTData();
      // }:null,
      isEmpty: _isSelfBuiltPlaylist && fileGroup.children.isEmpty,
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
    );
  }
}
