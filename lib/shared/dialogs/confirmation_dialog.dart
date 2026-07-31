import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:player_base/player_base.dart';

class ConfirmationDialog extends StatelessWidget {
  final String? title;
  final String? message;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;
  final TextAlign? textAlign;

  const ConfirmationDialog({
    super.key,
    this.title,
    this.message,
    this.onCancel,
    this.onConfirm,
    this.textAlign,
  });

  static show({
    String? title,
    String? message,
    VoidCallback? onConfirm,
    String? routeName,
    TextAlign? textAlign,
  }) {
    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      routeSettings: RouteSettings(name: routeName),
      builder: (context) {
        return ConfirmationDialog(
          title: title,
          message: message,
          onConfirm: onConfirm,
          textAlign: textAlign,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Column(
                children: [
                  Text(
                    title!,
                    textAlign: textAlign,
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            if (message != null)
              Column(
                children: [
                  Text(
                    message!,
                    textAlign: textAlign,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            SizedBox(height: 14),
            SizedBox(
              height: 40,
              child: Row(
                children: [
                  Expanded(
                    child: FractionallySizedBox(
                      widthFactor: 0.8,
                      child: CupertinoButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onCancel?.call();
                        },
                        padding: EdgeInsets.zero,
                        sizeStyle: CupertinoButtonSize.small,
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(22)),
                            border: Border.all(
                              width: 2,
                              color: Color(0xff1D75FF),
                            ),
                          ),
                          child: Text(
                            'Cancel'.translate,
                            style: TextStyle(
                              color: Color(0xff1D75FF),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: FractionallySizedBox(
                      widthFactor: 0.8,
                      child: CupertinoButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onConfirm?.call();
                        },
                        padding: EdgeInsets.zero,
                        sizeStyle: CupertinoButtonSize.small,
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Color(0xff1D75FF),
                            borderRadius: BorderRadius.all(Radius.circular(22)),
                          ),
                          child: Text(
                            'Confirm'.translate,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
