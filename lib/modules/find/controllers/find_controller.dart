import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/cupertino.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/datebase/file_group_data_operate.dart';
import 'package:echo_vault/enums/file_source.dart';
import 'package:echo_vault/modules/find/widgets/history_keywork_widget.dart';
import 'package:echo_vault/modules/home/controllers/home_controller.dart';
import 'package:echo_vault/modules/tab_page.dart';
import 'package:echo_vault/network/ytm_network.dart';
import 'package:echo_vault/parse/common_parse.dart';
import 'package:echo_vault/parse/common_yt_parse.dart';
import 'package:echo_vault/parse/parse_util.dart';
import 'package:echo_vault/widgets/base_status_widget.dart';

class FindController with ChangeNotifier {
  ValueNotifier<List<String>> suggestionsList = ValueNotifier([]);
  //搜索结果列表（其中All是把最佳搜索手动组装成的FileGroup）
  ValueNotifier<List<FileGroup>?> resourceList = ValueNotifier(null);
  final EasyRefreshController refreshController = EasyRefreshController();

  ValueNotifier<ResourceStatus> state = ValueNotifier(ResourceStatus.idl);
  final FocusNode focusNode = FocusNode();
  final TextEditingController editingController =TextEditingController();
  ValueNotifier<bool> needShowSuggestions = ValueNotifier(false);
  ValueNotifier<bool> isEditing = ValueNotifier(false);
  ValueNotifier<bool> isSearchBarEmpty = ValueNotifier(true);

  late VoidCallback _editingListener;
  final String tag;
  FindController(this.tag){
    _editingListener = (){
      isEditing.value = focusNode.hasFocus;
      isSearchBarEmpty.value = editingController.text.isEmpty;
      if(isSearchBarEmpty.value){
        resourceList.value = null;
        if(state.value != ResourceStatus.source){
          state.value = ResourceStatus.idl;
        }
      }
      if(focusNode.hasFocus && editingController.text.isNotEmpty) {
        needShowSuggestions.value = true;
        querySuggestions(editingController.text);
      }else{
        needShowSuggestions.value = false;
      }
    };
    editingController.addListener(_editingListener);
    focusNode.addListener(_editingListener);
  }

  Future querySuggestions(String keyword) async {
    Map<String, dynamic>? params = {'input': keyword};
    dynamic result = await YTMNetwork.post(
      url: YTMApis.suggestions,
      prams: params,
    );
    List resultList = ParseUtil.parse<List>(result, FindParseKeys.suggestionsList)??[];

    List<String> list = [];
    for(final suggestionItemMap in resultList) {
      List runs = ParseUtil.parse<List>(suggestionItemMap, FindParseKeys.suggestionsItemRuns) ?? [];
      String suggestion = '';
      for (Map text in runs) {
        suggestion += text['text'];
      }
      list.add(suggestion);
    }
    suggestionsList.value = list;
  }

  Future queryData(String keyword, {String source = 'input'}) async {
    state.value = ResourceStatus.loading;
    editingController.text= keyword;
    focusNode.unfocus();
    Get.find<HistoryKeyworkController>(tag: tag).saveHistoryKeywork(keyword);
    if(HomeController.instance.isYoutubeMusicEnable.value){
      await _queryData(source: source);
    }else{
      await _queryYTData(source: source);
    }
    if(resourceList.value?.isEmpty==true){
      state.value = ResourceStatus.empty;
    }
    else if(resourceList.value?.isNotEmpty==true){
      state.value = ResourceStatus.source;
    }
    else {
      state.value = ResourceStatus.error;
    }
  }

