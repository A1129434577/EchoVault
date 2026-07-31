import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/cupertino.dart';
import 'package:echo_vault/core/persistence/media_collection_repository.dart';
import 'package:echo_vault/core/media/media_origin.dart';
import 'package:echo_vault/core/networking/music_catalog_gateway.dart';
import 'package:echo_vault/core/parsing/shared_parser.dart';
import 'package:echo_vault/core/parsing/parser_helper.dart';

class SearchTabResultParserKeys {
  //翻页参数
  static List initialCursorPath = [
    'contents',
    'tabbedSearchResultsRenderer',
    'tabs',
    {ParserHelper.positionField: 0},
    'tabRenderer',
    'content',
    'sectionListRenderer',
    'contents',
    {ParserHelper.matchField: 'musicShelfRenderer'},
    {ParserHelper.positionField: 0},
    'musicShelfRenderer',
    'continuations',
    {ParserHelper.positionField: 0},
    'nextContinuationData',
    'continuation',
  ];

  //翻页参数
  static List nextCursorPath = [
    'continuationContents',
    'musicShelfContinuation',
    'continuations',
    {ParserHelper.positionField: 0},
    'nextContinuationData',
    'continuation',
  ];

  //翻页第一页数据列表
  static List initialItemsPath = [
    'contents',
    'tabbedSearchResultsRenderer',
    'tabs',
    {ParserHelper.positionField: 0},
    'tabRenderer',
    'content',
    'sectionListRenderer',
    'contents',
  ];

  //翻页更多页数据列表
  static List nextItemsPath = [
    'continuationContents',
    'musicShelfContinuation',
    'contents',
  ];
}

class SearchTabResultState with ChangeNotifier {
  ValueNotifier<List> records = ValueNotifier([]);
  final EasyRefreshController refreshController = EasyRefreshController();

  final String keyword;
  final MediaCollection mediaCollection;

  //请求更多分页的参数
  String? _continuation;
  SearchTabResultState({required this.keyword, required this.mediaCollection});
  Future fetchMoreResource() async {
    return await _fetchResource(continuationArg: _continuation);
  }

  Future reloadResource() async {
    await _fetchResource();
  }

  Future _fetchResource({String? continuationArg}) async {
    Map<String, dynamic>? requestParameters = {
      'query': keyword,
      'params': mediaCollection.params,
    };
    Map<String, dynamic>? queryLocal;
    if (continuationArg != null) {
      queryLocal = {'continuation': continuationArg};
    }
    dynamic response = await MusicCatalogGateway.post(
      resourceUrl: MusicCatalogEndpoints.filteredSearch,
      pramsArg: requestParameters,
      queryArg: queryLocal,
    );

    String? newContinuationLocal;
    if (continuationArg == null) {
      records.value.clear();
      //将下一页的分页请求参数保存下来
      newContinuationLocal = ParserHelper.parse<String>(
        response,
        SearchTabResultParserKeys.initialCursorPath,
      );
      _continuation = newContinuationLocal;
      response =
          ParserHelper.parse<List>(
            response,
            SearchTabResultParserKeys.initialItemsPath,
          ) ??
          [];
      List<MediaCollection> entries = await SharedParser.decodeContents(
        response,
        mediaOrigin: MediaOrigin.searchResults,
      );
      records.value.addAll(entries.firstOrNull?.children ?? []);
    } else {
      newContinuationLocal = ParserHelper.parse<String>(
        response,
        SearchTabResultParserKeys.nextCursorPath,
      );
      if (newContinuationLocal != null) {
        _continuation = newContinuationLocal;
      }
      response =
          ParserHelper.parse<List>(
            response,
            SearchTabResultParserKeys.nextItemsPath,
          ) ??
          [];
      List entries = await SharedParser.decodeChildren(
        response,
        mediaOrigin: MediaOrigin.searchResults,
      );
      records.value.addAll(entries);
    }

    records.notifyListeners();
    if (newContinuationLocal == null) {
      return IndicatorResult.noMore;
    }
  }
}
