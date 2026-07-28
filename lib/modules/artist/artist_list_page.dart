import 'package:flutter/material.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/datebase/file_group_data_operate.dart';
import 'package:echo_vault/models/artist_info.dart';
import 'package:echo_vault/modules/artist/controllers/artist_list_controller.dart';
import 'package:echo_vault/modules/player/widgets/play_bar.dart';
import 'package:echo_vault/widgets/app_bar_widgets.dart';
import 'package:echo_vault/modules/artist/widgets/artist_list_cell.dart';
import 'package:echo_vault/widgets/bg_container.dart';
import 'package:echo_vault/widgets/empty_widget.dart';
import 'package:echo_vault/widgets/refresh_load_widget.dart';

class ArtistListPage extends StatefulWidget {
  final List<ArtistInfo> artistList;
  final FileGroup? fileGroup;
  const ArtistListPage({
    super.key,
    required this.artistList,
    this.fileGroup,
  });

  @override
  State<ArtistListPage> createState() => _ArtistListPageState();
}

class _ArtistListPageState extends State<ArtistListPage> {
  late final List<ArtistInfo> artistList = widget.artistList;
  late final ArtistListController controller = ArtistListController(
    fileGroup: widget.fileGroup,
    artistList: artistList,
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
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
              title: Text('Artist'.translate),
            ),
            body: RefreshLoadWidget(
              refreshOnStart: true,
              onRefresh: controller.fileGroup?.id!=null? () async {
                return await controller.queryData();
              }:null,
              childBuilder: (BuildContext context, ScrollPhysics physics) {
                return ValueListenableBuilder(
                  valueListenable: controller.artistListNotifier,
                  builder: (BuildContext context, List<ArtistInfo> artistList, Widget? child) {
                    return artistList.isNotEmpty?
                    ListView.separated(
                      physics: physics,
                      padding: EdgeInsets.only(left: 16, right: 16, bottom: MediaQuery.of(context).padding.bottom+barHeight),
                      itemCount: artistList.length,
                      separatorBuilder:(context, index){
                        return SizedBox(height: 18);
                      },
                      itemBuilder: (context, index){
                        ArtistInfo artist = artistList[index];
                        return SizedBox(
                          height: 68,
                          child: ArtistListCell(artistInfo: artist),
                        );
                      },
                    ):
                    EmptyWidget();
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

