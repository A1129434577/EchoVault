import 'package:player_base/enums/media_source_Interface.dart';

class MediaOrigin implements MediaSourceInterface {
  @override
  String name;

  //history
  static MediaOrigin listeningHistory = MediaOrigin(name: 'history');

  //recommend
  static MediaOrigin homeRecommendations = MediaOrigin(name: 'reco');

  static MediaOrigin onlineHome = MediaOrigin(name: 'home_net');

  static MediaOrigin collectionHome = MediaOrigin(name: 'playlist_home');

  static MediaOrigin performerHome = MediaOrigin(name: 'artist_home');

  static MediaOrigin searchResults = MediaOrigin(name: 'search');

  static List<MediaOrigin> availableSources = [
    listeningHistory,
    homeRecommendations,
    onlineHome,
    collectionHome,
    performerHome,
    searchResults,
  ];
  MediaOrigin({required this.name});
}
