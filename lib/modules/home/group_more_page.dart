import 'package:flutter/material.dart';
import 'package:echo_vault/datebase/file_group_data_operate.dart';
import 'package:echo_vault/modules/home/controllers/group_more_controller.dart';
import 'package:echo_vault/modules/player/widgets/play_bar.dart';
import 'package:echo_vault/widgets/file/group_list_view.dart';
import 'package:echo_vault/modules/library/widgets/common_grid_view.dart';
import 'package:echo_vault/widgets/app_bar_widgets.dart';
import 'package:echo_vault/widgets/bg_container.dart';
import 'package:echo_vault/widgets/refresh_load_widget.dart';

class GroupMorePage extends StatefulWidget {
  final FileGroup fileGroup;
  const GroupMorePage({
    super.key,
    required this.fileGroup,
  });

  @override
  State<GroupMorePage> createState() => _GroupMorePageState();
}

class _GroupMorePageState extends State<GroupMorePage> {
  late final GroupMoreController controller = GroupMoreController(fileGroup: widget.fileGroup);

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
              title: Text(controller.fileGroup.name),
            ),
            body: RefreshLoadWidget(
              onRefresh: () async {
                await controller.queryData();
              },
              refreshOnStart: true,
              childBuilder: (context, physics){
                return ValueListenableBuilder(
                  valueListenable: controller.resourceList,
                  builder: (BuildContext context, List<FileGroup> resourceList, Widget? child) {
                    if(resourceList.length==1 && resourceList.first.type==FileGroupShowType.grid){
                      return CommonGridView(
                        physics: physics,
                        padding: EdgeInsets.only(
                          left: 22,
                          right: 22,
                          bottom: MediaQuery.of(context).padding.bottom+barHeight,
                        ),
                        resourceList: resourceList.first.children,
                      );
                    }
                    return GroupListView(
                      physics: physics,
                      padding: EdgeInsets.only(bottom: barHeight),
                      fileGroupList: resourceList,
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
