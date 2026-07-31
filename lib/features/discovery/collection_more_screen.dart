import 'package:flutter/material.dart';
import 'package:echo_vault/core/persistence/media_collection_repository.dart';
import 'package:echo_vault/features/discovery/controllers/collection_more_state.dart';
import 'package:echo_vault/features/playback/widgets/playback_bar.dart';
import 'package:echo_vault/shared/widgets/media/collection_list_view.dart';
import 'package:echo_vault/features/catalog/widgets/shared_grid_view.dart';
import 'package:echo_vault/shared/widgets/navigation_bar_views.dart';
import 'package:echo_vault/shared/widgets/background_surface.dart';
import 'package:echo_vault/shared/widgets/paged_refresh_view.dart';

class CollectionMoreScreen extends StatefulWidget {
  final MediaCollection mediaCollection;
  const CollectionMoreScreen({super.key, required this.mediaCollection});

  @override
  State<CollectionMoreScreen> createState() => _CollectionMoreScreenState();
}

class _CollectionMoreScreenState extends State<CollectionMoreScreen> {
  late final CollectionMoreState controller = CollectionMoreState(
    mediaCollection: widget.mediaCollection,
  );

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
              title: Text(controller.mediaCollection.name),
            ),
            body: PagedRefreshView(
              onRefresh: () async {
                await controller.queryData();
              },
              refreshOnStart: true,
              childBuilder: (context, physics) {
                return ValueListenableBuilder(
                  valueListenable: controller.resourceList,
                  builder:
                      (
                        BuildContext context,
                        List<MediaCollection> resourceList,
                        Widget? child,
                      ) {
                        if (resourceList.length == 1 &&
                            resourceList.first.type ==
                                MediaCollectionShowType.grid) {
                          return SharedGridView(
                            physics: physics,
                            padding: EdgeInsets.only(
                              left: 22,
                              right: 22,
                              bottom:
                                  MediaQuery.of(context).padding.bottom +
                                  barHeight,
                            ),
                            resourceList: resourceList.first.children,
                          );
                        }
                        return CollectionListView(
                          physics: physics,
                          padding: EdgeInsets.only(bottom: barHeight),
                          mediaCollections: resourceList,
                        );
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
