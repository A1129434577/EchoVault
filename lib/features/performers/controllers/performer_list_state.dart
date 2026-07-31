import 'package:flutter/cupertino.dart';
import 'package:echo_vault/core/persistence/media_collection_repository.dart';
import 'package:echo_vault/core/models/performer_details.dart';
import 'package:echo_vault/core/networking/music_catalog_gateway.dart';
import 'package:echo_vault/core/parsing/shared_parser.dart';
import 'package:echo_vault/core/parsing/parser_helper.dart';

class PerformerListState with ChangeNotifier {
  final MediaCollection? mediaCollection;
  final ValueNotifier<List<PerformerDetails>> artistListNotifier =
      ValueNotifier([]);
  PerformerListState({
    this.mediaCollection,
    List<PerformerDetails> performers = const [],
  }) {
    artistListNotifier.value = performers;
    _initArtistList = performers;
  }

  List<PerformerDetails> _initArtistList = [];

  Future queryData() async {
    Map<String, dynamic>? params = {'browseId': mediaCollection!.id!};
    dynamic result = await MusicCatalogGateway.post(
      url: MusicCatalogEndpoints.detail,
      prams: params,
    );
    result =
        ParserHelper.parse<List>(
          result,
          SectionListParserKeys.initResourceList,
        ) ??
        [];
    List<MediaCollection> list = await SharedParser.parseContents(result);

    for (final mediaCollection in list) {
      if (mediaCollection.type == MediaCollectionShowType.twoRowArtist) {
        List<PerformerDetails> list = mediaCollection.children
            .cast<PerformerDetails>();
        list.removeWhere((e) {
          return _initArtistList.where((e1) => e1.id == e.id).isNotEmpty;
        });
        artistListNotifier.value = [..._initArtistList, ...list];
      }
    }
  }
}
