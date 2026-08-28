import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/shared/widgets/shared_button.dart';

enum UpdateType { close, open, force }

class UpgradeDialog extends StatelessWidget {
  static String dialogRoute = '$UpgradeDialog';
  static UpdateType _upgradeMode = UpdateType.close;

  static String releaseUrl = '';

  const UpgradeDialog({super.key});
  static set updateType(UpdateType typeArg) {
    _upgradeMode = typeArg;
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
                  _upgradeMode == UpdateType.open
                      ? 'This app no longer receives updates. Download our new app for the best experience.'
                            .translate
                      : 'This app is no longer supported. Download our new app to continue enjoying your music.'
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
                        launchUrlString(UpgradeDialog.releaseUrl);
                      },
                      title: 'Get New Music App',
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          if (_upgradeMode == UpdateType.open)
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
    if (_upgradeMode == UpdateType.close ||
        AppRouteObserver.observer.currentRouteName == dialogRoute) {
      return;
    }
    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      routeSettings: RouteSettings(name: dialogRoute),
      builder: (buildContext) {
        return UpgradeDialog();
      },
    );
  }
}
