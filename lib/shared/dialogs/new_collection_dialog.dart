import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/core/state/bookmark_collection_state.dart';
import 'package:echo_vault/core/persistence/media_collection_repository.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/shared/widgets/dialog_text_field.dart';
import 'package:echo_vault/shared/widgets/shared_button.dart';

class NewCollectionDialog extends StatelessWidget {
  static String routeName = '$NewCollectionDialog';
  static const String createPlaylistNamePrefix = 'via_timer';

  final MediaCollection? mediaCollection;
  const NewCollectionDialog({super.key, this.mediaCollection});

  @override
  Widget build(BuildContext context) {
    final TextEditingController textEditingControllerLocal =
        TextEditingController(text: mediaCollection?.name);

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
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      sizeStyle: CupertinoButtonSize.small,
                      padding: EdgeInsets.only(right: 5, top: 3),
                      child: Assets.images.status.dialogDismiss.image(
                        width: 20,
                      ),
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
                  DialogTextField(
                    fillColor: Color(0xFFEFEFEF),
                    borderRadius: 14,
                    contentPadding: EdgeInsetsGeometry.symmetric(
                      horizontal: 16,
                      vertical: 22,
                    ),
                    hintText: 'Please input'.translate,
                    controller: textEditingControllerLocal,
                  ),
                  SizedBox(height: 22),
                  FractionallySizedBox(
                    widthFactor: 0.65,
                    child: ValueListenableBuilder(
                      valueListenable: textEditingControllerLocal,
                      builder:
                          (
                            BuildContext context,
                            TextEditingValue value,
                            Widget? child,
                          ) {
                            return SharedButton(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              onPressed: value.text.isEmpty
                                  ? null
                                  : () {
                                      MediaCollection? newMusicGroupLocal =
                                          (mediaCollection?..name = value.text);
                                      newMusicGroupLocal ??= MediaCollection(
                                        id: '$createPlaylistNamePrefix${DateTime.now().millisecondsSinceEpoch}',
                                        name: value.text,
                                        thumbnail: Assets
                                            .images
                                            .media
                                            .albumPlaceholder
                                            .path,
                                      );
                                      BookmarkCollectionState(
                                        mediaCollectionArg: newMusicGroupLocal,
                                      ).infoChange(isEditNameArg: true);
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
      ),
    );
  }

  static Future show({MediaCollection? musicCollectionArg}) async {
    await showDialog(
      context: Get.context!,
      barrierDismissible: false,
      routeSettings: RouteSettings(name: routeName),
      builder: (buildContext) {
        return NewCollectionDialog(mediaCollection: musicCollectionArg);
      },
    );
  }
}
