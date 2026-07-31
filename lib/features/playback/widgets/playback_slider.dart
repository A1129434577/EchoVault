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
    Duration newBuffered = buffered ?? Duration.zero;
    Duration newDuration = duration ?? Duration(seconds: 1);
    if (newBuffered.inMilliseconds > newDuration.inMilliseconds) {
      newBuffered = newDuration;
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
        max: newDuration.inSeconds.toDouble(),
        value: (position ?? Duration.zero).inSeconds.toDouble(),
        secondaryTrackValue: newBuffered.inSeconds.toDouble(),
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
    final canvas = context.canvas;

    if (imageStream != null) {
      // 加载图片
      final listener = ImageStreamListener((ImageInfo info, bool _) {
        final image = info.image;
        final src = Rect.fromLTWH(
          0,
          0,
          image.width.toDouble(),
          image.height.toDouble(),
        );
        final dst = Rect.fromCenter(
          center: center,
          width: size.width,
          height: size.height,
        );
        // 绘制图片
        canvas.drawImageRect(image, src, dst, Paint());
      });
      imageStream?.addListener(listener);
    } else {
      Paint paint = Paint();
      paint.color = Color(0xff2575FF);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center,
            width: size.width,
            height: size.height,
          ),
          Radius.circular(4),
        ),
        paint,
      );
    }
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
    final trackHeight = sliderTheme.trackHeight ?? 4; // 轨道高度
    final trackLeft = offset.dx;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
  }) {
    final Canvas canvas = context.canvas;
    final trackHeight = sliderTheme.trackHeight ?? 4; // 轨道高度
    final trackRadius = Radius.circular(trackHeight / 2); // 圆角半径
    final activeTrackColor = sliderTheme.activeTrackColor ?? Colors.blue;
    final inactiveTrackColor = sliderTheme.inactiveTrackColor ?? Colors.grey;
    final secondaryActiveTrackColor =
        sliderTheme.secondaryActiveTrackColor ??
        Colors.blue.withAlpha((255 * 0.4).round());

    // 绘制未选中部分的轨道
    final inactiveRect = Rect.fromLTRB(
      thumbCenter.dx,
      offset.dy + (parentBox.size.height - trackHeight) / 2,
      offset.dx + parentBox.size.width,
      offset.dy + (parentBox.size.height + trackHeight) / 2,
    );
    final inactivePaint = Paint()
      ..color = inactiveTrackColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(inactiveRect, trackRadius),
      inactivePaint,
    );

    // 绘制buffered部分的轨道
    final secondaryRect = Rect.fromLTRB(
      offset.dx,
      offset.dy + (parentBox.size.height - trackHeight) / 2,
      secondaryOffset?.dx ?? thumbCenter.dx,
      offset.dy + (parentBox.size.height + trackHeight) / 2,
    );
    final secondaryPaint = Paint()
      ..color = secondaryActiveTrackColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(secondaryRect, trackRadius),
      secondaryPaint,
    );

    // 绘制选中部分的轨道
    final activeRect = Rect.fromLTRB(
      offset.dx,
      offset.dy + (parentBox.size.height - trackHeight) / 2,
      thumbCenter.dx,
      offset.dy + (parentBox.size.height + trackHeight) / 2,
    );
    final activePaint = Paint()
      ..color = activeTrackColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(activeRect, trackRadius),
      activePaint,
    );
  }
}
