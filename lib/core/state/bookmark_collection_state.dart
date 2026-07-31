import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:echo_vault/core/persistence/media_collection_repository.dart';
import 'package:echo_vault/core/utilities/message_overlay.dart';

class BookmarkCollectionState with ChangeNotifier {
  static final StreamController<MediaCollection> _favoriteController =
      StreamController.broadcast();
  static Stream<MediaCollection> get favoriteStream =>
      _favoriteController.stream;

  late ValueNotifier<MediaCollection> notifier;

  late StreamSubscription _favoriteSubscription;
  BookmarkCollectionState({required MediaCollection mediaCollection}) {
    notifier = ValueNotifier(mediaCollection);
    _favoriteSubscription = favoriteStream.listen((musicCollection) {
      if (musicCollection.id == notifier.value.id) {
        notifier.value.isFavorite = musicCollection.isFavorite;
        notifier.notifyListeners();
      }
    });
  }

  void infoChange({bool isEditName = false}) async {
    MediaCollection musicCollection = notifier.value;
    if (isEditName) {
      musicCollection.isFavorite = 1;
    } else {
      musicCollection.isFavorite ^= 1;
    }
    notifier.notifyListeners();
    if (musicCollection.isFavorite == 1) {
      MessageOverlay.showMessage('Added to Library.');
      String likeString = '"name":"${musicCollection.name}"';
      List<MediaCollection> exitList =
          await MediaCollectionRepository.queryFileGroup(
            where: 'json_content LIKE \'%$likeString%\'',
          );
      if (exitList.isNotEmpty) {
        musicCollection.displayName =
            '${musicCollection.name}(${exitList.length})';
      } else {
        musicCollection.displayName = musicCollection.name;
      }
      await MediaCollectionRepository.insertFileGroup(musicCollection);
    } else {
      MessageOverlay.showMessage('Removed from Library.');
      await MediaCollectionRepository.deleteFileGroup(musicCollection);
    }
    _favoriteController.add(musicCollection);
  }

  @override
  void dispose() {
    _favoriteSubscription.cancel();
    super.dispose();
  }
}
