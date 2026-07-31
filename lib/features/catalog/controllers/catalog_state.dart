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
  static final CatalogState _sharedState = CatalogState._();

  final ValueNotifier<AdInfo?> libraryNatoAd = ValueNotifier(
    AdHelper.adSceneCacheInfo[AdvertisingScene.libraryFeedNative],
  );

  ValueNotifier<List<FileInfo>> savedList = ValueNotifier([]);
  ValueNotifier<List<FileInfo>> likedList = ValueNotifier([]);
  ValueNotifier<List<PerformerDetails>> performers = ValueNotifier([]);
  ValueNotifier<List<MediaCollection>> mediaCollections = ValueNotifier([]);
  bool isSavedNewly = false;
  bool isLikedNewly = false;
  bool isArtistNewly = false;
  factory CatalogState() {
    return _sharedState;
  }
  CatalogState._() {
    AdHelper.loadSceneAdIfNull(
      scene: AdvertisingScene.libraryFeedNative,
      detailScene: AdvertisingDetailScene.mediaLibrary,
    );
    TransferMediaState.downloadFinishAndRemoveStream.listen((mediaEntry) {
      if (DownloadTaskStatus.fromInt(mediaEntry.downloadStatus) ==
          DownloadTaskStatus.complete) {
        isSavedNewly = true;
      }
      fetchSavedList();
      //收藏里面也有下载状态，所以要更新下载状态
      fetchLikedList();
    });
    BookmarkMediaState.favoriteStream.listen((mediaEntry) async {
      await fetchLikedList();
      //下载里面也有收藏状态，所以要更新收藏状态
      await fetchSavedList();
      if (mediaEntry.isFavorite == 1 && likedList.value.isNotEmpty) {
        isLikedNewly = true;
      } else {
        isLikedNewly = false;
      }
    });
    BookmarkCollectionState.favoriteStream.listen((mediaEntry) {
      fetchMusicGroupList();
    });
    BookmarkPerformerState.favoriteStream.listen((performerProfile) async {
      await fetchArtistList();
      if (performerProfile.isFavorite == 1 && performers.value.isNotEmpty) {
        isArtistNewly = true;
      } else {
        isArtistNewly = false;
      }
    });
    AdHelper.adLoadStatusStream.listen((adInfoInputArg) {
      if (adInfoInputArg.scene == AdvertisingScene.libraryFeedNative) {
        if (adInfoInputArg.loadState == AdLoadStatus.loaded) {
          libraryNatoAd.value = adInfoInputArg;
          libraryNatoAd.notifyListeners();
        }
      }
    });
    PrimaryNavigationScreen.selectedSection.addListener(() {
      if (PrimaryNavigationScreen.selectedSection.value == 1) {
        AdHelper.loadSceneAdIfNull(
          scene: AdvertisingScene.libraryFeedNative,
          detailScene: AdvertisingDetailScene.mediaLibrary,
        );
      }
    });
  }
  static CatalogState get instance => _sharedState;

  Future addFileInfoToPlaylist(
    FileInfo mediaEntry,
    MediaCollection mediaCollectionArg,
  ) async {
    await MediaRepository.addFileInfo(mediaEntry);
    mediaCollectionArg.childrenIds.add(mediaEntry.fileId);
    await MediaCollectionRepository.addFileGroup(mediaCollectionArg);
    await fetchMusicGroupList();
  }

  Future<List<PerformerDetails>> fetchArtistList() async {
    performers.value = await PerformerRepository.fetchArtistInfo(
      whereArg: 'is_favorite = 1',
    );
    return performers.value;
  }

  Future<List<FileInfo>> fetchLikedList() async {
    likedList.value = await MediaRepository.fetchFileInfo(
      whereArg: 'is_favorite = 1',
    );
    return likedList.value;
  }

  Future<List<MediaCollection>> fetchMusicGroupList() async {
    mediaCollections.value = await MediaCollectionRepository.fetchFileGroup();
    return mediaCollections.value;
  }

  Future<List<FileInfo>> fetchSavedList() async {
    savedList.value = await MediaRepository.fetchFileInfo(
      whereArg: 'download_status = 3',
    );
    return savedList.value;
  }
}
