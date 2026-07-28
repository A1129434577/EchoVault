import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AlertInputFiled extends StatelessWidget {
  final FormFieldValidator<String>? validator;
  final FormFieldSetter<String>? onSaved;
  final int? maxLength;
  final int? maxLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final bool? enabled;
  final Color? fillColor;
  final TextStyle? style;
  final TextStyle? hintStyle;
  final BorderSide? borderSide;
  final TextEditingController? controller;
  final bool autofocus;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Color? cursorColor;
  final FocusNode? focusNode;

  final String? hintText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final BoxConstraints? prefixIconConstraints;
  final BoxConstraints? suffixIconConstraints;

  ///是否安全输入控件，如果设置成ture将自动配置一个默认的suffixIcon
  final bool secureInput;

  ///默认赋值字符
  final String? initText;

  final double? borderRadius;

  final InputBorder? enabledBorder;
  final InputBorder? errorBorder;
  final InputBorder? focusedBorder;

  final EdgeInsetsGeometry? contentPadding;

  const AlertInputFiled({
    super.key,
    this.validator,
    this.onSaved,
    this.maxLength,
    this.maxLines,
    this.onChanged,
    this.onFieldSubmitted,
    this.enabled,
    this.fillColor,
    this.style,
    this.hintStyle,
    this.borderSide,
    this.controller,
    this.autofocus = false,
    this.keyboardType,
    this.inputFormatters,
    this.cursorColor,
    this.focusNode,
    this.hintText,
    this.suffixIcon,
    this.suffixIconConstraints,
    this.prefixIcon,
    this.prefixIconConstraints,
    this.secureInput = false,
    this.initText,
    this.borderRadius,
    this.enabledBorder,
    this.errorBorder,
    this.focusedBorder,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    TextEditingController textEditingController = controller ?? TextEditingController(text: initText);
    return TextFormField(
      validator: validator,
      onSaved: onSaved,
      maxLength: maxLength,
      maxLines: maxLines,
      focusNode: focusNode,
      onChanged: onChanged,
      enabled: enabled,
      controller: textEditingController,
      autofocus: autofocus,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      cursorColor: cursorColor,
      textInputAction: TextInputAction.search,
      onFieldSubmitted: onFieldSubmitted,
      style: style?? TextStyle(
        fontSize: 14,
        color: Color(0xff141414),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        contentPadding: contentPadding??EdgeInsets.symmetric(horizontal:8, vertical: 8),
        hintText: hintText,
        counterText: '', //隐藏字数统计
        hintStyle: hintStyle?? TextStyle(
          fontSize: 12,
          color: Color(0xff141414).withAlpha((255*0.75).round()),
          fontWeight: FontWeight.w400,
        ),
        errorStyle: TextStyle(fontSize: 0),
        filled: true,
        fillColor: fillColor?? Colors.white,
        prefixIcon: prefixIcon,
        prefixIconConstraints: prefixIconConstraints,
        suffixIcon: suffixIcon,
        suffixIconConstraints: suffixIconConstraints,
        enabledBorder: enabledBorder??OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius??0),
          borderSide: borderSide??BorderSide.none,
        ),
        disabledBorder: enabledBorder??OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius??0),
          borderSide: borderSide??BorderSide.none,
        ),
        focusedBorder: focusedBorder??enabledBorder??OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius??0),
          borderSide: borderSide??BorderSide.none,
        ),
        errorBorder: errorBorder??OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius??0),
          borderSide: borderSide??BorderSide.none,
        ),
        focusedErrorBorder: errorBorder??OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius??0),
          borderSide: borderSide??BorderSide.none,
        ),
      ),
    );
  }
}