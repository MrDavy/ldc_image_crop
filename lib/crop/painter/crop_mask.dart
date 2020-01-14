import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ldc_image_crop/logger.dart';

typedef OnChange = void Function(Rect crop);

class CropMask extends CustomPainter {
  Logger _logger = Logger("CropMask");

  ///裁剪宽
  double cropWidth;

  ///裁剪高
  double cropHeight;

  ///裁剪框中心坐标
  Offset center;

  ///角标大小
  double subscriptRectSize = 20;

  ///角标漏出大小
  double subscriptSize = 5;

  ///边框宽度
  double borderWidth = 4;

  ///角标修正大小，放大角标的触摸范围
  double subscriptAmendSize = 0;

  Rect ltr;
  Rect rtr;
  Rect rbr;
  Rect lbr;

  OnChange onChange;

  ///画笔
  Paint _paint;

  CropMask({
    @required this.center,
    this.cropWidth,
    this.cropHeight,
    this.borderWidth,
    this.subscriptRectSize = 0,
    this.subscriptSize = 0,
    this.subscriptAmendSize = 0,
    this.ltr,
    this.rtr,
    this.rbr,
    this.lbr,
    this.onChange,
  }) {
    assert(cropWidth != null && cropWidth > 0);
    assert(cropHeight != null && cropHeight > 0);
    _paint = Paint();
    _paint.blendMode = BlendMode.srcOver;
    _paint.isAntiAlias = true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    _paint.color = Color(0xb2000000);
//    _logger.log("paint  size = $size");
    canvas.save();

    ///背景
    Rect container = Offset.zero & size;
    canvas.saveLayer(container, _paint);
    canvas.drawRect(container, _paint);
    if (cropWidth == 0 || cropWidth > size.width) {
      cropWidth = size.width;
    }

    if (cropHeight == 0 || cropHeight > size.height) {
      cropHeight = size.height;
    }

    ///边框
    Rect rect = Rect.fromCenter(
        center: center,
        width: cropWidth + borderWidth,
        height: cropHeight + borderWidth);
    canvas.drawRect(rect, _paint..color = Colors.white);

    ///拐角
    ///左上角
    canvas.drawRect(ltr, _paint);

    ///右上角
    canvas.drawRect(rtr, _paint);

    ///右下角
    canvas.drawRect(rbr, _paint);

    ///左下角
    canvas.drawRect(lbr, _paint);

    ///裁剪部分
    rect =
        Rect.fromCenter(center: center, width: cropWidth, height: cropHeight);

    ///采用dstOut模式裁剪掉重叠的部分
    _paint.blendMode = BlendMode.dstOut;
    canvas.drawRect(rect, _paint..color = Colors.black);
    canvas.restore();
    canvas.restore();
    onChange(rect);
  }

  @override
  bool shouldRepaint(CropMask oldDelegate) {
//    _logger.log("shouldRepaint ${oldDelegate.offset}");
    return oldDelegate.center != this.center;
  }
}
