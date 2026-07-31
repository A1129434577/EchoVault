import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/core/persistence/media_repository.dart';
import 'package:echo_vault/core/utilities/message_overlay.dart';

class BookmarkMediaState with ChangeNotifier {
  static final StreamController<FileInfo> _favoriteController =
      StreamController.broadcast();
  static Stream<FileInfo> get favoriteStream => _favoriteController.stream;

  ValueNotifier<FileInfo?> notifier = ValueNotifier(null);

  late StreamSubscription _favoriteSubscription;
  BookmarkMediaState({FileInfo? mediaDetails}) {
    notifier.value = mediaDetails;
    _favoriteSubscription = favoriteStream.listen((newFileInfo) {
      if (newFileInfo.fileId == notifier.value?.fileId) {
        notifier.value?.isFavorite = newFileInfo.isFavorite;
        notifier.notifyListeners();
      }
    });
  }

  void favoriteStateChange() async {
    if (notifier.value != null) {
      FileInfo mediaDetails = notifier.value!;
      mediaDetails.isFavorite ^= 1;
      if (mediaDetails.isFavorite == 1) {
        MessageOverlay.showMessage('Added to Library.');
      } else {
        MessageOverlay.showMessage('Removed from Library.');
      }
      notifier.notifyListeners();
      await MediaRepository.insertFileInfo(mediaDetails);
      _favoriteController.add(mediaDetails);
    }
  }

  @override
  void dispose() {
    _favoriteSubscription.cancel();
    super.dispose();
  }
}
