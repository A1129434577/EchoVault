import 'package:flutter/cupertino.dart';

class SheetBgWidget extends StatelessWidget {
  final Widget child;
  const SheetBgWidget({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          gradient: LinearGradient(
            colors: [
              Color(0xffDFEBF7),
              Color(0xffFAFAFA),
              Color(0xffFAFAFA),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
      ),
      child: child,
    );
  }
}
