import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/datebase/file_group_data_operate.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/modules/find/controllers/find_controller.dart';
import 'package:echo_vault/modules/find/widgets/find_tab_result_view.dart';
import 'package:echo_vault/modules/find/widgets/find_top_result_view.dart';
import 'package:echo_vault/modules/find/widgets/history_keywork_widget.dart';
import 'package:echo_vault/modules/tab_page.dart';
import 'package:echo_vault/widgets/alert_input_filed.dart';
import 'package:echo_vault/widgets/base_status_widget.dart';
import 'package:echo_vault/widgets/bg_container.dart';
import 'package:echo_vault/modules/player/widgets/play_bar.dart';
import 'package:echo_vault/widgets/tab_bar_widget.dart';

class FindPage extends StatefulWidget {
  static const String homeTag = 'home';
  static const String tabTag = 'tab';

  static ValueNotifier<int> currentTabIndex = ValueNotifier(0);

  final String tag;
  const FindPage({
    super.key,
    this.tag = tabTag,
  });

  @override
  State<FindPage> createState() => _FindPageState();
}

class _FindPageState extends State<FindPage> with TickerProviderStateMixin {
  late final FindController controller = FindController(widget.tag);
  late final HistoryKeyworkController historyKeyworkController = HistoryKeyworkController(tag: widget.tag);
  late final FocusNode focusNode = controller.focusNode;
  late final TextEditingController editingController = controller.editingController;
  TabController? tabController;

  late VoidCallback editingListener;
  late final AnimationController suggestionsAnimationC;

  @override
  void initState() {
    super.initState();
    suggestionsAnimationC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    Get.put(historyKeyworkController, tag: widget.tag);
    Get.put(controller, tag: widget.tag);
    editingListener = (){
      if(controller.needShowSuggestions.value){
        suggestionsAnimationC.forward();
      }else{
        suggestionsAnimationC.reverse();
      }
    };
    controller.needShowSuggestions.addListener(editingListener);
  }

