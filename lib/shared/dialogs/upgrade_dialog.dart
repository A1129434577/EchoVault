import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/shared/widgets/shared_button.dart';

enum UpdateType { close, open, force }

class UpgradeDialog extends StatelessWidget {
  static String routeName = '$UpgradeDialog';
  static UpdateType _updateType = UpdateType.close;

  static String updateLink = '';

  const UpgradeDialog({super.key});
  static set updateType(UpdateType typeArg) {
    _updateType = typeArg;
    if (AppRouteObserver.observer.currentRouteName != '/') {
      show();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 300,
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 22),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: Assets.images.update.updateBackdrop.provider(),
                fit: BoxFit.fill,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Assets.images.update.updateHeading.image(height: 76),
                    SizedBox(
                      width: 80,
                      height: 100,
                      child: OverflowBox(
                        maxHeight: 140,
                        maxWidth: 140,
                        alignment: Alignment.bottomCenter,
                        child: Assets.images.update.updateBadge.image(
                          height: 140,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  _updateType == UpdateType.open
                      ? 'The current app is no longer receiving updates. For an enhanced experience, we recommend downloading our new app.'
                            .translate
                      : 'Please note that the current app is no longer supported. Kindly download our new app to continue enjoying all music.'
                            .translate,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff03011A),
                  ),
                ),
                Expanded(child: SizedBox()),
                FractionallySizedBox(
                  widthFactor: 0.8,
                  child: SizedBox(
                    height: 48,
                    child: SharedButton(
                      onPressed: () {
                        launchUrlString(UpgradeDialog.updateLink);
                      },
                      title: 'Get New Music App',
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          if (_updateType == UpdateType.open)
            CupertinoButton(
              onPressed: () {
                Navigator.pop(context);
              },
              sizeStyle: CupertinoButtonSize.small,
              padding: EdgeInsets.zero,
              child: Assets.images.update.updateDismiss.image(width: 24),
            ),
        ],
      ),
    );
  }

  static void show() {
    if (_updateType == UpdateType.close ||
        AppRouteObserver.observer.currentRouteName == routeName) {
      return;
    }
    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      routeSettings: RouteSettings(name: routeName),
      builder: (buildContext) {
        return UpgradeDialog();
      },
    );
  }
}
