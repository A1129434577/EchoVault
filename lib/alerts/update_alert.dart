import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/widgets/common_button.dart';


enum UpdateType{
  close,
  open,
  force,
}

class UpdateAlert extends StatelessWidget {
  static String routeName = '$UpdateAlert';
  static UpdateType _updateType = UpdateType.close;
  static set updateType(UpdateType type){
    _updateType=type;
    if(AppRouteObserver.observer.currentRouteName!='/') {
      show();
    }
  }
  static String updateLink = '';

  const UpdateAlert({super.key});

  static void show() {
    if(_updateType == UpdateType.close || AppRouteObserver.observer.currentRouteName == routeName){
      return;
    }
    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      routeSettings: RouteSettings(name: routeName),
      builder: (context) {
        return UpdateAlert();
      },
    );
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
                  image: AssetImage(Assets.otherUpdateAlertBg),
                  fit: BoxFit.fill,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset(Assets.otherUpdateAlertTitle, height: 76),
                      SizedBox(
                        width: 80,
                        height: 100,
                        child: OverflowBox(
                          maxHeight: 140,
                          maxWidth: 140,
                          alignment: Alignment.bottomCenter,
                          child: Image.asset(Assets.otherUpdateAlertIcon, height: 140),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    _updateType==UpdateType.open?
                    'The current app is no longer receiving updates. For an enhanced experience, we recommend downloading our new app.'.translate:
                    'Please note that the current app is no longer supported. Kindly download our new app to continue enjoying all music.'.translate,
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
                      child: CommonButton(
                        onPressed: (){
                          launchUrlString(UpdateAlert.updateLink);
                        },
                        title: 'Get New Music App',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            if(_updateType==UpdateType.open) CupertinoButton(
              onPressed: (){
                Navigator.pop(context);
              },
              sizeStyle: CupertinoButtonSize.small,
              padding: EdgeInsets.zero,
              child: Image.asset(
                Assets.otherUpdateClose,
                width: 24,
              ),
            ),
          ],
        ),
    );
  }
}