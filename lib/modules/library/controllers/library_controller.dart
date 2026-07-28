import 'package:flutter/cupertino.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/ads/ads_manager.dart';
import 'package:echo_vault/controllers/download_file_controller.dart';
import 'package:echo_vault/controllers/favorite_artist_controller.dart';
import 'package:echo_vault/controllers/favorite_file_controller.dart';
import 'package:echo_vault/controllers/favorite_group_controller.dart';
import 'package:echo_vault/datebase/artist_data_operate.dart';
import 'package:echo_vault/datebase/file_info_data_operate.dart';
import 'package:echo_vault/datebase/file_group_data_operate.dart';
import 'package:echo_vault/models/artist_info.dart';
import 'package:echo_vault/modules/artist/widgets/favorite_artist_widget.dart';
import 'package:echo_vault/modules/tab_page.dart';

class LibraryController with ChangeNotifier {
  static final LibraryController _instance = LibraryController._();
  static LibraryController get instance => _instance;
  factory LibraryController() {
    return _instance;
  }
  LibraryController._(){
    AdHelper.loadSceneAdIfNull(scene: AdsManagerScene.libraryNative, detailScene: AdsManagerDetailScene.library);
    DownloadFileController.downloadFinishAndRemoveStream.listen((fileInfo){
      if(DownloadTaskStatus.fromInt(fileInfo.downloadStatus)==DownloadTaskStatus.complete){
        isSavedNewly = true;
      }
      querySavedList();
      //收藏里面也有下载状态，所以要更新下载状态
      queryLikedList();
    });
    FavoriteFileController.favoriteStream.listen((fileInfo) async {
      await queryLikedList();
      //下载里面也有收藏状态，所以要更新收藏状态
      await querySavedList();
      if(fileInfo.isFavorite==1 && likedList.value.isNotEmpty){
        isLikedNewly = true;
      }else{
        isLikedNewly = false;
      }
    });
    FavoriteGroupController.favoriteStream.listen((fileInfo){
      queryMusicGroupList();
    });
    FavoriteArtistController.favoriteStream.listen((artistInfo) async {
      await queryArtistList();
      if(artistInfo.isFavorite==1 && artistList.value.isNotEmpty){
        isArtistNewly = true;
      }else{
        isArtistNewly = false;
      }
    });
    AdHelper.adLoadStatusStream.listen((adInfo) {
      if(adInfo.scene == AdsManagerScene.libraryNative){
        if (adInfo.loadState == AdLoadStatus.loaded) {
          libraryNatoAd.value = adInfo;
          libraryNatoAd.notifyListeners();
        }
      }
    });
    TabPage.currentTabIndex.addListener((){
      if(TabPage.currentTabIndex.value==1){
        AdHelper.loadSceneAdIfNull(scene: AdsManagerScene.libraryNative, detailScene: AdsManagerDetailScene.library);
      }
    });
  }

  final ValueNotifier<AdInfo?> libraryNatoAd = ValueNotifier(AdHelper.adSceneCacheInfo[AdsManagerScene.libraryNative]);

  ValueNotifier<List<FileInfo>> savedList = ValueNotifier([]);
  ValueNotifier<List<FileInfo>> likedList = ValueNotifier([]);
  ValueNotifier<List<ArtistInfo>> artistList = ValueNotifier([]);
  ValueNotifier<List<FileGroup>> fileGroupList = ValueNotifier([]);
  bool isSavedNewly = false;
  bool isLikedNewly = false;
  bool isArtistNewly = false;

  Future<List<FileInfo>> querySavedList() async {
    savedList.value = await FileInfoDataOperate.queryFileInfo(where: 'download_status = 3');
    return savedList.value;
  }

  Future<List<FileInfo>> queryLikedList() async {
    likedList.value = await FileInfoDataOperate.queryFileInfo(where: 'is_favorite = 1');
    return likedList.value;
  }

  Future<List<ArtistInfo>> queryArtistList() async {
    artistList.value = await ArtistDataOperate.queryArtistInfo(where: 'is_favorite = 1');
    return artistList.value;
  }

  Future<List<FileGroup>> queryMusicGroupList() async {
    fileGroupList.value = await FileGroupDataOperate.queryFileGroup();
    return fileGroupList.value;
  }

  Future addFileInfoToPlaylist(FileInfo fileInfo, FileGroup fileGroup) async {
    await FileInfoDataOperate.insertFileInfo(fileInfo);
    fileGroup.childrenIds.add(fileInfo.fileId);
    await FileGroupDataOperate.insertFileGroup(fileGroup);
    await queryMusicGroupList();
  }
}