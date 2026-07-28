import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/cupertino.dart';
import 'package:echo_vault/datebase/file_group_data_operate.dart';
import 'package:echo_vault/enums/file_source.dart';
import 'package:echo_vault/network/ytm_network.dart';
import 'package:echo_vault/parse/common_parse.dart';
import 'package:echo_vault/parse/parse_util.dart';

class FindTabResultController with ChangeNotifier{
  ValueNotifier<List> dataList = ValueNotifier([]);
  final EasyRefreshController refreshController = EasyRefreshController();

  final String keyword;
  final FileGroup fileGroup;
  FindTabResultController({
    required this.keyword,
    required this.fileGroup,
  });

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
      'params': fileGroup.params,
    };
    Map<String, dynamic>? query;
    if (continuation != null) {
      query = {'continuation': continuation};
    }
    dynamic result = await YTMNetwork.post(
      url: YTMApis.searchTabResult,
      prams: params,
      query: query,
    );

    String? newContinuation;
    if(continuation == null){
      dataList.value.clear();
      //将下一页的分页请求参数保存下来
      newContinuation = ParseUtil.parse<String>(result, FindTabResultParseKeys.initContinuation);
      _continuation = newContinuation;
      result = ParseUtil.parse<List>(result, FindTabResultParseKeys.initResourceList)??[];
      List<FileGroup> list = await CommonParse.parseContents(result, source: FileSource.search);
      dataList.value.addAll(list.firstOrNull?.children??[]);
    }else{
      newContinuation = ParseUtil.parse<String>(result, FindTabResultParseKeys.moreContinuation);
      if (newContinuation != null) {
        _continuation = newContinuation;
      }
      result = ParseUtil.parse<List>(result, FindTabResultParseKeys.moreResourceList)??[];
      List list = await CommonParse.parseChildren(result, source: FileSource.search);
      dataList.value.addAll(list);
    }

    dataList.notifyListeners();
    if (newContinuation == null) {
      return IndicatorResult.noMore;
    }
  }

}

class FindTabResultParseKeys {
  //翻页参数
  static List initContinuation = [
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
    {
      ParseUtil.filterKey: 'musicShelfRenderer',
    },
    {
      ParseUtil.indexKey: 0,
    },
    'musicShelfRenderer',
    'continuations',
    {
      ParseUtil.indexKey: 0,
    },
    'nextContinuationData',
    'continuation',
  ];

  //翻页参数
  static List moreContinuation = [
    'continuationContents',
    'musicShelfContinuation',
    'continuations',
    {
      ParseUtil.indexKey: 0,
    },
    'nextContinuationData',
    'continuation',
  ];

  //翻页第一页数据列表
  static List initResourceList = [
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

  //翻页更多页数据列表
  static List moreResourceList = [
    'continuationContents',
    'musicShelfContinuation',
    'contents',
  ];
}