  Future _queryData({String source = 'input'}) async {
    Map<String, dynamic>? params = {
      'query': editingController.text,
      //from自定义埋点字段，非接口需要
      'from': source,
    };
    dynamic result = await YTMNetwork.post(
      url: YTMApis.search,
      prams: params,
    );
    if(result==null){
      return;
    }
    //更新全局的visitorData
    if((await YTMNetwork.visitorData)==null) {
      final visitorData = ParseUtil.parse<String>(result, CommonParseKeys.visitorData);
      if (visitorData != null) {
        YTMNetwork.visitorData = visitorData;
      }
    }

    List<FileGroup> resultList = [];
    List topMapList = ParseUtil.parse<List>(result, FindParseKeys.topResourceList)??[];
    if(topMapList.isNotEmpty){
      //最佳搜索结果
      FileGroup topFileGroup = FileGroup(name: 'All'.translate, children: []);
      List newSearchOtherList = [];
      for(Map element in topMapList){
        if(element.containsKey(CardShelfParseKeys.cardShelf)) {
          //由于卡片不是分组，所以手动组装一个分组并加入卡片以及卡片紧跟的列表
          FileGroup childGroup = FileGroup(children: []);
          //最佳搜索卡片:FilGroup|ArtistInfo|FileInfo
          final item = (await CommonParse.parseChildren([element], source: FileSource.search)).firstOrNull;
          if(item != null){
            childGroup.children.add(item);
          }
          //最佳搜索卡片紧跟的音乐（可能没有）
          element = element[CardShelfParseKeys.cardShelf];
          if(element.containsKey(CommonParseKeys.children)) {
            final childrenMapList = element[CommonParseKeys.children];
            if (childrenMapList != null) {
              List list = await CommonParse.parseChildren(childrenMapList, source: FileSource.search);
              childGroup.children.addAll(list);
            }
          }
          topFileGroup.children.add(childGroup);
        }
        else if(element.containsKey(ShelfParseKeys.shelf)) {
          //最佳搜索延伸的音乐
          List<FileGroup> list = await CommonParse.parseContents([element], source: FileSource.search);
          topFileGroup.children.addAll(list);
        }
        else if(element.containsKey(FindParseKeys.searchNewItem)) {
          element = element[FindParseKeys.searchNewItem];
          List responsiveList = element[CommonParseKeys.children]??[];
          newSearchOtherList.addAll(responsiveList);
        }
      }
      if(newSearchOtherList.isNotEmpty){
        List list = await CommonParse.parseChildren(newSearchOtherList, source: FileSource.search);
        FileGroup newSearchOtherGroup = FileGroup(type: FileGroupShowType.listMusic);
        if(list.isNotEmpty){
          newSearchOtherGroup.children = list;
          topFileGroup.children.add(newSearchOtherGroup);
        }
      }
      if(topFileGroup.children.isNotEmpty) {
        resultList.add(topFileGroup);
      }
    }

    //搜索结果所有tab
    List tabMapList = ParseUtil.parse<List>(result, FindParseKeys.tabList)??[];
    for(Map tabMap in tabMapList){
      if(tabMap.containsKey(FindParseKeys.tab)) {
        tabMap = tabMap[FindParseKeys.tab];
        FileGroup tabFileGroup = FileGroup();
        tabFileGroup.name = ParseUtil.parse<String>(tabMap, FindParseKeys.tabGroupTitle)??'';
        tabFileGroup.params = ParseUtil.parse<String>(tabMap, FindParseKeys.tabGroupParams);
        resultList.add(tabFileGroup);
      }
    }
    resourceList.value = resultList;
  }

