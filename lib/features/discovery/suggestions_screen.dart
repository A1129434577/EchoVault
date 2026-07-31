import 'package:flutter/material.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/features/playback/widgets/playback_bar.dart';
import 'package:echo_vault/shared/widgets/navigation_bar_views.dart';
import 'package:echo_vault/shared/widgets/background_surface.dart';
import 'package:echo_vault/shared/widgets/media/adaptive_list_view.dart';

class SuggestionsScreen extends StatelessWidget {
  final List<FileInfo> fileList;
  const SuggestionsScreen({super.key, this.fileList = const []});

  @override
  Widget build(BuildContext context) {
    return BackgroundSurface(
      child: PlaybackBar(
        builder: (BuildContext context, double barHeight) {
          return Scaffold(
            appBar: AppBar(
              leading: AppBlackBackButton(),
              title: Text('Recommend Radio'.translate),
            ),
            body: AdaptiveListView(
              padding: EdgeInsets.only(bottom: barHeight),
              records: fileList,
            ),
          );
        },
      ),
    );
  }
}
