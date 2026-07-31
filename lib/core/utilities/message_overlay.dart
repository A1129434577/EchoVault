import 'package:ad/ad.dart';
import 'package:flutter/material.dart';
import 'package:echo_vault/generated/assets.dart';

class MessageOverlay {
  static dismiss() {
    SmartDialog.dismiss();
  }

  static Future<T?> loading<T>({String? currentStatus}) {
    return SmartDialog.showLoading(
      builder: (buildContext) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha((255 * 0.85).round()),
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Color(0xFF2575FF),
                  strokeWidth: 3,
                  backgroundColor: Color(0xffF1F6FF),
                ),
              ),
              if (currentStatus != null)
                Column(
                  children: [
                    const SizedBox(height: 15),
                    Text(
                      currentStatus,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  static Future showError(String currentStatus) {
    return SmartDialog.showToast(
      '',
      builder: (buildContext) {
        return MessageOverlayView(
          icon: Assets.images.status.statusError.image(width: 24),
          status: currentStatus,
        );
      },
    );
  }

  static Future showMessage(String currentStatus) {
    return SmartDialog.showToast(
      '',
      builder: (buildContext) {
        return MessageOverlayView(status: currentStatus);
      },
    );
  }

  static Future showSuccess(String currentStatus) {
    return SmartDialog.showToast(
      '',
      builder: (buildContext) {
        return MessageOverlayView(
          icon: Assets.images.status.statusSuccess.image(width: 24),
          status: currentStatus,
        );
      },
    );
  }

  static Future showWarning(String currentStatus) {
    return SmartDialog.showToast(
      '',
      builder: (buildContext) {
        return MessageOverlayView(
          icon: Assets.images.status.statusWarning.image(width: 24),
          status: currentStatus,
        );
      },
    );
  }
}

class MessageOverlayView extends StatelessWidget {
  final Widget? icon;
  final String status;

  const MessageOverlayView({super.key, this.icon, required this.status});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 0.7,
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xff404040),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              if (icon != null) icon!,
              Flexible(
                child: Text(
                  status,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
