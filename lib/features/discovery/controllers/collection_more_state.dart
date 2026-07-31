import 'package:flutter/cupertino.dart';
import 'package:echo_vault/core/persistence/media_collection_repository.dart';
import 'package:echo_vault/core/networking/music_catalog_gateway.dart';
import 'package:echo_vault/core/parsing/shared_parser.dart';
import 'package:echo_vault/core/parsing/parser_helper.dart';

class CollectionMoreState with ChangeNotifier {
  final MediaCollection mediaCollection;

  //有可能是主页样式的分组，有可能是单个样式的gird
  ValueNotifier<List<MediaCollection>> resourceList = ValueNotifier([]);
  CollectionMoreState({required this.mediaCollection});

  Future queryData() async {
    Map<String, dynamic>? requestParameters = {
      'browseId': mediaCollection.id!,
      'params': mediaCollection.params,
    };
    dynamic response = await MusicCatalogGateway.post(
      resourceUrl: MusicCatalogEndpoints.detail,
      pramsArg: requestParameters,
    );
    dynamic entries = ParserHelper.parse<List>(
      response,
      SectionListParserKeys.initResourceList,
    );
    entries ??=
        ParserHelper.parse<List>(
          response,
          SectionListParserKeys.tapMoreResourceList,
        ) ??
        [];
    entries = await SharedParser.parseContents(entries);
    resourceList.value = entries;
  }
}
