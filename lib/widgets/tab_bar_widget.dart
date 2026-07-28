import 'package:flutter/material.dart';

class TabBarWidget extends StatelessWidget {
  final List<String> titles;
  final TabController controller;
  final ValueChanged<int>? onTap;
  const TabBarWidget({
    super.key,
    this.titles = const [],
    required this.controller,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    ValueNotifier<int> currentIndexNotifier = ValueNotifier(controller.index);
    controller.addListener((){
      currentIndexNotifier.value = controller.index;
    });
    return ValueListenableBuilder(
      valueListenable: currentIndexNotifier,
      builder: (BuildContext context, int currentIndex, Widget? child) {
        return TabBar(
          tabs: titles.map((e) {
            int index = titles.indexOf(e);
            return Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.symmetric(horizontal: index==currentIndex?20:16, vertical: 8),
              decoration: BoxDecoration(
                color: index==currentIndex?
                Color(0xff337DFF).withAlpha((255*0.3).round()):null,
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
            color: Color(0xff141414).withAlpha((255*0.5).round()),
          ),
          labelStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xff141414),
          ),
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          dividerColor: Color(0xff141414).withAlpha((255*0.05).round()),
          labelPadding: EdgeInsets.zero,
          indicatorPadding: EdgeInsets.zero,
          indicator: CustomIndicator(),
        );
      },
    );
  }
}

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
    return _CustomBoxPainter(width: width, height: height, color: color, radius: radius);
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
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size!;
    final newOffset = Offset(offset.dx + (size.width - width) / 2, size.height - height);
    final Rect rect = newOffset & Size(width, height);
    final Paint paint = Paint();
    paint.color = color??Color(0xFF1D75FF);
    paint.style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)), // 圆角半径
      paint,
    );
  }
}
