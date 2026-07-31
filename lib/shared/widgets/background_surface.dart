import 'package:flutter/cupertino.dart';
import 'package:echo_vault/generated/assets.dart';

class BackgroundSurface extends StatelessWidget {
  final Widget child;
  final String? bg;
  const BackgroundSurface({super.key, required this.child, this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        image: DecorationImage(
          fit: BoxFit.fill,
          image: AssetImage(
            bg ?? Assets.images.shell.appBackdrop.path,
          ),
        ),
      ),
      child: child,
    );
  }
}
