import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/controllers/favorite_group_controller.dart';
import 'package:echo_vault/datebase/file_group_data_operate.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/widgets/alert_input_filed.dart';
import 'package:echo_vault/widgets/common_button.dart';


class CreatePlaylistAlert extends StatelessWidget {
  static String routeName = '$CreatePlaylistAlert';
  static const String createPlaylistNamePrefix = 'via_timer';

  final FileGroup? fileGroup;
  const CreatePlaylistAlert({
    super.key,
    this.fileGroup,
  });

  static Future show({
    FileGroup? musicGroup,
  }) async {
    await showDialog(
      context: Get.context!,
      barrierDismissible: false,
      routeSettings: RouteSettings(name: routeName),
      builder: (context) {
        return CreatePlaylistAlert(fileGroup: musicGroup);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController textEditingController = TextEditingController(text: fileGroup?.name);

    return Dialog(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.only(left: 16),
                height: 45,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        'Create playlist'.translate,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Container(
                      alignment: Alignment.topRight,
                      child: CupertinoButton(
                        onPressed: (){
                          Navigator.pop(context);
                        },
                        sizeStyle: CupertinoButtonSize.small,
                        padding: EdgeInsets.only(right: 5, top: 3),
                        child: Assets.dialogDismiss.image( width: 20),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsetsGeometry.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    AlertInputFiled(
                      fillColor: Color(0xFFEFEFEF),
                      borderRadius: 14,
                      contentPadding: EdgeInsetsGeometry.symmetric(horizontal: 16, vertical: 22),
                      hintText: 'Please input'.translate,
                      controller: textEditingController,
                    ),
                    SizedBox(height: 22),
                    FractionallySizedBox(
                      widthFactor: 0.65,
                      child: ValueListenableBuilder(
                        valueListenable: textEditingController,
                        builder: (BuildContext context, TextEditingValue value, Widget? child) {
                          return CommonButton(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            onPressed: value.text.isEmpty?
                            null:() {
                              FileGroup? newMusicGroup = (fileGroup?..name = value.text);
                              newMusicGroup ??= FileGroup(
                                id: '$createPlaylistNamePrefix${DateTime.now().millisecondsSinceEpoch}',
                                name: value.text,
                                thumbnail: Assets.other.albumPlaceholder.path,
                              );
                              FavoriteGroupController(fileGroup: newMusicGroup).infoChange(isEditName: true);
                              Navigator.pop(context);
                            },
                            title: 'Save'.translate,
                          );
                        },

                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        )
    );
  }
}