  @override
  void dispose() {
    controller.needShowSuggestions.removeListener(editingListener);
    suggestionsAnimationC.dispose();
    historyKeyworkController.dispose();
    controller.dispose();
    Get.delete<HistoryKeyworkController>(tag: widget.tag);
    Get.delete<FindController>(tag: widget.tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BgContainer(
      bg: Assets.other.searchBackdrop.path,
      child: PlayBar(
        builder: (BuildContext context, double barHeight) {
          return Scaffold(
            appBar: AppBar(
              leadingWidth: 0,
              titleSpacing: 0,
              title: _searchBar(),
              centerTitle: false,
            ),
            body: ValueListenableBuilder(
              valueListenable: controller.state,
              builder: (BuildContext context, ResourceStatus state, Widget? child) {
                return BaseStatusWidget(
                  state: state,
                  action: (){
                    controller.queryData(controller.editingController.text);
                  },
                  child: ValueListenableBuilder(
                    valueListenable: controller.isSearchBarEmpty,
                    builder: (BuildContext context, bool isSearchBarEmpty, Widget? child) {
                      return ValueListenableBuilder(
                        valueListenable: controller.isEditing,
                        builder: (BuildContext context, bool isEditing, Widget? child) {
                          return ValueListenableBuilder(
                            valueListenable: controller.needShowSuggestions,
                            builder: (BuildContext context, bool needShowSuggestions, Widget? child) {
                              return ValueListenableBuilder(
                                valueListenable: controller.resourceList,
                                builder: (BuildContext context, List<FileGroup>? resourceList, Widget? child) {
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      top: 20,
                                      bottom: barHeight,
                                    ),
                                    child: Stack(
                                      children: [
                                        FadeTransition(
                                          opacity: AlwaysStoppedAnimation(((resourceList==null || isEditing) && !needShowSuggestions)?1:0),
                                          child: Padding(
                                            padding: EdgeInsets.only(top: 10, left: 16, right: 16),
                                            child: HistoryKeyworkWidget(
                                              tag: widget.tag,
                                              onTap: (keyword){
                                                controller.queryData(keyword, source: 'history');
                                              },
                                            ),
                                          ),
                                        ),
                                        if(!isEditing && !isSearchBarEmpty && resourceList!=null) _contentWidget(),
                                        if(needShowSuggestions) _suggestionsListWidget(),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _searchBar(){
    return ValueListenableBuilder(
      valueListenable: controller.isSearchBarEmpty,
      builder: (BuildContext context, bool isSearchBarEmpty, Widget? child) {
        return ValueListenableBuilder(
          valueListenable: controller.isEditing,
          builder: (BuildContext context, bool isEditing, Widget? child) {
            return Container(
              height: 48,
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                spacing: 15,
                children: [
                  Expanded(
                    child: AlertInputFiled(
                      autofocus: true,
                      borderRadius: 24,
                      maxLines: 1,
                      focusNode: focusNode,
                      controller: editingController,
                      hintText: 'Search for music'.translate,
                      borderSide: BorderSide(width: 1.5, color: Color(0xff337DFF)),
                      prefixIconConstraints: BoxConstraints(minWidth: 12),
                      prefixIcon: SizedBox(width: 12,),
                      suffixIcon: CupertinoButton(
                        onPressed: isSearchBarEmpty?null:(){
                          editingController.text = '';
                          controller.focusNode.requestFocus();
                        },
                        sizeStyle: CupertinoButtonSize.small,
                        padding: EdgeInsets.zero,
                        child: Container(
                          alignment: Alignment.center,
                          width: 48,
                          child: isSearchBarEmpty?
                          Assets.other.historySearch.image( width: 24,):
                          Assets.other.searchClear.image( width: 16,),
                        ),
                      ),
                      onFieldSubmitted: (text){
                        controller.queryData(text);
                      },
                    ),
                  ),
                  if(!isSearchBarEmpty || isEditing || AppRouteObserver.observer.currentRouteName != '/$TabPage') CupertinoButton(
                    onPressed: (){
                      controller.cancelSearch();
                    },
                    sizeStyle: CupertinoButtonSize.small,
                    padding: EdgeInsets.zero,
                    child: Text(
                      'Cancel'.translate,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xff141414),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  ///联想词
  Widget _suggestionsListWidget() {
    return SizeTransition(
      sizeFactor: suggestionsAnimationC,
      child: ValueListenableBuilder(
        valueListenable: controller.suggestionsList,
        builder: (BuildContext context, List<String> suggestionsList, Widget? child) {
          return Container(
            decoration: BoxDecoration(
              color: Color(0xffF7F7F7),
            ),
            child: ListView.separated(
              key: Key(editingController.text),
              padding: EdgeInsets.all(12),
              itemCount: suggestionsList.length,
              itemBuilder: (context, index) {
                String searchKeyword = editingController.text;
                String suggestionsKeyword = suggestionsList[index];
                //前面的
                String frontString = '';
                //中间的
                String string = searchKeyword;
                //后面的
                String behindString = '';
                if (suggestionsKeyword.contains(searchKeyword)) {
                  int startIndex = suggestionsKeyword.indexOf(searchKeyword);
                  frontString = suggestionsKeyword.substring(0, startIndex);
                  behindString = suggestionsKeyword.substring(startIndex + searchKeyword.length, suggestionsKeyword.length);
                } else {
                  string = suggestionsKeyword;
                }
                return GestureDetector(
                  onTap: () {
                    controller.queryData(suggestionsKeyword, source: 'association');
                  },
                  child: Container(
                    color: Colors.transparent,
                    height: 20,
                    child: FittedBox(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Assets.other.searchRow.image( width: 20),
                          SizedBox(width: 10),
                          if (frontString.isNotEmpty)
                            Text(
                              frontString,
                              style: TextStyle(fontSize: 14),
                            ),
                          Text(
                            string,
                            style: TextStyle(fontSize: 14, color: Color(0xFF1D75FF)),
                          ),
                          if (behindString.isNotEmpty)
                            Text(
                              behindString,
                              style: TextStyle(
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              separatorBuilder: (BuildContext context, int index) {
                return SizedBox(height: 16);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _contentWidget(){
    List<FileGroup> resourceList = controller.resourceList.value??[];
    if(tabController?.length != resourceList.length){
      tabController?.dispose();
      tabController = TabController(length: resourceList.length, vsync: this);
      tabController!.addListener(() {
        FindPage.currentTabIndex.value = tabController!.index;
      });
    }
    return Column(
      spacing: 16,
      children: [
        if(resourceList.length>1) TabBarWidget(
          controller: tabController!,
          titles: resourceList.map((fileGroup){
            return fileGroup.name;
          }).toList(),
        ),
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: FindPage.currentTabIndex,
            builder: (BuildContext context, int currentTabIndex, Widget? child) {
              return IndexedStack(
                index: currentTabIndex,
                children: resourceList.map((fileGroup){
                  if(fileGroup.params == null){
                    return FindTopResultView(controller: controller);
                  }
                  return FindTabResultView(
                    keyword: editingController.text,
                    fileGroup: fileGroup,
                    index: resourceList.indexOf(fileGroup),
                  );
                }).toList(),
              );
            },
          ),
        )
      ],
    );
  }
}
