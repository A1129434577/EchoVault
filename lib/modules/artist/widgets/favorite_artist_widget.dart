import 'package:flutter/cupertino.dart';
import 'package:echo_vault/controllers/favorite_artist_controller.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/models/artist_info.dart';

export 'package:echo_vault/controllers/favorite_file_controller.dart';

class FavoriteArtistWidget extends StatelessWidget {
  final ArtistInfo artist;
  final FavoriteArtistController? controller;
  final String? icon;
  final String? selectedIcon;
  const FavoriteArtistWidget({
    super.key,
    required this.artist,
    this.controller,
    this.icon,
    this.selectedIcon,
  });

  @override
  Widget build(BuildContext context) {
    FavoriteArtistController favoriteController = controller??FavoriteArtistController(artist: artist);

    return ValueListenableBuilder(
      valueListenable: favoriteController.notifier,
      builder: (BuildContext context, ArtistInfo artist, Widget? child) {
        Widget child = Image.asset(artist.isFavorite == 1
            ? (selectedIcon ?? Assets.other.favoriteActive.path)
            : (icon ?? Assets.other.favorite.path));
        if(controller==null){
          return CupertinoButton(
            onPressed: (){
              favoriteController.favoriteStateChange();
            },
            sizeStyle: CupertinoButtonSize.small,
            padding: EdgeInsets.zero,
            child: child,
          );
        }
        return child;
      },
    );
  }
}
