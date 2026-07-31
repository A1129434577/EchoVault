import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/core/persistence/media_collection_repository.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/features/search/controllers/search_state.dart';
import 'package:echo_vault/features/search/widgets/search_tab_result_view.dart';
import 'package:echo_vault/features/search/widgets/search_top_result_view.dart';
import 'package:echo_vault/features/search/widgets/search_history_view.dart';
import 'package:echo_vault/features/primary_navigation_screen.dart';
import 'package:echo_vault/shared/widgets/dialog_text_field.dart';
import 'package:echo_vault/shared/widgets/resource_state_view.dart';
import 'package:echo_vault/shared/widgets/background_surface.dart';
import 'package:echo_vault/features/playback/widgets/playback_bar.dart';
import 'package:echo_vault/shared/widgets/tab_navigation_view.dart';

class SearchScreen extends StatefulWidget {
  static const String homeTag = 'home';
  static const String tabTag = 'tab';

  static ValueNotifier<int> currentTabIndex = ValueNotifier(0);

  final String tag;
  const SearchScreen({super.key, this.tag = tabTag});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with TickerProviderStateMixin {
  late final SearchState controller = SearchState(widget.tag);
  late final SearchHistoryState searchHistoryState = SearchHistoryState(
    tag: widget.tag,
  );
  late final FocusNode focusNode = controller.focusNode;
  late final TextEditingController editingController =
      controller.editingController;
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
    Get.put(searchHistoryState, tag: widget.tag);
    Get.put(controller, tag: widget.tag);
    editingListener = () {
      if (controller.needShowSuggestions.value) {
        suggestionsAnimationC.forward();
      } else {
        suggestionsAnimationC.reverse();
      }
    };
    controller.needShowSuggestions.addListener(editingListener);
  }

  @override
  void dispose() {
    controller.needShowSuggestions.removeListener(editingListener);
    suggestionsAnimationC.dispose();
    searchHistoryState.dispose();
    controller.dispose();
    Get.delete<SearchHistoryState>(tag: widget.tag);
    Get.delete<SearchState>(tag: widget.tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundSurface(
      bg: Assets.images.search.searchBackdrop.path,
      child: PlaybackBar(
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
                return ResourceStateView(
                  state: state,
                  action: () {
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
                            builder:
                                (
                                  BuildContext context,
                                  bool needShowSuggestions,
                                  Widget? child,
                                ) {
                                  return ValueListenableBuilder(
                                    valueListenable: controller.resourceList,
                                    builder:
                                        (
                                          BuildContext context,
                                          List<MediaCollection>? resourceList,
                                          Widget? child,
                                        ) {
                                          return Padding(
                                            padding: EdgeInsets.only(
                                              top: 20,
                                              bottom: barHeight,
                                            ),
                                            child: Stack(
                                              children: [
                                                FadeTransition(
                                                  opacity: AlwaysStoppedAnimation(
                                                    ((resourceList == null ||
                                                                isEditing) &&
                                                            !needShowSuggestions)
                                                        ? 1
                                                        : 0,
                                                  ),
                                                  child: Padding(
                                                    padding: EdgeInsets.only(
                                                      top: 10,
                                                      left: 16,
                                                      right: 16,
                                                    ),
                                                    child: SearchHistoryView(
                                                      tag: widget.tag,
                                                      onTap: (keyword) {
                                                        controller.queryData(
                                                          keyword,
                                                          source: 'history',
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ),
                                                if (!isEditing &&
                                                    !isSearchBarEmpty &&
                                                    resourceList != null)
                                                  _contentWidget(),
                                                if (needShowSuggestions)
                                                  _suggestionsListWidget(),
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

  Widget _searchBar() {
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
                    child: DialogTextField(
                      autofocus: true,
                      borderRadius: 24,
                      maxLines: 1,
                      focusNode: focusNode,
                      controller: editingController,
                      hintText: 'Search for music'.translate,
                      borderSide: BorderSide(
                        width: 1.5,
                        color: Color(0xff337DFF),
                      ),
                      prefixIconConstraints: BoxConstraints(minWidth: 12),
                      prefixIcon: SizedBox(width: 12),
                      suffixIcon: CupertinoButton(
                        onPressed: isSearchBarEmpty
                            ? null
                            : () {
                                editingController.text = '';
                                controller.focusNode.requestFocus();
                              },
                        sizeStyle: CupertinoButtonSize.small,
                        padding: EdgeInsets.zero,
                        child: Container(
                          alignment: Alignment.center,
                          width: 48,
                          child: isSearchBarEmpty
                              ? Assets.images.search.historySearch
                                    .image(width: 24)
                              : Assets.images.search.searchClear.image(
                                  width: 16,
                                ),
                        ),
                      ),
                      onFieldSubmitted: (text) {
                        controller.queryData(text);
                      },
                    ),
                  ),
                  if (!isSearchBarEmpty ||
                      isEditing ||
                      AppRouteObserver.observer.currentRouteName !=
                          '/$PrimaryNavigationScreen')
                    CupertinoButton(
                      onPressed: () {
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
        builder:
            (
              BuildContext context,
              List<String> suggestionsList,
              Widget? child,
            ) {
              return Container(
                decoration: BoxDecoration(color: Color(0xffF7F7F7)),
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
                      int startIndex = suggestionsKeyword.indexOf(
                        searchKeyword,
                      );
                      frontString = suggestionsKeyword.substring(0, startIndex);
                      behindString = suggestionsKeyword.substring(
                        startIndex + searchKeyword.length,
                        suggestionsKeyword.length,
                      );
                    } else {
                      string = suggestionsKeyword;
                    }
                    return GestureDetector(
                      onTap: () {
                        controller.queryData(
                          suggestionsKeyword,
                          source: 'association',
                        );
                      },
                      child: Container(
                        color: Colors.transparent,
                        height: 20,
                        child: FittedBox(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              Assets.images.search.searchRow.image(
                                width: 20,
                              ),
                              SizedBox(width: 10),
                              if (frontString.isNotEmpty)
                                Text(
                                  frontString,
                                  style: TextStyle(fontSize: 14),
                                ),
                              Text(
                                string,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1D75FF),
                                ),
                              ),
                              if (behindString.isNotEmpty)
                                Text(
                                  behindString,
                                  style: TextStyle(fontSize: 14),
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

  Widget _contentWidget() {
    List<MediaCollection> resourceList = controller.resourceList.value ?? [];
    if (tabController?.length != resourceList.length) {
      tabController?.dispose();
      tabController = TabController(length: resourceList.length, vsync: this);
      tabController!.addListener(() {
        SearchScreen.currentTabIndex.value = tabController!.index;
      });
    }
    return Column(
      spacing: 16,
      children: [
        if (resourceList.length > 1)
          TabNavigationView(
            controller: tabController!,
            titles: resourceList.map((mediaCollection) {
              return mediaCollection.name;
            }).toList(),
          ),
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: SearchScreen.currentTabIndex,
            builder:
                (BuildContext context, int currentTabIndex, Widget? child) {
                  return IndexedStack(
                    index: currentTabIndex,
                    children: resourceList.map((mediaCollection) {
                      if (mediaCollection.params == null) {
                        return SearchTopResultView(controller: controller);
                      }
                      return SearchTabResultView(
                        keyword: editingController.text,
                        mediaCollection: mediaCollection,
                        index: resourceList.indexOf(mediaCollection),
                      );
                    }).toList(),
                  );
                },
          ),
        ),
      ],
    );
  }
}
