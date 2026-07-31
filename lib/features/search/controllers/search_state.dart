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

class SearchParserKeys {
  static List suggestionItemsPath = [
    'contents',
    {ParserHelper.positionField: 0},
    'searchSuggestionsSectionRenderer',
    'contents',
  ];

  static List suggestionTextPath = [
    'searchSuggestionRenderer',
    'suggestion',
    'runs',
  ];

  static String resultSectionKey = 'itemSectionRenderer';

  //最佳搜索
  static List primaryResultsPath = [
    'contents',
    'tabbedSearchResultsRenderer',
    'tabs',
    {ParserHelper.positionField: 0},
    'tabRenderer',
    'content',
    'sectionListRenderer',
    'contents',
  ];

  static String filterChipKey = 'chipCloudChipRenderer';

  //其他tab
  static List filterItemsPath = [
    'contents',
    'tabbedSearchResultsRenderer',
    'tabs',
    {ParserHelper.positionField: 0},
    'tabRenderer',
    'content',
    'sectionListRenderer',
    'header',
    'chipCloudRenderer',
    'chips',
  ];

  static List filterTitlePath = [
    'text',
    'runs',
    {ParserHelper.positionField: 0},
    'text',
  ];

  static List filterParamsPath = [
    'navigationEndpoint',
    'searchEndpoint',
    'params',
  ];
}

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

  //请求更多分页的参数
  String? _continuation;
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
        fetchSuggestions(editingController.text);
      } else {
        needShowSuggestions.value = false;
      }
    };
    editingController.addListener(_editingListener);
    focusNode.addListener(_editingListener);
  }

  @override
  void dispose() {
    editingController.removeListener(_editingListener);
    focusNode.removeListener(_editingListener);
    editingController.dispose();
    focusNode.dispose();
    super.dispose();
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

  Future fetchMoreYTData() async {
    return await _fetchYTData(continuationArg: _continuation);
  }

  Future fetchData(String keywordArg, {String mediaOrigin = 'input'}) async {
    state.value = ResourceStatus.loading;
    editingController.text = keywordArg;
    focusNode.unfocus();
    Get.find<SearchHistoryState>(tag: tag).saveHistoryKeyword(keywordArg);
    if (DiscoveryState.instance.isYoutubeMusicEnable.value) {
      await _fetchData(mediaOrigin: mediaOrigin);
    } else {
      await _fetchYTData(mediaOrigin: mediaOrigin);
    }
    if (resourceList.value?.isEmpty == true) {
      state.value = ResourceStatus.empty;
    } else if (resourceList.value?.isNotEmpty == true) {
      state.value = ResourceStatus.source;
    } else {
      state.value = ResourceStatus.error;
    }
  }

  Future fetchSuggestions(String keywordArg) async {
    Map<String, dynamic>? requestParameters = {'input': keywordArg};
    dynamic response = await MusicCatalogGateway.post(
      resourceUrl: MusicCatalogEndpoints.querySuggestions,
      pramsArg: requestParameters,
    );
    List responses =
        ParserHelper.parse<List>(
          response,
          SearchParserKeys.suggestionItemsPath,
        ) ??
        [];

    List<String> entries = [];
    for (final suggestionItemMap in responses) {
      List runsLocal =
          ParserHelper.parse<List>(
            suggestionItemMap,
            SearchParserKeys.suggestionTextPath,
          ) ??
          [];
      String suggestionLocal = '';
      for (Map text in runsLocal) {
        suggestionLocal += text['text'];
      }
      entries.add(suggestionLocal);
    }
    suggestionsList.value = entries;
  }

  Future _fetchData({String mediaOrigin = 'input'}) async {
    Map<String, dynamic>? requestParameters = {
      'query': editingController.text,
      //from自定义埋点字段，非接口需要
      'from': mediaOrigin,
    };
    dynamic response = await MusicCatalogGateway.post(
      resourceUrl: MusicCatalogEndpoints.catalogSearch,
      pramsArg: requestParameters,
    );
    if (response == null) {
      return;
    }
    //更新全局的visitorData
    if ((await MusicCatalogGateway.visitorData) == null) {
      final visitorDataLocal = ParserHelper.parse<String>(
        response,
        SharedParserKeys.visitorDataPath,
      );
      if (visitorDataLocal != null) {
        MusicCatalogGateway.visitorData = visitorDataLocal;
      }
    }

    List<MediaCollection> responses = [];
    List topMapListLocal =
        ParserHelper.parse<List>(
          response,
          SearchParserKeys.primaryResultsPath,
        ) ??
        [];
    if (topMapListLocal.isNotEmpty) {
      //最佳搜索结果
      MediaCollection topFileGroupLocal = MediaCollection(
        name: 'All'.translate,
        children: [],
      );
      List newSearchOtherListLocal = [];
      for (Map element in topMapListLocal) {
        if (element.containsKey(CardShelfParserKeys.cardShelfNode)) {
          //由于卡片不是分组，所以手动组装一个分组并加入卡片以及卡片紧跟的列表
          MediaCollection childGroupLocal = MediaCollection(children: []);
          //最佳搜索卡片:FilGroup|PerformerDetails|FileInfo
          final entry = (await SharedParser.decodeChildren([
            element,
          ], mediaOrigin: MediaOrigin.searchResults)).firstOrNull;
          if (entry != null) {
            childGroupLocal.children.add(entry);
          }
          //最佳搜索卡片紧跟的音乐（可能没有）
          element = element[CardShelfParserKeys.cardShelfNode];
          if (element.containsKey(SharedParserKeys.childrenNode)) {
            final childRecords = element[SharedParserKeys.childrenNode];
            if (childRecords != null) {
              List entries = await SharedParser.decodeChildren(
                childRecords,
                mediaOrigin: MediaOrigin.searchResults,
              );
              childGroupLocal.children.addAll(entries);
            }
          }
          topFileGroupLocal.children.add(childGroupLocal);
        } else if (element.containsKey(ShelfParserKeys.shelfNode)) {
          //最佳搜索延伸的音乐
          List<MediaCollection> entries = await SharedParser.decodeContents([
            element,
          ], mediaOrigin: MediaOrigin.searchResults);
          topFileGroupLocal.children.addAll(entries);
        } else if (element.containsKey(SearchParserKeys.resultSectionKey)) {
          element = element[SearchParserKeys.resultSectionKey];
          List responsiveListLocal =
              element[SharedParserKeys.childrenNode] ?? [];
          newSearchOtherListLocal.addAll(responsiveListLocal);
        }
      }
      if (newSearchOtherListLocal.isNotEmpty) {
        List entries = await SharedParser.decodeChildren(
          newSearchOtherListLocal,
          mediaOrigin: MediaOrigin.searchResults,
        );
        MediaCollection newSearchOtherGroupLocal = MediaCollection(
          type: MediaCollectionShowType.listMusic,
        );
        if (entries.isNotEmpty) {
          newSearchOtherGroupLocal.children = entries;
          topFileGroupLocal.children.add(newSearchOtherGroupLocal);
        }
      }
      if (topFileGroupLocal.children.isNotEmpty) {
        responses.add(topFileGroupLocal);
      }
    }

    //搜索结果所有tab
    List tabMapListLocal =
        ParserHelper.parse<List>(response, SearchParserKeys.filterItemsPath) ??
        [];
    for (Map tabMap in tabMapListLocal) {
      if (tabMap.containsKey(SearchParserKeys.filterChipKey)) {
        tabMap = tabMap[SearchParserKeys.filterChipKey];
        MediaCollection tabFileGroupLocal = MediaCollection();
        tabFileGroupLocal.name =
            ParserHelper.parse<String>(
              tabMap,
              SearchParserKeys.filterTitlePath,
            ) ??
            '';
        tabFileGroupLocal.params = ParserHelper.parse<String>(
          tabMap,
          SearchParserKeys.filterParamsPath,
        );
        responses.add(tabFileGroupLocal);
      }
    }
    resourceList.value = responses;
  }

  Future _fetchYTData({
    String? continuationArg,
    String mediaOrigin = 'input',
  }) async {
    Map<String, dynamic>? requestParameters = {
      'query': editingController.text,
      //from自定义埋点字段，非接口需要
      'from': mediaOrigin,
    };
    Map<String, dynamic>? queryLocal;
    if (continuationArg != null) {
      queryLocal = {'continuation': continuationArg};
    }
    dynamic response = await MusicCatalogGateway.post(
      resourceUrl: MusicCatalogEndpoints.videoSearch,
      pramsArg: requestParameters,
      queryArg: queryLocal,
      isMusicArg: false,
    );
    if (response == null) {
      return;
    }
    //更新全局的visitorData
    if ((await MusicCatalogGateway.visitorData) == null) {
      final visitorDataLocal = ParserHelper.parse<String>(
        response,
        SharedParserKeys.visitorDataPath,
      );
      if (visitorDataLocal != null) {
        MusicCatalogGateway.visitorData = visitorDataLocal;
      }
    }

    String? newContinuationLocal;
    if (continuationArg == null) {
      //将下一页的分页请求参数保存下来
      newContinuationLocal = ParserHelper.parse<String>(
        response,
        SearchCatalogParserKeys.continuationPath,
      );
      _continuation = newContinuationLocal;

      MediaCollection topFileGroupLocal = MediaCollection(
        name: 'All'.translate,
        children: [],
      );

      //最佳搜索卡片
      Map cardLocal =
          ParserHelper.parse<Map>(
            response,
            SearchCatalogParserKeys.topUniversalWatchCardRendererPath,
          ) ??
          {};
      //由于卡片不是分组，所以手动组装一个分组并加入卡片以及卡片紧跟的列表
      MediaCollection childGroupLocal = MediaCollection(children: []);
      if (cardLocal.containsKey(SearchCatalogParserKeys.topCardNode)) {
        Map headerLocal = cardLocal[SearchCatalogParserKeys.topCardNode];
        //最佳搜索卡片:FilGroup|PerformerDetails
        final entry = (await MusicCatalogParser.decodeSearchTopChildren([
          headerLocal,
        ], mediaOrigin: MediaOrigin.searchResults)).firstOrNull;
        if (entry != null) {
          if (entry is MediaCollection) {
            entry.thumbnail =
                ParserHelper.parse<String>(
                  response,
                  SearchCatalogParserKeys.topCardAlbumCoverPath,
                ) ??
                '';
          }
          childGroupLocal.children.add(entry);
        }
      }

      //最佳搜索卡片紧跟的音乐
      List topGroupParentListLocal =
          ParserHelper.parse<List>(
            cardLocal,
            SearchCatalogParserKeys.topVideoFileGroupFilterItemsPath,
          ) ??
          [];
      for (final part in topGroupParentListLocal) {
        List childRecords =
            ParserHelper.parse<List>(
              part,
              SearchCatalogParserKeys.topVideoFileGroupItemsPath,
            ) ??
            [];
        List topChildrenLocal =
            await MusicCatalogParser.decodeSearchTopChildren(childRecords);
        childGroupLocal.children.addAll(topChildrenLocal);
      }
      if (childGroupLocal.children.isNotEmpty) {
        topFileGroupLocal.children.add(childGroupLocal);
      }

      //搜索结果
      List entries =
          ParserHelper.parse<List>(
            response,
            SearchCatalogParserKeys.resourceListPath,
          ) ??
          [];
      MediaCollection mediaCollectionLocal = MediaCollection(
        children: [],
        type: MediaCollectionShowType.listMusic,
      );
      List childEntries = await MusicCatalogParser.decodeSearchChildren(
        entries,
      );
      mediaCollectionLocal.children.addAll(childEntries);
      topFileGroupLocal.children.add(mediaCollectionLocal);
      resourceList.value = [topFileGroupLocal];
    } else {
      newContinuationLocal = ParserHelper.parse<String>(
        response,
        SearchCatalogParserKeys.moreContinuationPath,
      );
      if (newContinuationLocal != null) {
        _continuation = newContinuationLocal;
      }
      List entries =
          ParserHelper.parse<List>(
            response,
            SearchCatalogParserKeys.moreResourceListPath,
          ) ??
          [];
      List childEntries = await MusicCatalogParser.decodeSearchChildren(
        entries,
      );

      for (MediaCollection tabGroup in resourceList.value ?? []) {
        if (tabGroup.params == null) {
          tabGroup.children.last.children.addAll(childEntries);
          break;
        }
      }
      resourceList.notifyListeners();
    }

    if (newContinuationLocal == null) {
      return IndicatorResult.noMore;
    }
  }
}