  Future _queryYTData({String? continuation, String source = 'input'}) async {
    Map<String, dynamic>? params = {
      'query': editingController.text,
      //from自定义埋点字段，非接口需要
      'from': source,
    };
    Map<String, dynamic>? query;
    if (continuation != null) {
      query = {'continuation': continuation};
    }
    dynamic result = await YTMNetwork.post(
      url: YTMApis.ytSearch,
      prams: params,
      query: query,
      isMusic: false,
    );
    if(result==null){
      return;
    }
    //更新全局的visitorData
    if((await YTMNetwork.visitorData)==null) {
      final visitorData = ParseUtil.parse<String>(result, CommonParseKeys.visitorData);
      if (visitorData != null) {
        YTMNetwork.visitorData = visitorData;
      }
    }

    String? newContinuation;
    if(continuation == null){
      //将下一页的分页请求参数保存下来
      newContinuation = ParseUtil.parse<String>(result, SearchYTParseKeys.continuation);
      _continuation = newContinuation;

      FileGroup topFileGroup = FileGroup(name: 'All'.translate, children: []);

      //最佳搜索卡片
      Map card = ParseUtil.parse<Map>(result, SearchYTParseKeys.topUniversalWatchCardRenderer)??{};
      //由于卡片不是分组，所以手动组装一个分组并加入卡片以及卡片紧跟的列表
      FileGroup childGroup = FileGroup(children: []);
      if(card.containsKey(SearchYTParseKeys.topCard)){
        Map header = card[SearchYTParseKeys.topCard];
        //最佳搜索卡片:FilGroup|ArtistInfo
        final item = (await CommonYtParse.parseSearchTopChildren([header], source: FileSource.search)).firstOrNull;
        if(item != null){
          if(item is FileGroup){
            item.thumbnail = ParseUtil.parse<String>(result, SearchYTParseKeys.topCardAlbumCover)??'';
          }
          childGroup.children.add(item);
        }
      }

      //最佳搜索卡片紧跟的音乐
      List topGroupParentList = ParseUtil.parse<List>(card, SearchYTParseKeys.topVideoFileGroupFilterItems)??[];
      for (final part in topGroupParentList) {
        List childrenMapList = ParseUtil.parse<List>(part, SearchYTParseKeys.topVideoFileGroupItems)??[];
        List topChildren = await CommonYtParse.parseSearchTopChildren(childrenMapList);
        childGroup.children.addAll(topChildren);
      }
      if(childGroup.children.isNotEmpty) {
        topFileGroup.children.add(childGroup);
      }

      //搜索结果
      List list = ParseUtil.parse<List>(result, SearchYTParseKeys.resourceList)??[];
      FileGroup fileGroup = FileGroup(children: [], type: FileGroupShowType.listMusic);
      List children = await CommonYtParse.parseSearchChildren(list);
      fileGroup.children.addAll(children);
      topFileGroup.children.add(fileGroup);
      resourceList.value = [topFileGroup];
    }else{
      newContinuation = ParseUtil.parse<String>(result, SearchYTParseKeys.moreContinuation);
      if (newContinuation != null) {
        _continuation = newContinuation;
      }
      List list = ParseUtil.parse<List>(result, SearchYTParseKeys.moreResourceList)??[];
      List children = await CommonYtParse.parseSearchChildren(list);

      for(FileGroup tabGroup in resourceList.value??[]){
        if(tabGroup.params==null){
          tabGroup.children.last.children.addAll(children);
          break;
        }
      }
      resourceList.notifyListeners();
    }

    if (newContinuation == null) {
      return IndicatorResult.noMore;
    }
  }

  //请求更多分页的参数
  String? _continuation;
  Future loadMoreYTData() async {
    return await _queryYTData(continuation: _continuation);
  }

  void cancelSearch(){
    if(AppRouteObserver.observer.currentRouteName == '/$TabPage'){
      if(isEditing.value){
        focusNode.unfocus();
      }else{
        editingController.text = '';
      }
    }else{
      if(isEditing.value){
        focusNode.unfocus();
        if(editingController.text.isEmpty) {
          Get.back();
        }
      }else{
        Get.back();
      }
    }
  }


  @override
  void dispose() {
    editingController.removeListener(_editingListener);
    focusNode.removeListener(_editingListener);
    editingController.dispose();
    focusNode.dispose();
    super.dispose();
  }
}

class FindParseKeys {
  static List suggestionsList = [
    'contents',
    {
      ParseUtil.indexKey: 0,
    },
    'searchSuggestionsSectionRenderer',
    'contents',
  ];

  static List suggestionsItemRuns = [
    'searchSuggestionRenderer',
    'suggestion',
    'runs',
  ];

  static String searchNewItem = 'itemSectionRenderer';

  //最佳搜索
  static List topResourceList = [
    'contents',
    'tabbedSearchResultsRenderer',
    'tabs',
    {
      ParseUtil.indexKey: 0,
    },
    'tabRenderer',
    'content',
    'sectionListRenderer',
    'contents',
  ];

  static String tab = 'chipCloudChipRenderer';

  //其他tab
  static List tabList = [
    'contents',
    'tabbedSearchResultsRenderer',
    'tabs',
    {
      ParseUtil.indexKey: 0,
    },
    'tabRenderer',
    'content',
    'sectionListRenderer',
    'header',
    'chipCloudRenderer',
    'chips',
  ];

  static List tabGroupTitle = [
    'text',
    'runs',
    {
      ParseUtil.indexKey: 0,
    },
    'text',
  ];

  static List tabGroupParams = [
    'navigationEndpoint',
    'searchEndpoint',
    'params',
  ];
}

