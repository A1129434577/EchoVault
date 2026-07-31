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

  List<PerformerDetails> _initArtistList = [];
  PerformerListState({
    this.mediaCollection,
    List<PerformerDetails> performersArg = const [],
  }) {
    artistListNotifier.value = performersArg;
    _initArtistList = performersArg;
  }

  Future fetchData() async {
    Map<String, dynamic>? requestParameters = {
      'browseId': mediaCollection!.id!,
    };
    dynamic response = await MusicCatalogGateway.post(
      resourceUrl: MusicCatalogEndpoints.detail,
      pramsArg: requestParameters,
    );
    response =
        ParserHelper.parse<List>(
          response,
          SectionListParserKeys.initResourceList,
        ) ??
        [];
    List<MediaCollection> entries = await SharedParser.decodeContents(response);

    for (final mediaCollection in entries) {
      if (mediaCollection.type == MediaCollectionShowType.twoRowArtist) {
        List<PerformerDetails> entries = mediaCollection.children
            .cast<PerformerDetails>();
        entries.removeWhere((entry) {
          return _initArtistList
              .where((e1InputArg) => e1InputArg.id == entry.id)
              .isNotEmpty;
        });
        artistListNotifier.value = [..._initArtistList, ...entries];
      }
    }
  }
}
