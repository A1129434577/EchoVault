import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/cupertino.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/core/persistence/media_collection_repository.dart';
import 'package:echo_vault/core/media/media_origin.dart';
import 'package:echo_vault/features/search/widgets/search_history_view.dart';
import 'package:echo_vault/features/discovery/controllers/discovery_state.dart';
import 'package:echo_vault/features/primary_navigation_screen.dart';
import 'package:echo_vault/core/networking/music_catalog_gateway.dart';
import 'package:echo_vault/core/parsing/shared_parser.dart';
import 'package:echo_vault/core/parsing/music_catalog_parser.dart';
import 'package:echo_vault/core/parsing/parser_helper.dart';
import 'package:echo_vault/shared/widgets/resource_state_view.dart';

class SearchState with ChangeNotifier {
  ValueNotifier<List<String>> suggestionsList = ValueNotifier([]);
  //搜索结果列表（其中All是把最佳搜索手动组装成的FileGroup）
  ValueNotifier<List<MediaCollection>?> resourceList = ValueNotifier(null);
  final EasyRefreshController refreshController = EasyRefreshController();

  ValueNotifier<ResourceStatus> state = ValueNotifier(ResourceStatus.idl);
  final FocusNode focusNode = FocusNode();
  final TextEditingController editingController = TextEditingController();
  ValueNotifier<bool> needShowSuggestions = ValueNotifier(false);
  ValueNotifier<bool> isEditing = ValueNotifier(false);
  ValueNotifier<bool> isSearchBarEmpty = ValueNotifier(true);

  late VoidCallback _editingListener;
  final String tag;
  SearchState(this.tag) {
    _editingListener = () {
      isEditing.value = focusNode.hasFocus;
      isSearchBarEmpty.value = editingController.text.isEmpty;
      if (isSearchBarEmpty.value) {
        resourceList.value = null;
        if (state.value != ResourceStatus.source) {
          state.value = ResourceStatus.idl;
        }
      }
      if (focusNode.hasFocus && editingController.text.isNotEmpty) {
        needShowSuggestions.value = true;
        querySuggestions(editingController.text);
      } else {
        needShowSuggestions.value = false;
      }
    };
    editingController.addListener(_editingListener);
    focusNode.addListener(_editingListener);
  }

