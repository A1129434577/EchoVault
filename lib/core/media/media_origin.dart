import 'package:player_base/enums/media_source_Interface.dart';

class MediaOrigin implements MediaSourceInterface {
  @override
  String name;

  //history
  static MediaOrigin history = MediaOrigin(name: 'history');

  //recommend
  static MediaOrigin homeReco = MediaOrigin(name: 'reco');

  static MediaOrigin homeNet = MediaOrigin(name: 'home_net');

  static MediaOrigin playlistHome = MediaOrigin(name: 'playlist_home');

  static MediaOrigin artistHome = MediaOrigin(name: 'artist_home');

  static MediaOrigin search = MediaOrigin(name: 'search');

  static List<MediaOrigin> sources = [
    history,
    homeReco,
    homeNet,
    playlistHome,
    artistHome,
    search,
  ];
  MediaOrigin({required this.name});
}
