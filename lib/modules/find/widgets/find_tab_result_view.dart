import 'package:flutter/material.dart';
import 'package:echo_vault/datebase/file_group_data_operate.dart';
import 'package:echo_vault/modules/find/controllers/find_tab_result_controller.dart';
import 'package:echo_vault/widgets/file/dynamic_list_view.dart';
import 'package:echo_vault/widgets/refresh_load_widget.dart';
import 'package:visibility_detector/visibility_detector.dart';

class FindTabResultView extends StatefulWidget {
  final String keyword;
  final FileGroup fileGroup;
  final int index;
  const FindTabResultView({
    super.key,
    required this.keyword,
    required this.fileGroup,
    required this.index,
  });

  @override
  State<FindTabResultView> createState() => _FindTabResultViewState();
}

class _FindTabResultViewState extends State<FindTabResultView> {
  late final FindTabResultController controller = FindTabResultController(
    keyword: widget.keyword,
    fileGroup: widget.fileGroup,
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshLoadWidget(
      onRefresh: () {
        return controller.refreshResource();
      },
      onLoading: () {
        return controller.loadMoreResource();
      },
      controller: controller.refreshController,
      child: VisibilityDetector(
        key: Key('search_tab_index${widget.index}'),
        onVisibilityChanged: (VisibilityInfo info) {
          if(info.visibleFraction == 1){
            if(controller.dataList.value.isEmpty) {
              controller.refreshController.callRefresh();
            }
          }
        },
        child: ValueListenableBuilder(
          valueListenable: controller.dataList,
          builder: (BuildContext context, List<dynamic> dataList, Widget? child) {
            return DynamicListView(
              dataList: dataList,
            );
          },
        ),
      ),
    );
  }
}

