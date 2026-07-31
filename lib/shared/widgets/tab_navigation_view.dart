import 'package:flutter/material.dart';

class CustomIndicator extends Decoration {
  final double width;
  final double height;
  final double radius;
  final Color? color;
  const CustomIndicator({
    this.width = 6,
    this.height = 6,
    this.radius = 3,
    this.color,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _CustomBoxPainter(
      width: width,
      height: height,
      color: color,
      radius: radius,
    );
  }
}

class TabNavigationView extends StatelessWidget {
  final List<String> titles;
  final TabController controller;
  final ValueChanged<int>? onTap;
  const TabNavigationView({
    super.key,
    this.titles = const [],
    required this.controller,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    ValueNotifier<int> currentIndexNotifierLocal = ValueNotifier(
      controller.index,
    );
    controller.addListener(() {
      currentIndexNotifierLocal.value = controller.index;
    });
    return ValueListenableBuilder(
      valueListenable: currentIndexNotifierLocal,
      builder: (BuildContext context, int currentIndex, Widget? child) {
        return TabBar(
          tabs: titles.map((e) {
            int itemIndex = titles.indexOf(e);
            return Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.symmetric(
                horizontal: itemIndex == currentIndex ? 20 : 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: itemIndex == currentIndex
                    ? Color(0xff337DFF).withAlpha((255 * 0.3).round())
                    : null,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(e),
            );
          }).toList(),
          tabAlignment: TabAlignment.start,
          padding: EdgeInsets.only(left: 12),
          isScrollable: true,
          controller: controller,
          onTap: onTap,
          unselectedLabelStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xff141414).withAlpha((255 * 0.5).round()),
          ),
          labelStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xff141414),
          ),
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          dividerColor: Color(0xff141414).withAlpha((255 * 0.05).round()),
          labelPadding: EdgeInsets.zero,
          indicatorPadding: EdgeInsets.zero,
          indicator: CustomIndicator(),
        );
      },
    );
  }
}

class _CustomBoxPainter extends BoxPainter {
  final double width;
  final double height;
  final double radius;
  final Color? color;
  const _CustomBoxPainter({
    this.width = 12,
    this.height = 3,
    this.radius = 5,
    this.color,
  });

  @override
  void paint(Canvas canvas, Offset i, ImageConfiguration configuration) {
    final sizeLocal = configuration.size!;
    final newOffsetLocal = Offset(
      i.dx + (sizeLocal.width - width) / 2,
      sizeLocal.height - height,
    );
    final Rect rectLocal = newOffsetLocal & Size(width, height);
    final Paint paintLocal = Paint();
    paintLocal.color = color ?? Color(0xFF1D75FF);
    paintLocal.style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rectLocal, Radius.circular(radius)), // 圆角半径
      paintLocal,
    );
  }
}
