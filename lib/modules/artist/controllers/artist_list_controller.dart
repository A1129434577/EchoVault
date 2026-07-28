import 'package:flutter/cupertino.dart';
import 'package:echo_vault/datebase/file_group_data_operate.dart';
import 'package:echo_vault/models/artist_info.dart';
import 'package:echo_vault/network/ytm_network.dart';
import 'package:echo_vault/parse/common_parse.dart';
import 'package:echo_vault/parse/parse_util.dart';

class ArtistListController with ChangeNotifier {
  final FileGroup? fileGroup;
  final ValueNotifier<List<ArtistInfo>> artistListNotifier = ValueNotifier([]);
  ArtistListController({
    this.fileGroup,
    List<ArtistInfo> artistList = const [],
  }){
    artistListNotifier.value = artistList;
    _initArtistList = artistList;
  }

  List<ArtistInfo> _initArtistList = [];

  Future queryData() async {
    Map<String, dynamic>? params = {'browseId': fileGroup!.id!};
    dynamic result = await YTMNetwork.post(
      url: YTMApis.detail,
      prams: params,
    );
    result = ParseUtil.parse<List>(result, SectionListParseKeys.initResourceList)??[];
    List<FileGroup> list = await CommonParse.parseContents(result);

    for(final fileGroup in list){
      if(fileGroup.type == FileGroupShowType.twoRowArtist){
        List<ArtistInfo> list = fileGroup.children.cast<ArtistInfo>();
        list.removeWhere((e){
          return _initArtistList.where((e1)=>e1.id==e.id).isNotEmpty;
        });
        artistListNotifier.value = [..._initArtistList, ...list];
      }
    }
  }

}