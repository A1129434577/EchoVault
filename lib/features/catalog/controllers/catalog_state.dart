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
  factory CatalogState() {
    return _instance;
  }
  CatalogState._() {
    AdHelper.loadSceneAdIfNull(
      scene: AdvertisingScene.libraryNative,
      detailScene: AdvertisingDetailScene.library,
    );
    TransferMediaState.downloadFinishAndRemoveStream.listen((mediaEntry) {
      if (DownloadTaskStatus.fromInt(mediaEntry.downloadStatus) ==
          DownloadTaskStatus.complete) {
        isSavedNewly = true;
      }
      querySavedList();
      //收藏里面也有下载状态，所以要更新下载状态
      queryLikedList();
    });
    BookmarkMediaState.favoriteStream.listen((mediaEntry) async {
      await queryLikedList();
      //下载里面也有收藏状态，所以要更新收藏状态
      await querySavedList();
      if (mediaEntry.isFavorite == 1 && likedList.value.isNotEmpty) {
        isLikedNewly = true;
      } else {
        isLikedNewly = false;
      }
    });
    BookmarkCollectionState.favoriteStream.listen((mediaEntry) {
      queryMusicGroupList();
    });
    BookmarkPerformerState.favoriteStream.listen((performerProfile) async {
      await queryArtistList();
      if (performerProfile.isFavorite == 1 && performers.value.isNotEmpty) {
        isArtistNewly = true;
      } else {
        isArtistNewly = false;
      }
    });
    AdHelper.adLoadStatusStream.listen((adInfoInputArg) {
      if (adInfoInputArg.scene == AdvertisingScene.libraryNative) {
        if (adInfoInputArg.loadState == AdLoadStatus.loaded) {
          libraryNatoAd.value = adInfoInputArg;
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
  static CatalogState get instance => _instance;

  Future addFileInfoToPlaylist(
    FileInfo mediaEntry,
    MediaCollection mediaCollectionArg,
  ) async {
    await MediaRepository.insertFileInfo(mediaEntry);
    mediaCollectionArg.childrenIds.add(mediaEntry.fileId);
    await MediaCollectionRepository.insertFileGroup(mediaCollectionArg);
    await queryMusicGroupList();
  }

  Future<List<PerformerDetails>> queryArtistList() async {
    performers.value = await PerformerRepository.queryArtistInfo(
      whereArg: 'is_favorite = 1',
    );
    return performers.value;
  }

  Future<List<FileInfo>> queryLikedList() async {
    likedList.value = await MediaRepository.queryFileInfo(
      whereArg: 'is_favorite = 1',
    );
    return likedList.value;
  }

  Future<List<MediaCollection>> queryMusicGroupList() async {
    mediaCollections.value = await MediaCollectionRepository.queryFileGroup();
    return mediaCollections.value;
  }

  Future<List<FileInfo>> querySavedList() async {
    savedList.value = await MediaRepository.queryFileInfo(
      whereArg: 'download_status = 3',
    );
    return savedList.value;
  }
}
