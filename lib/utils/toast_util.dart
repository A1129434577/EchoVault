import 'package:ad/ad.dart';
import 'package:flutter/material.dart';
import 'package:echo_vault/generated/assets.dart';

class ToastUtil {
  static Future<T?> loading<T>({String? status}) {
    return SmartDialog.showLoading(
      builder:(context){
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha((255*0.85).round()),
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
              if (status != null)
                Column(
                  children: [
                    const SizedBox(height: 15),
                    Text(
                      status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  ],
                )
            ],
          ),
        );
      },
    );
  }

  static dismiss() {
    SmartDialog.dismiss();
  }

  static Future showMessage(String status) {
    return SmartDialog.showToast(
      '',
      builder: (context){
        return ToastWidget(status: status);
      },
    );
  }

  static Future showSuccess(String status) {
    return SmartDialog.showToast(
      '',
      builder: (context){
        return ToastWidget(
          icon: Image.asset(Assets.assetsSuccess, width: 24),
          status: status,
        );
      },
    );
  }

  static Future showError(String status) {
    return SmartDialog.showToast(
      '',
      builder: (context){
        return ToastWidget(
          icon: Image.asset(Assets.assetsFail, width: 24),
          status: status,
        );
      },
    );
  }

  static Future showWarning(String status) {
    return SmartDialog.showToast(
      '',
      builder: (context){
        return ToastWidget(
          icon: Image.asset(Assets.assetsWarning, width: 24),
          status: status,
        );
      },
    );
  }
}

class ToastWidget extends StatelessWidget {
  final Widget? icon;
  final String status;

  const ToastWidget({
    super.key,
    this.icon,
    required this.status,
  });

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