import 'package:flutter/material.dart';
import 'package:echo_vault/core/persistence/media_collection_repository.dart';
import 'package:echo_vault/features/search/controllers/search_tab_result_state.dart';
import 'package:echo_vault/shared/widgets/media/adaptive_list_view.dart';
import 'package:echo_vault/shared/widgets/paged_refresh_view.dart';
import 'package:visibility_detector/visibility_detector.dart';

class SearchTabResultView extends StatefulWidget {
  final String keyword;
  final MediaCollection mediaCollection;
  final int index;
  const SearchTabResultView({
    super.key,
    required this.keyword,
    required this.mediaCollection,
    required this.index,
  });

  @override
  State<SearchTabResultView> createState() => _FindTabResultViewState();
}

class _FindTabResultViewState extends State<SearchTabResultView> {
  late final SearchTabResultState controller = SearchTabResultState(
    keyword: widget.keyword,
    mediaCollection: widget.mediaCollection,
  );

  @override
  Widget build(BuildContext context) {
    return PagedRefreshView(
      onRefresh: () {
        return controller.reloadResource();
      },
      onLoading: () {
        return controller.fetchMoreResource();
      },
      controller: controller.refreshController,
      child: VisibilityDetector(
        key: Key('search_tab_index${widget.index}'),
        onVisibilityChanged: (VisibilityInfo info) {
          if (info.visibleFraction == 1) {
            if (controller.records.value.isEmpty) {
              controller.refreshController.callRefresh();
            }
          }
        },
        child: ValueListenableBuilder(
          valueListenable: controller.records,
          builder:
              (BuildContext context, List<dynamic> records, Widget? child) {
                return AdaptiveListView(records: records);
              },
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
