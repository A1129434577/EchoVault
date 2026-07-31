import 'package:flutter/cupertino.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/core/monetization/advertising_coordinator.dart';
import 'package:echo_vault/core/state/transfer_media_state.dart';
import 'package:echo_vault/core/state/bookmark_performer_state.dart';
import 'package:echo_vault/core/state/bookmark_media_state.dart';
import 'package:echo_vault/core/state/bookmark_collection_state.dart';
import 'package:echo_vault/core/persistence/performer_repository.dart';
import 'package:echo_vault/core/persistence/media_repository.dart';
import 'package:echo_vault/core/persistence/media_collection_repository.dart';
import 'package:echo_vault/core/models/performer_details.dart';
import 'package:echo_vault/features/performers/widgets/bookmark_performer_view.dart';
import 'package:echo_vault/features/primary_navigation_screen.dart';

class CatalogState with ChangeNotifier {
  static final CatalogState _instance = CatalogState._();
  static CatalogState get instance => _instance;
  factory CatalogState() {
    return _instance;
  }
  CatalogState._() {
    AdHelper.loadSceneAdIfNull(
      scene: AdvertisingScene.libraryNative,
      detailScene: AdvertisingDetailScene.library,
    );
    TransferMediaState.downloadFinishAndRemoveStream.listen((mediaDetails) {
      if (DownloadTaskStatus.fromInt(mediaDetails.downloadStatus) ==
          DownloadTaskStatus.complete) {
        isSavedNewly = true;
      }
      querySavedList();
      //收藏里面也有下载状态，所以要更新下载状态
      queryLikedList();
    });
    BookmarkMediaState.favoriteStream.listen((mediaDetails) async {
      await queryLikedList();
      //下载里面也有收藏状态，所以要更新收藏状态
      await querySavedList();
      if (mediaDetails.isFavorite == 1 && likedList.value.isNotEmpty) {
        isLikedNewly = true;
      } else {
        isLikedNewly = false;
      }
    });
    BookmarkCollectionState.favoriteStream.listen((mediaDetails) {
      queryMusicGroupList();
    });
    BookmarkPerformerState.favoriteStream.listen((performerDetails) async {
      await queryArtistList();
      if (performerDetails.isFavorite == 1 && performers.value.isNotEmpty) {
        isArtistNewly = true;
      } else {
        isArtistNewly = false;
      }
    });
    AdHelper.adLoadStatusStream.listen((adInfo) {
      if (adInfo.scene == AdvertisingScene.libraryNative) {
        if (adInfo.loadState == AdLoadStatus.loaded) {
          libraryNatoAd.value = adInfo;
          libraryNatoAd.notifyListeners();
        }
      }
    });
    PrimaryNavigationScreen.currentTabIndex.addListener(() {
      if (PrimaryNavigationScreen.currentTabIndex.value == 1) {
        AdHelper.loadSceneAdIfNull(
          scene: AdvertisingScene.libraryNative,
          detailScene: AdvertisingDetailScene.library,
        );
      }
    });
  }

  final ValueNotifier<AdInfo?> libraryNatoAd = ValueNotifier(
    AdHelper.adSceneCacheInfo[AdvertisingScene.libraryNative],
  );

  ValueNotifier<List<FileInfo>> savedList = ValueNotifier([]);
  ValueNotifier<List<FileInfo>> likedList = ValueNotifier([]);
  ValueNotifier<List<PerformerDetails>> performers = ValueNotifier([]);
  ValueNotifier<List<MediaCollection>> mediaCollections = ValueNotifier([]);
  bool isSavedNewly = false;
  bool isLikedNewly = false;
  bool isArtistNewly = false;

  Future<List<FileInfo>> querySavedList() async {
    savedList.value = await MediaRepository.queryFileInfo(
      where: 'download_status = 3',
    );
    return savedList.value;
  }

  Future<List<FileInfo>> queryLikedList() async {
    likedList.value = await MediaRepository.queryFileInfo(
      where: 'is_favorite = 1',
    );
    return likedList.value;
  }

  Future<List<PerformerDetails>> queryArtistList() async {
    performers.value = await PerformerRepository.queryArtistInfo(
      where: 'is_favorite = 1',
    );
    return performers.value;
  }

  Future<List<MediaCollection>> queryMusicGroupList() async {
    mediaCollections.value = await MediaCollectionRepository.queryFileGroup();
    return mediaCollections.value;
  }

  Future addFileInfoToPlaylist(
    FileInfo mediaDetails,
    MediaCollection mediaCollection,
  ) async {
    await MediaRepository.insertFileInfo(mediaDetails);
    mediaCollection.childrenIds.add(mediaDetails.fileId);
    await MediaCollectionRepository.insertFileGroup(mediaCollection);
    await queryMusicGroupList();
  }
}
