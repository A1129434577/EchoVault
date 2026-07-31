import 'package:echo_vault/modules/settings/user_feedback_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/generated/assets.dart';

class RateAlert extends StatelessWidget {
  static String routeName = '$RateAlert';

  const RateAlert({super.key});

  static void show() {
    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      routeSettings: RouteSettings(name: routeName),
      builder: (context) {
        return RateAlert();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ValueNotifier<int> currentIndex = ValueNotifier(-1);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 279,
            padding: EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(36),
              gradient: LinearGradient(
                colors: [
                  Color(0xffC5DAFF),
                  Colors.white,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 95,
                  child: OverflowBox(
                    maxHeight: 140,
                    maxWidth: 140,
                    alignment: Alignment.bottomCenter,
                    child: Assets.images.feedback.ratingPanel.image( width: 140),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Enjoying our app?'.translate,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Your support is our greatest motivation for progress!'.translate,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 12),
                ValueListenableBuilder(
                  valueListenable: currentIndex,
                  builder: (BuildContext context, int value, Widget? child) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (index){
                        return IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () async {
                            currentIndex.value = index;
                            await Future.delayed(Duration(milliseconds: 300));
                            if(index>2){
                              const String url = "https://apps.apple.com/app/id6755465583?action=write-review";
                              if (await canLaunchUrlString(url)) {
                                await launchUrlString(url);
                              }
                            }else{
                              Get.off(UserFeedbackPage());
                            }
                          },
                          isSelected: index<=value,
                          icon: Assets.images.feedback.ratingStar.image( width: 28,),
                          selectedIcon: Assets.images.feedback.starActive.image( width: 28,),
                        );
                      }),
                    );
                  },
                ),
                Flexible(
                  child: Container(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: OverflowBox(
                        maxWidth: 65,
                        maxHeight: 65,
                        alignment: Alignment.topLeft,
                        child: SizedBox(
                          height: 65,
                          width: 65,
                          child: Stack(
                            children: [
                              Container(
                                height: 32,
                                width: 32,
                                padding: EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xffFFD245).withAlpha((255*0.3).round()),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xffFFD245),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 10,
                                top: 10,
                                child: Assets.images.feedback.ratingHand.image(width: 56,),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          CupertinoButton(
            onPressed: (){
              Navigator.pop(context);
            },
            sizeStyle: CupertinoButtonSize.small,
            padding: EdgeInsets.zero,
            child: Assets.images.update.updateDismiss.image(
              width: 24,
            ),
          ),
        ],
      ),
    );
  }
}