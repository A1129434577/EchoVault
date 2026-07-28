import 'package:flutter/material.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/modules/player/widgets/play_bar.dart';
import 'package:echo_vault/widgets/app_bar_widgets.dart';
import 'package:echo_vault/widgets/bg_container.dart';
import 'package:echo_vault/widgets/file/dynamic_list_view.dart';

class RecommendPage extends StatelessWidget {
  final List<FileInfo> fileList;
  const RecommendPage({
    super.key,
    this.fileList = const [],
  });

  @override
  Widget build(BuildContext context) {
    return BgContainer(
      child: PlayBar(
        builder: (BuildContext context, double barHeight) {
          return Scaffold(
            appBar: AppBar(
              leading: AppBlackBackButton(),
              title: Text('Recommend Radio'.translate),
            ),
            body: DynamicListView(
              padding: EdgeInsets.only(bottom: barHeight),
              dataList: fileList,
            ),
          );
        },
      ),
    );
  }
}
