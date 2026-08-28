import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/core/persistence/media_repository.dart';
import 'package:echo_vault/core/utilities/message_overlay.dart';

class BookmarkMediaState with ChangeNotifier {
  static final StreamController<FileInfo> _bookmarkEvents =
      StreamController.broadcast();

  ValueNotifier<FileInfo?> notifier = ValueNotifier(null);

  late StreamSubscription _favoriteSubscription;
  BookmarkMediaState({FileInfo? mediaEntry}) {
    notifier.value = mediaEntry;
    _favoriteSubscription = favoriteStream.listen((newFileInfoInputArg) {
      if (newFileInfoInputArg.fileId == notifier.value?.fileId) {
        notifier.value?.isFavorite = newFileInfoInputArg.isFavorite;
        notifier.notifyListeners();
      }
    });
  }
  static Stream<FileInfo> get favoriteStream => _bookmarkEvents.stream;

  @override
  void dispose() {
    _favoriteSubscription.cancel();
    super.dispose();
  }

  void toggleBookmark() async {
    if (notifier.value != null) {
      FileInfo mediaEntry = notifier.value!;
      mediaEntry.isFavorite ^= 1;
      if (mediaEntry.isFavorite == 1) {
        MessageOverlay.presentMessage('Added to favorites.'.translate);
      } else {
        MessageOverlay.presentMessage('Removed from Favorites.'.translate);
      }
      notifier.notifyListeners();
      await MediaRepository.addFileInfo(mediaEntry);
      _bookmarkEvents.add(mediaEntry);
    }
  }
}
