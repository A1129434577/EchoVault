import 'package:flutter/material.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/core/state/transfer_media_state.dart';
import 'package:echo_vault/generated/assets.dart';

class SaveGuideView extends StatelessWidget {
  static String routeName = '$SaveGuideView';

  static final String _saveGuideShowedKey = '_saveGuideShowedKey';

  final GlobalKey targetKey;
  final FileInfo? mediaDetails;
  const SaveGuideView({super.key, required this.targetKey, this.mediaDetails});

  @override
  Widget build(BuildContext context) {
    TransferMediaState downloadControllerLocal = TransferMediaState();
    downloadControllerLocal.fileInfoNotifier.value = mediaDetails;

    RenderObject? targetRenderBoxLocal = targetKey.currentContext
        ?.findRenderObject();
    Offset centerLocal = (targetRenderBoxLocal as RenderBox).localToGlobal(
      Offset(
        targetRenderBoxLocal.size.width / 2,
        targetRenderBoxLocal.size.height / 2,
      ),
    );
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      behavior: HitTestBehavior.translucent,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Positioned(
              left: centerLocal.dx - 62 / 2,
              top: centerLocal.dy - 62 / 2,
              child: Container(
                height: 62,
                width: 62,
                padding: EdgeInsets.all(7),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xffB7CFFF).withAlpha((255 * 0.3).round()),
                ),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    downloadControllerLocal.saveStateChange();
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xffB7CFFF),
                    ),
                    child: Assets.images.collection.saveHelp.image(width: 24),
                  ),
                ),
              ),
            ),
            Positioned(
              top: centerLocal.dy - 80,
              left: centerLocal.dx - 4,
              width: 8,
              height: 52,
              child: Assets.images.collection.saveGuideLine.image(),
            ),
            Positioned(
              top: centerLocal.dy - 80 - 84,
              left: centerLocal.dx - 230 / 2,
              width: 230,
              height: 78,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: Assets.images.collection.saveGuideBackdrop
                        .provider(),
                  ),
                ),
                child: Text(
                  'Access your favorite tracks instantly with a click here.'
                      .translate,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static show({required GlobalKey targetKeyArg, FileInfo? mediaEntry}) async {
    SharedPreferences spLocal = await SharedPreferences.getInstance();
    bool? saveGuideShowedValueLocal = spLocal.getBool(_saveGuideShowedKey);
    if (saveGuideShowedValueLocal == true) {
      return;
    }
    spLocal.setBool(_saveGuideShowedKey, true);
    showDialog(
      context: Get.context!,
      useSafeArea: false,
      routeSettings: RouteSettings(name: routeName),
      builder: (buildContext) {
        return SaveGuideView(targetKey: targetKeyArg, mediaDetails: mediaEntry);
      },
    );
  }
}
