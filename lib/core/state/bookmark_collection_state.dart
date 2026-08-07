import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:echo_vault/core/persistence/media_collection_repository.dart';
import 'package:echo_vault/core/utilities/message_overlay.dart';

class BookmarkCollectionState with ChangeNotifier {
  static final StreamController<MediaCollection> _bookmarkEvents =
      StreamController.broadcast();

  late ValueNotifier<MediaCollection> notifier;

  late StreamSubscription _favoriteSubscription;
  BookmarkCollectionState({required MediaCollection mediaCollectionArg}) {
    notifier = ValueNotifier(mediaCollectionArg);
    _favoriteSubscription = favoriteStream.listen((musicCollectionArg) {
      if (musicCollectionArg.id == notifier.value.id) {
        notifier.value.isFavorite = musicCollectionArg.isFavorite;
        notifier.notifyListeners();
      }
    });
  }
  static Stream<MediaCollection> get favoriteStream => _bookmarkEvents.stream;

  @override
  void dispose() {
    _favoriteSubscription.cancel();
    super.dispose();
  }

  void updateCollection({bool isEditNameArg = false}) async {
    MediaCollection musicCollectionLocal = notifier.value;
    if (isEditNameArg) {
      musicCollectionLocal.isFavorite = 1;
    } else {
      musicCollectionLocal.isFavorite ^= 1;
    }
    notifier.notifyListeners();
    if (musicCollectionLocal.isFavorite == 1) {
      MessageOverlay.presentMessage('Added to Library.');
      try{
        String likeStringLocal = '"name":"${musicCollectionLocal.name}"';
        List<MediaCollection> exitListLocal =
        await MediaCollectionRepository.fetchFileGroup(
          whereArg: 'json_content LIKE \'%$likeStringLocal%\'',
        );
        if (exitListLocal.isNotEmpty) {
          musicCollectionLocal.displayName =
          '${musicCollectionLocal.name}(${exitListLocal.length})';
        } else {
          musicCollectionLocal.displayName = musicCollectionLocal.name;
        }
      }catch(_){}
      await MediaCollectionRepository.addFileGroup(musicCollectionLocal);
    } else {
      MessageOverlay.presentMessage('Removed from Library.');
      await MediaCollectionRepository.removeFileGroup(musicCollectionLocal);
    }
    _bookmarkEvents.add(musicCollectionLocal);
  }
}
