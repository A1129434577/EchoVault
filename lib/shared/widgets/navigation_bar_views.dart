import 'package:flutter/cupertino.dart';
import 'package:echo_vault/generated/assets.dart';

// class AppBarTitle extends StatelessWidget {
//   final String title;
//   const AppBarTitle({
//     super.key,
//     required this.title,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Text(
//       title,
//       style: TextStyle(
//         fontSize: 17,
//         color: Color(0xff1A1A1A),
//         fontWeight: FontWeight.w500,
//       ),
//     );
//   }
// }

class AppBarAction extends StatelessWidget {
  final String iconName;
  final VoidCallback? onPressed;
  const AppBarAction({super.key, required this.iconName, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      onPressed: onPressed,
      sizeStyle: CupertinoButtonSize.small,
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.centerRight,
        child: Image.asset(iconName, width: 24),
      ),
    );
  }
}

class AppBlackBackButton extends StatelessWidget {
  final String? icon;
  const AppBlackBackButton({super.key, this.icon});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      onPressed: () {
        Navigator.pop(context);
      },
      sizeStyle: CupertinoButtonSize.small,
      padding: EdgeInsets.zero,
      child: Container(
        padding: EdgeInsets.all(16),
        alignment: Alignment.centerLeft,
        child: Image.asset(
          icon ?? Assets.images.shell.navBackDark.path,
          width: 24,
        ),
      ),
    );
  }
}

class AppWhiteBackButton extends StatelessWidget {
  const AppWhiteBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child: Container(
        padding: EdgeInsets.all(16),
        alignment: Alignment.centerLeft,
        child: Assets.images.shell.navBackLight.image(width: 24),
      ),
    );
  }
}
