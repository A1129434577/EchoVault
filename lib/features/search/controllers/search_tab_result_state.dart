import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/cupertino.dart';
import 'package:echo_vault/core/persistence/media_collection_repository.dart';
import 'package:echo_vault/core/media/media_origin.dart';
import 'package:echo_vault/core/networking/music_catalog_gateway.dart';
import 'package:echo_vault/core/parsing/shared_parser.dart';
import 'package:echo_vault/core/parsing/parser_helper.dart';

class SearchTabResultState with ChangeNotifier {
  ValueNotifier<List> records = ValueNotifier([]);
  final EasyRefreshController refreshController = EasyRefreshController();

  final String keyword;
  final MediaCollection mediaCollection;
  SearchTabResultState({required this.keyword, required this.mediaCollection});

  Future refreshResource() async {
    await _queryResource();
  }

  //请求更多分页的参数
  String? _continuation;
  Future loadMoreResource() async {
    return await _queryResource(continuation: _continuation);
  }

  Future _queryResource({String? continuation}) async {
    Map<String, dynamic>? params = {
      'query': keyword,
      'params': mediaCollection.params,
    };
    Map<String, dynamic>? query;
    if (continuation != null) {
      query = {'continuation': continuation};
    }
    dynamic result = await MusicCatalogGateway.post(
      url: MusicCatalogEndpoints.searchTabResult,
      prams: params,
      query: query,
    );

    String? newContinuation;
    if (continuation == null) {
      records.value.clear();
      //将下一页的分页请求参数保存下来
      newContinuation = ParserHelper.parse<String>(
        result,
        SearchTabResultParserKeys.initContinuation,
      );
      _continuation = newContinuation;
      result =
          ParserHelper.parse<List>(
            result,
            SearchTabResultParserKeys.initResourceList,
          ) ??
          [];
      List<MediaCollection> list = await SharedParser.parseContents(
        result,
        source: MediaOrigin.search,
      );
      records.value.addAll(list.firstOrNull?.children ?? []);
    } else {
      newContinuation = ParserHelper.parse<String>(
        result,
        SearchTabResultParserKeys.moreContinuation,
      );
      if (newContinuation != null) {
        _continuation = newContinuation;
      }
      result =
          ParserHelper.parse<List>(
            result,
            SearchTabResultParserKeys.moreResourceList,
          ) ??
          [];
      List list = await SharedParser.parseChildren(
        result,
        source: MediaOrigin.search,
      );
      records.value.addAll(list);
    }

    records.notifyListeners();
    if (newContinuation == null) {
      return IndicatorResult.noMore;
    }
  }
}

class SearchTabResultParserKeys {
  //翻页参数
  static List initContinuation = [
    'contents',
    'tabbedSearchResultsRenderer',
    'tabs',
    {ParserHelper.indexKey: 0},
    'tabRenderer',
    'content',
    'sectionListRenderer',
    'contents',
    {ParserHelper.filterKey: 'musicShelfRenderer'},
    {ParserHelper.indexKey: 0},
    'musicShelfRenderer',
    'continuations',
    {ParserHelper.indexKey: 0},
    'nextContinuationData',
    'continuation',
  ];

  //翻页参数
  static List moreContinuation = [
    'continuationContents',
    'musicShelfContinuation',
    'continuations',
    {ParserHelper.indexKey: 0},
    'nextContinuationData',
    'continuation',
  ];

  //翻页第一页数据列表
  static List initResourceList = [
    'contents',
    'tabbedSearchResultsRenderer',
    'tabs',
    {ParserHelper.indexKey: 0},
    'tabRenderer',
    'content',
    'sectionListRenderer',
    'contents',
  ];

  //翻页更多页数据列表
  static List moreResourceList = [
    'continuationContents',
    'musicShelfContinuation',
    'contents',
  ];
}
