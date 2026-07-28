import 'package:player_base/enums/media_source_Interface.dart';

class FileSource implements MediaSourceInterface{
  FileSource({
    required this.name,
  });

  @override
  String name;

  //history
  static FileSource history = FileSource(name: 'history');

  //recommend
  static FileSource homeReco = FileSource(name: 'reco');

  static FileSource homeNet = FileSource(name: 'home_net');

  static FileSource playlistHome = FileSource(name: 'playlist_home');

  static FileSource artistHome = FileSource(name: 'artist_home');

  static FileSource search = FileSource(name: 'search');


  static List<FileSource> sources = [
    history,
    homeReco,
    homeNet,
    playlistHome,
    artistHome,
    search,
  ];
}