import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CommonButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final double? fontSize;
  final Widget? icon;
  final String? title;
  final bool isWhite;
  final EdgeInsetsGeometry? padding;
  const CommonButton({
    super.key,
    this.onPressed,
    this.fontSize,
    this.icon,
    this.title,
    this.isWhite=false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      onPressed: onPressed,
      sizeStyle: CupertinoButtonSize.small,
      padding: EdgeInsets.zero,
      child: Container(
        alignment: Alignment.center,
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: isWhite?Colors.white:(onPressed!=null?Color(0xFF1D75FF):Color(0xFF1D75FF).withAlpha((255*0.5).round())),
          border: Border.all(
            width: isWhite?1.5:0,
            color: (onPressed!=null?Color(0xFF1D75FF):Color(0xFF1D75FF).withAlpha((255*0.5).round())),
          ),
        ),
        child: Row(
          spacing: 12,
          mainAxisSize: MainAxisSize.min,
          children: [
            if(icon!=null) SizedBox(width: 24, child: icon!,),
            Text(
              title??'',
              style: TextStyle(
                fontSize: fontSize??14,
                fontWeight: FontWeight.w500,
                color: isWhite?(onPressed!=null?Color(0xFF1D75FF):Color(0xFF1D75FF).withAlpha((255*0.5).round())):Colors.white,
              ),
            )
          ],
        ),
      ),
    );
  }
}
