import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui' as ui;

/// 图片裁剪
class ImageClipper extends CustomPainter {
  final ui.Image image;
  final Rect clipperRect;

  ImageClipper(this.image, this.clipperRect);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();
    paint.isAntiAlias = true;
    canvas.drawImageRect(image, clipperRect,
        Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
