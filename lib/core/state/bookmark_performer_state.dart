import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:echo_vault/core/persistence/performer_repository.dart';
import 'package:echo_vault/core/models/performer_details.dart';
import 'package:echo_vault/core/utilities/message_overlay.dart';

class BookmarkPerformerState with ChangeNotifier {
  static final StreamController<PerformerDetails> _bookmarkEvents =
      StreamController.broadcast();

  late ValueNotifier<PerformerDetails> notifier;

  late StreamSubscription _favoriteSubscription;
  BookmarkPerformerState({required PerformerDetails artistArg}) {
    notifier = ValueNotifier(artistArg);
    _favoriteSubscription = favoriteStream.listen((artistArg) {
      if (artistArg.id == notifier.value.id) {
        notifier.value.isFavorite = artistArg.isFavorite;
        notifier.notifyListeners();
      }
    });
  }
  static Stream<PerformerDetails> get favoriteStream => _bookmarkEvents.stream;

  @override
  void dispose() {
    _favoriteSubscription.cancel();
    super.dispose();
  }

  void toggleBookmark() async {
    PerformerDetails artistLocal = notifier.value;
    artistLocal.isFavorite ^= 1;
    if (artistLocal.isFavorite == 1) {
      MessageOverlay.presentMessage('Added to Library.');
    } else {
      MessageOverlay.presentMessage('Removed from Library.');
    }
    notifier.notifyListeners();
    await PerformerRepository.addArtistInfo(artistLocal);
    _bookmarkEvents.add(artistLocal);
  }
}