  Future querySuggestions(String keyword) async {
    Map<String, dynamic>? params = {'input': keyword};
    dynamic result = await MusicCatalogGateway.post(
      url: MusicCatalogEndpoints.suggestions,
      prams: params,
    );
    List results =
        ParserHelper.parse<List>(result, SearchParserKeys.suggestionsList) ??
        [];

    List<String> list = [];
    for (final suggestionItemMap in results) {
      List runs =
          ParserHelper.parse<List>(
            suggestionItemMap,
            SearchParserKeys.suggestionsItemRuns,
          ) ??
          [];
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
    editingController.text = keyword;
    focusNode.unfocus();
    Get.find<SearchHistoryState>(tag: tag).saveHistoryKeyword(keyword);
    if (DiscoveryState.instance.isYoutubeMusicEnable.value) {
      await _queryData(source: source);
    } else {
      await _queryYTData(source: source);
    }
    if (resourceList.value?.isEmpty == true) {
      state.value = ResourceStatus.empty;
    } else if (resourceList.value?.isNotEmpty == true) {
      state.value = ResourceStatus.source;
    } else {
      state.value = ResourceStatus.error;
    }
  }

  Future _queryData({String source = 'input'}) async {
    Map<String, dynamic>? params = {
      'query': editingController.text,
      //from自定义埋点字段，非接口需要
      'from': source,
    };
    dynamic result = await MusicCatalogGateway.post(
      url: MusicCatalogEndpoints.search,
      prams: params,
    );
    if (result == null) {
      return;
    }
    //更新全局的visitorData
    if ((await MusicCatalogGateway.visitorData) == null) {
      final visitorData = ParserHelper.parse<String>(
        result,
        SharedParserKeys.visitorData,
      );
      if (visitorData != null) {
        MusicCatalogGateway.visitorData = visitorData;
      }
    }

    List<MediaCollection> results = [];
    List topMapList =
        ParserHelper.parse<List>(result, SearchParserKeys.topResourceList) ??
        [];
    if (topMapList.isNotEmpty) {
      //最佳搜索结果
      MediaCollection topFileGroup = MediaCollection(
        name: 'All'.translate,
        children: [],
      );
      List newSearchOtherList = [];
      for (Map element in topMapList) {
        if (element.containsKey(CardShelfParserKeys.cardShelf)) {
          //由于卡片不是分组，所以手动组装一个分组并加入卡片以及卡片紧跟的列表
          MediaCollection childGroup = MediaCollection(children: []);
          //最佳搜索卡片:FilGroup|PerformerDetails|FileInfo
          final item = (await SharedParser.parseChildren([
            element,
          ], source: MediaOrigin.search)).firstOrNull;
          if (item != null) {
            childGroup.children.add(item);
          }
          //最佳搜索卡片紧跟的音乐（可能没有）
          element = element[CardShelfParserKeys.cardShelf];
          if (element.containsKey(SharedParserKeys.children)) {
            final childrenMapList = element[SharedParserKeys.children];
            if (childrenMapList != null) {
              List list = await SharedParser.parseChildren(
                childrenMapList,
                source: MediaOrigin.search,
              );
              childGroup.children.addAll(list);
            }
          }
          topFileGroup.children.add(childGroup);
        } else if (element.containsKey(ShelfParserKeys.shelf)) {
          //最佳搜索延伸的音乐
          List<MediaCollection> list = await SharedParser.parseContents([
            element,
          ], source: MediaOrigin.search);
          topFileGroup.children.addAll(list);
        } else if (element.containsKey(SearchParserKeys.searchNewItem)) {
          element = element[SearchParserKeys.searchNewItem];
          List responsiveList = element[SharedParserKeys.children] ?? [];
          newSearchOtherList.addAll(responsiveList);
        }
      }
      if (newSearchOtherList.isNotEmpty) {
        List list = await SharedParser.parseChildren(
          newSearchOtherList,
          source: MediaOrigin.search,
        );
        MediaCollection newSearchOtherGroup = MediaCollection(
          type: MediaCollectionShowType.listMusic,
        );
        if (list.isNotEmpty) {
          newSearchOtherGroup.children = list;
          topFileGroup.children.add(newSearchOtherGroup);
        }
      }
      if (topFileGroup.children.isNotEmpty) {
        results.add(topFileGroup);
      }
    }

    //搜索结果所有tab
    List tabMapList =
        ParserHelper.parse<List>(result, SearchParserKeys.tabList) ?? [];
    for (Map tabMap in tabMapList) {
      if (tabMap.containsKey(SearchParserKeys.tab)) {
        tabMap = tabMap[SearchParserKeys.tab];
        MediaCollection tabFileGroup = MediaCollection();
        tabFileGroup.name =
            ParserHelper.parse<String>(
              tabMap,
              SearchParserKeys.tabGroupTitle,
            ) ??
            '';
        tabFileGroup.params = ParserHelper.parse<String>(
          tabMap,
          SearchParserKeys.tabGroupParams,
        );
        results.add(tabFileGroup);
      }
    }
    resourceList.value = results;
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
    dynamic result = await MusicCatalogGateway.post(
      url: MusicCatalogEndpoints.ytSearch,
      prams: params,
      query: query,
      isMusic: false,
    );
    if (result == null) {
      return;
    }
    //更新全局的visitorData
    if ((await MusicCatalogGateway.visitorData) == null) {
      final visitorData = ParserHelper.parse<String>(
        result,
        SharedParserKeys.visitorData,
      );
      if (visitorData != null) {
        MusicCatalogGateway.visitorData = visitorData;
      }
    }

    String? newContinuation;
    if (continuation == null) {
      //将下一页的分页请求参数保存下来
      newContinuation = ParserHelper.parse<String>(
        result,
        SearchCatalogParserKeys.continuation,
      );
      _continuation = newContinuation;

      MediaCollection topFileGroup = MediaCollection(
        name: 'All'.translate,
        children: [],
      );

      //最佳搜索卡片
      Map card =
          ParserHelper.parse<Map>(
            result,
            SearchCatalogParserKeys.topUniversalWatchCardRenderer,
          ) ??
          {};
      //由于卡片不是分组，所以手动组装一个分组并加入卡片以及卡片紧跟的列表
      MediaCollection childGroup = MediaCollection(children: []);
      if (card.containsKey(SearchCatalogParserKeys.topCard)) {
        Map header = card[SearchCatalogParserKeys.topCard];
        //最佳搜索卡片:FilGroup|PerformerDetails
        final item = (await MusicCatalogParser.parseSearchTopChildren([
          header,
        ], source: MediaOrigin.search)).firstOrNull;
        if (item != null) {
          if (item is MediaCollection) {
            item.thumbnail =
                ParserHelper.parse<String>(
                  result,
                  SearchCatalogParserKeys.topCardAlbumCover,
                ) ??
                '';
          }
          childGroup.children.add(item);
        }
      }

      //最佳搜索卡片紧跟的音乐
      List topGroupParentList =
          ParserHelper.parse<List>(
            card,
            SearchCatalogParserKeys.topVideoFileGroupFilterItems,
          ) ??
          [];
      for (final part in topGroupParentList) {
        List childrenMapList =
            ParserHelper.parse<List>(
              part,
              SearchCatalogParserKeys.topVideoFileGroupItems,
            ) ??
            [];
        List topChildren = await MusicCatalogParser.parseSearchTopChildren(
          childrenMapList,
        );
        childGroup.children.addAll(topChildren);
      }
      if (childGroup.children.isNotEmpty) {
        topFileGroup.children.add(childGroup);
      }

      //搜索结果
      List list =
          ParserHelper.parse<List>(
            result,
            SearchCatalogParserKeys.resourceList,
          ) ??
          [];
      MediaCollection mediaCollection = MediaCollection(
        children: [],
        type: MediaCollectionShowType.listMusic,
      );
      List children = await MusicCatalogParser.parseSearchChildren(list);
      mediaCollection.children.addAll(children);
      topFileGroup.children.add(mediaCollection);
      resourceList.value = [topFileGroup];
    } else {
      newContinuation = ParserHelper.parse<String>(
        result,
        SearchCatalogParserKeys.moreContinuation,
      );
      if (newContinuation != null) {
        _continuation = newContinuation;
      }
      List list =
          ParserHelper.parse<List>(
            result,
            SearchCatalogParserKeys.moreResourceList,
          ) ??
          [];
      List children = await MusicCatalogParser.parseSearchChildren(list);

      for (MediaCollection tabGroup in resourceList.value ?? []) {
        if (tabGroup.params == null) {
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

  void cancelSearch() {
    if (AppRouteObserver.observer.currentRouteName ==
        '/$PrimaryNavigationScreen') {
      if (isEditing.value) {
        focusNode.unfocus();
      } else {
        editingController.text = '';
      }
    } else {
      if (isEditing.value) {
        focusNode.unfocus();
        if (editingController.text.isEmpty) {
          Get.back();
        }
      } else {
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

class SearchParserKeys {
  static List suggestionsList = [
    'contents',
    {ParserHelper.indexKey: 0},
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
    {ParserHelper.indexKey: 0},
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
    {ParserHelper.indexKey: 0},
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
    {ParserHelper.indexKey: 0},
    'text',
  ];

  static List tabGroupParams = [
    'navigationEndpoint',
    'searchEndpoint',
    'params',
  ];
}
