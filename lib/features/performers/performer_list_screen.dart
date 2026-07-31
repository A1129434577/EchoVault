import 'package:flutter/material.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/core/persistence/media_collection_repository.dart';
import 'package:echo_vault/core/models/performer_details.dart';
import 'package:echo_vault/features/performers/controllers/performer_list_state.dart';
import 'package:echo_vault/features/playback/widgets/playback_bar.dart';
import 'package:echo_vault/shared/widgets/navigation_bar_views.dart';
import 'package:echo_vault/features/performers/widgets/performer_list_cell.dart';
import 'package:echo_vault/shared/widgets/background_surface.dart';
import 'package:echo_vault/shared/widgets/empty_state_view.dart';
import 'package:echo_vault/shared/widgets/paged_refresh_view.dart';

class PerformerListScreen extends StatefulWidget {
  final List<PerformerDetails> performers;
  final MediaCollection? mediaCollection;
  const PerformerListScreen({
    super.key,
    required this.performers,
    this.mediaCollection,
  });

  @override
  State<PerformerListScreen> createState() => _PerformerListScreenState();
}

class _PerformerListScreenState extends State<PerformerListScreen> {
  late final List<PerformerDetails> performers = widget.performers;
  late final PerformerListState controller = PerformerListState(
    mediaCollection: widget.mediaCollection,
    performers: performers,
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
    return BackgroundSurface(
      child: PlaybackBar(
        builder: (BuildContext context, double barHeight) {
          return Scaffold(
            appBar: AppBar(
              leading: AppBlackBackButton(),
              title: Text('Artist'.translate),
            ),
            body: PagedRefreshView(
              refreshOnStart: true,
              onRefresh: controller.mediaCollection?.id != null
                  ? () async {
                      return await controller.queryData();
                    }
                  : null,
              childBuilder: (BuildContext context, ScrollPhysics physics) {
                return ValueListenableBuilder(
                  valueListenable: controller.artistListNotifier,
                  builder:
                      (
                        BuildContext context,
                        List<PerformerDetails> performers,
                        Widget? child,
                      ) {
                        return performers.isNotEmpty
                            ? ListView.separated(
                                physics: physics,
                                padding: EdgeInsets.only(
                                  left: 16,
                                  right: 16,
                                  bottom:
                                      MediaQuery.of(context).padding.bottom +
                                      barHeight,
                                ),
                                itemCount: performers.length,
                                separatorBuilder: (context, index) {
                                  return SizedBox(height: 18);
                                },
                                itemBuilder: (context, index) {
                                  PerformerDetails artist = performers[index];
                                  return SizedBox(
                                    height: 68,
                                    child: PerformerListCell(
                                      performerDetails: artist,
                                    ),
                                  );
                                },
                              )
                            : EmptyStateView();
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
