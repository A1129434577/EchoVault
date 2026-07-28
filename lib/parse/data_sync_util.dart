import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/datebase/artist_data_operate.dart';
import 'package:echo_vault/datebase/file_group_data_operate.dart';
import 'package:echo_vault/datebase/file_info_data_operate.dart';
import 'package:echo_vault/models/artist_info.dart';

class DataSyncUtil {
  static Future<FileInfo> syncFileInfo(FileInfo fileInfo) async {
    FileInfo? cacheFileInfo =  await FileInfoDataOperate.queryFileInfoFromId(fileInfo.fileId);
    if(cacheFileInfo != null){
      fileInfo.url = cacheFileInfo.url;
      fileInfo.uid = cacheFileInfo.uid;
      fileInfo.userName = cacheFileInfo.userName;
      fileInfo.downloadTaskId = cacheFileInfo.downloadTaskId;
      fileInfo.downloadStatus = cacheFileInfo.downloadStatus;
      fileInfo.isFavorite = cacheFileInfo.isFavorite;
      fileInfo.duration = cacheFileInfo.duration;
    }
    return fileInfo;
  }

  static Future<ArtistInfo> syncArtist(ArtistInfo artist) async {
    ArtistInfo? cacheArtist;
    if(artist.id != null){
      cacheArtist = await ArtistDataOperate.queryArtistInfoFromId(artist.id!);
    }
    if(cacheArtist != null){
      artist.isFavorite = cacheArtist.isFavorite;
    }
    return artist;
  }

  static Future<FileGroup> syncFileGroup(FileGroup fileGroup) async {
    FileGroup? cacheFileGroup = await FileGroupDataOperate.queryFileGroupFromId(fileGroup.id);
    if(cacheFileGroup != null){
      fileGroup.isFavorite = cacheFileGroup.isFavorite;
    }
    return fileGroup;
  }
}