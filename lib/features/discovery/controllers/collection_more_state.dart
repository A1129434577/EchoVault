import 'package:flutter/cupertino.dart';
import 'package:echo_vault/core/persistence/media_collection_repository.dart';
import 'package:echo_vault/core/networking/music_catalog_gateway.dart';
import 'package:echo_vault/core/parsing/shared_parser.dart';
import 'package:echo_vault/core/parsing/parser_helper.dart';

class CollectionMoreState with ChangeNotifier {
  final MediaCollection mediaCollection;
  CollectionMoreState({required this.mediaCollection});

  //有可能是主页样式的分组，有可能是单个样式的gird
  ValueNotifier<List<MediaCollection>> resourceList = ValueNotifier([]);

  Future queryData() async {
    Map<String, dynamic>? params = {
      'browseId': mediaCollection.id!,
      'params': mediaCollection.params,
    };
    dynamic result = await MusicCatalogGateway.post(
      url: MusicCatalogEndpoints.detail,
      prams: params,
    );
    dynamic list = ParserHelper.parse<List>(
      result,
      SectionListParserKeys.initResourceList,
    );
    list ??=
        ParserHelper.parse<List>(
          result,
          SectionListParserKeys.tapMoreResourceList,
        ) ??
        [];
    list = await SharedParser.parseContents(list);
    resourceList.value = list;
  }
}
