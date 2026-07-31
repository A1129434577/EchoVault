import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:echo_vault/core/persistence/performer_repository.dart';
import 'package:echo_vault/core/models/performer_details.dart';
import 'package:echo_vault/core/utilities/message_overlay.dart';

class BookmarkPerformerState with ChangeNotifier {
  static final StreamController<PerformerDetails> _favoriteController =
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
  static Stream<PerformerDetails> get favoriteStream =>
      _favoriteController.stream;

  @override
  void dispose() {
    _favoriteSubscription.cancel();
    super.dispose();
  }

  void favoriteStateChange() async {
    PerformerDetails artistLocal = notifier.value;
    artistLocal.isFavorite ^= 1;
    if (artistLocal.isFavorite == 1) {
      MessageOverlay.showMessage('Added to Library.');
    } else {
      MessageOverlay.showMessage('Removed from Library.');
    }
    notifier.notifyListeners();
    await PerformerRepository.insertArtistInfo(artistLocal);
    _favoriteController.add(artistLocal);
  }
}
