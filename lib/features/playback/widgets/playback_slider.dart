import 'dart:math';

import 'package:flutter/material.dart';

class PlaybackSlider extends StatelessWidget {
  final Duration? duration;
  final Duration? buffered;
  final Duration? position;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;
  final String? thumbImgName;
  final Size? thumbSize;
  final double? trackHeight;

  const PlaybackSlider({
    super.key,
    this.duration,
    this.buffered,
    this.position,
    this.onChangeStart,
    this.onChanged,
    this.onChangeEnd,
    this.thumbImgName,
    this.thumbSize,
    this.trackHeight,
  });

  @override
  Widget build(BuildContext context) {
    Duration newBufferedLocal = buffered ?? Duration.zero;
    Duration newDurationLocal = duration ?? Duration(seconds: 1);
    if (newBufferedLocal.inMilliseconds > newDurationLocal.inMilliseconds) {
      newBufferedLocal = newDurationLocal;
    }
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: trackHeight ?? 4,
        thumbSize: WidgetStateProperty.all(thumbSize),
        thumbShape: thumbSize != null
            ? _ThumbShape(imgName: thumbImgName, size: thumbSize!)
            : null,
        //轨道形状
        trackShape: RoundedRectSliderTrackShape(),
      ),
      child: Slider(
        max: newDurationLocal.inSeconds.toDouble(),
        value: (position ?? Duration.zero).inSeconds.toDouble(),
        secondaryTrackValue: newBufferedLocal.inSeconds.toDouble(),
        onChangeStart: onChangeStart,
        onChanged: onChanged,
        onChangeEnd: onChangeEnd,
        inactiveColor: Color(0xffE0E0E0),
        activeColor: Color(0xFF2575FF),
        secondaryActiveColor: Color(0xffA0BFEF),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class RoundedRectSliderTrackShape extends SliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeightLocal = sliderTheme.trackHeight ?? 4; // 轨道高度
    final trackLeftLocal = offset.dx;
    final trackTopLocal =
        offset.dy + (parentBox.size.height - trackHeightLocal) / 2;
    final trackWidthLocal = parentBox.size.width;
    return Rect.fromLTWH(
      trackLeftLocal,
      trackTopLocal,
      trackWidthLocal,
      trackHeightLocal,
    );
  }

  @override
  void paint(
    PaintingContext context,
    Offset i, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
  }) {
    final Canvas canvasLocal = context.canvas;
    final trackHeightLocal = sliderTheme.trackHeight ?? 4; // 轨道高度
    final trackRadiusLocal = Radius.circular(trackHeightLocal / 2); // 圆角半径
    final activeTrackColorLocal = sliderTheme.activeTrackColor ?? Colors.blue;
    final inactiveTrackColorLocal =
        sliderTheme.inactiveTrackColor ?? Colors.grey;
    final secondaryActiveTrackColorLocal =
        sliderTheme.secondaryActiveTrackColor ??
        Colors.blue.withAlpha((255 * 0.4).round());

    // 绘制未选中部分的轨道
    final inactiveRectLocal = Rect.fromLTRB(
      thumbCenter.dx,
      i.dy + (parentBox.size.height - trackHeightLocal) / 2,
      i.dx + parentBox.size.width,
      i.dy + (parentBox.size.height + trackHeightLocal) / 2,
    );
    final inactivePaintLocal = Paint()
      ..color = inactiveTrackColorLocal
      ..style = PaintingStyle.fill;
    canvasLocal.drawRRect(
      RRect.fromRectAndRadius(inactiveRectLocal, trackRadiusLocal),
      inactivePaintLocal,
    );

    // 绘制buffered部分的轨道
    final secondaryRectLocal = Rect.fromLTRB(
      i.dx,
      i.dy + (parentBox.size.height - trackHeightLocal) / 2,
      secondaryOffset?.dx ?? thumbCenter.dx,
      i.dy + (parentBox.size.height + trackHeightLocal) / 2,
    );
    final secondaryPaintLocal = Paint()
      ..color = secondaryActiveTrackColorLocal
      ..style = PaintingStyle.fill;
    canvasLocal.drawRRect(
      RRect.fromRectAndRadius(secondaryRectLocal, trackRadiusLocal),
      secondaryPaintLocal,
    );

    // 绘制选中部分的轨道
    final activeRectLocal = Rect.fromLTRB(
      i.dx,
      i.dy + (parentBox.size.height - trackHeightLocal) / 2,
      thumbCenter.dx,
      i.dy + (parentBox.size.height + trackHeightLocal) / 2,
    );
    final activePaintLocal = Paint()
      ..color = activeTrackColorLocal
      ..style = PaintingStyle.fill;
    canvasLocal.drawRRect(
      RRect.fromRectAndRadius(activeRectLocal, trackRadiusLocal),
      activePaintLocal,
    );
  }
}

class _ThumbShape extends SliderComponentShape {
  final String? imgName;
  ImageStream? imageStream;
  final Size size;
  _ThumbShape({this.imgName, required this.size}) {
    if (imgName != null) {
      imageStream = AssetImage(imgName!).resolve(ImageConfiguration.empty);
    }
  }

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return size.isEmpty
        ? size
        : Size(max(size.width, 20), max(size.height, 20)); // 设置 thumb 的大小
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvasLocal = context.canvas;

    if (imageStream != null) {
      // 加载图片
      final listenerLocal = ImageStreamListener((ImageInfo info, bool _) {
        final imageLocal = info.image;
        final srcLocal = Rect.fromLTWH(
          0,
          0,
          imageLocal.width.toDouble(),
          imageLocal.height.toDouble(),
        );
        final dstLocal = Rect.fromCenter(
          center: center,
          width: size.width,
          height: size.height,
        );
        // 绘制图片
        canvasLocal.drawImageRect(imageLocal, srcLocal, dstLocal, Paint());
      });
      imageStream?.addListener(listenerLocal);
    } else {
      Paint paintLocal = Paint();
      paintLocal.color = Color(0xff2575FF);
      canvasLocal.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center,
            width: size.width,
            height: size.height,
          ),
          Radius.circular(4),
        ),
        paintLocal,
      );
    }
  }
}
