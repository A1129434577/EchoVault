import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:echo_vault/datebase/artist_data_operate.dart';
import 'package:echo_vault/models/artist_info.dart';
import 'package:echo_vault/utils/toast_util.dart';

class FavoriteArtistController with ChangeNotifier{
  static final StreamController<ArtistInfo> _favoriteController = StreamController.broadcast();
  static Stream<ArtistInfo> get favoriteStream => _favoriteController.stream;

  late ValueNotifier<ArtistInfo> notifier;

  late StreamSubscription _favoriteSubscription;
  FavoriteArtistController({required ArtistInfo artist}){
    notifier = ValueNotifier(artist);
    _favoriteSubscription = favoriteStream.listen((artist){
      if(artist.id == notifier.value.id){
        notifier.value.isFavorite= artist.isFavorite;
        notifier.notifyListeners();
      }
    });
  }

  void favoriteStateChange() async {
    ArtistInfo artist = notifier.value;
    artist.isFavorite ^= 1;
    if(artist.isFavorite==1){
      ToastUtil.showMessage('Added to Library.');
    }else{
      ToastUtil.showMessage('Removed from Library.');
    }
    notifier.notifyListeners();
    await ArtistDataOperate.insertArtistInfo(artist);
    _favoriteController.add(artist);
  }

  @override
  void dispose() {
    _favoriteSubscription.cancel();
    super.dispose();
  }
}