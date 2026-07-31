import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:echo_vault/core/persistence/performer_repository.dart';
import 'package:echo_vault/core/models/performer_details.dart';
import 'package:echo_vault/core/utilities/message_overlay.dart';

class BookmarkPerformerState with ChangeNotifier {
  static final StreamController<PerformerDetails> _favoriteController =
      StreamController.broadcast();
  static Stream<PerformerDetails> get favoriteStream =>
      _favoriteController.stream;

  late ValueNotifier<PerformerDetails> notifier;

  late StreamSubscription _favoriteSubscription;
  BookmarkPerformerState({required PerformerDetails artist}) {
    notifier = ValueNotifier(artist);
    _favoriteSubscription = favoriteStream.listen((artist) {
      if (artist.id == notifier.value.id) {
        notifier.value.isFavorite = artist.isFavorite;
        notifier.notifyListeners();
      }
    });
  }

  void favoriteStateChange() async {
    PerformerDetails artist = notifier.value;
    artist.isFavorite ^= 1;
    if (artist.isFavorite == 1) {
      MessageOverlay.showMessage('Added to Library.');
    } else {
      MessageOverlay.showMessage('Removed from Library.');
    }
    notifier.notifyListeners();
    await PerformerRepository.insertArtistInfo(artist);
    _favoriteController.add(artist);
  }

  @override
  void dispose() {
    _favoriteSubscription.cancel();
    super.dispose();
  }
}
