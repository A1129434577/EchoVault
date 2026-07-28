import 'package:flutter/material.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/controllers/download_file_controller.dart';
import 'package:echo_vault/generated/assets.dart';

class SaveGuideWidget extends StatelessWidget {
  static String routeName = '$SaveGuideWidget';

  static final String _saveGuideShowedKey = '_saveGuideShowedKey';

  static show({required GlobalKey targetKey, FileInfo? fileInfo}) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    bool? saveGuideShowed = sp.getBool(_saveGuideShowedKey);
    if(saveGuideShowed == true){
      return;
    }
    sp.setBool(_saveGuideShowedKey, true);
    showDialog(
      context: Get.context!,
      useSafeArea: false,
      routeSettings: RouteSettings(name: routeName),
      builder: (context) {
        return SaveGuideWidget(targetKey: targetKey, fileInfo: fileInfo);
      },
    );
  }

  final GlobalKey targetKey;
  final FileInfo? fileInfo;
  const SaveGuideWidget({
    super.key,
    required this.targetKey,
    this.fileInfo,
  });

  @override
  Widget build(BuildContext context) {
    DownloadFileController downloadController = DownloadFileController();
    downloadController.fileInfoNotifier.value = fileInfo;

    RenderObject? targetRenderBox = targetKey.currentContext?.findRenderObject();
    Offset center = (targetRenderBox as RenderBox).localToGlobal(Offset(targetRenderBox.size.width/2, targetRenderBox.size.height/2));
    return GestureDetector(
      onTap: (){
        Navigator.pop(context);
      },
      behavior: HitTestBehavior.translucent,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Positioned(
              left: center.dx-62/2,
              top: center.dy-62/2,
              child: Container(
                height: 62,
                width: 62,
                padding: EdgeInsets.all(7),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xffB7CFFF).withAlpha((255*0.3).round()),
                ),
                child: GestureDetector(
                  onTap: (){
                    Navigator.pop(context);
                    downloadController.saveStateChange();
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xffB7CFFF),
                    ),
                    child: Image.asset(Assets.otherSaveGuide, width: 24,),
                  ),
                ),
              ),
            ),
            Positioned(
              top: center.dy-80,
              left: center.dx-4,
              width: 8,
              height: 52,
              child: Image.asset(Assets.otherSaveGuidLine),
            ),
            Positioned(
              top: center.dy-80-84,
              left: center.dx-230/2,
              width: 230,
              height: 78,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    image: DecorationImage(image: AssetImage(Assets.otherSaveGuideBg))
                ),
                child: Text(
                  'Access your favorite tracks instantly with a click here.'.translate,
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
}
