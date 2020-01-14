import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ldc_image_crop/logger.dart';

class CropCore {
  Logger logger = Logger("CropCore");

  double cropWidth;
  double cropHeight;
  double containerWidth;
  double containerHeight;
  double borderWidth;
  double subscriptRectSize;
  double subscriptSize;
  double subscriptAmendSize;

  Rect container;
  Rect ltr;
  Rect rtr;
  Rect rbr;
  Rect lbr;

  Rect ltTapBox;
  Rect rtTapBox;
  Rect rbTapBox;
  Rect lbTapBox;

  List<Rect> _unIgnores = List();

  List<Rect> get unIgnores => _unIgnores;

  Offset center;

  Offset offset;

  bool _started = false;

  CropCore(
      {@required this.center,
      offset = const Offset(0, 0),
      this.cropWidth = 200,
      this.cropHeight = 200,
      this.borderWidth = 4,
      this.subscriptRectSize = 16,
      this.subscriptSize = 4,
      this.subscriptAmendSize = 8})
      : assert(center != null) {
    calc();
  }

  calc() {
    _unIgnores.clear();
    changeCropRect();
    _createLtSubscript();
    _createRtSubscript();
    _createRbSubscript();
    _createLbSubscript();
  }

  void onPanDown(DragDownDetails details) {
//    logger.log(
//        "onPanDown localPosition = ${details.localPosition}，globalPosition = ${details.globalPosition}");
  }

  void onPanStart(DragStartDetails details) {
//    logger.log(
//        "onPanStart localPosition = ${details.localPosition}，globalPosition = ${details.globalPosition}");
    _started = true;
  }

  void onPanUpdate(DragUpdateDetails details) {
//    logger.log(
//        "onPanUpdate delta = ${details.delta}, localPosition = ${details.localPosition}，globalPosition = ${details.globalPosition}");
    center += details.delta;
    if (center.dx - cropWidth / 2 < 0) {
      center = Offset(cropWidth / 2, center.dy);
    } else if (center.dx + cropWidth / 2 > ScreenUtil.screenWidthDp) {
      center = Offset(ScreenUtil.screenWidthDp - cropWidth / 2, center.dy);
    }

    if (center.dy - cropHeight / 2 < 0) {
      center = Offset(center.dx, cropHeight / 2);
    } else if (center.dy + cropHeight / 2 > ScreenUtil.screenHeightDp) {
      center = Offset(center.dx, ScreenUtil.screenHeightDp - cropHeight / 2);
    }
    calc();
  }

  void onPanCancel() {
//    logger.log("onPanCancel");
  }

  void onPanEnd(DragEndDetails details) {
//    logger.log('onPanEnd');
    if (_started) {}
    _started = false;
  }

  void onChange(
      Offset center, double size, Rect lt, Rect rt, Rect rb, Rect lb) {}

  void changeCropRect() {}

  _createLbSubscript() {
    Offset lbOffset = Offset(
        center.dx - cropWidth / 2 + subscriptRectSize / 2 - subscriptSize,
        center.dy + cropHeight / 2 - subscriptRectSize / 2 + subscriptSize);
    lbr = Rect.fromCenter(
        center: lbOffset, width: subscriptRectSize, height: subscriptRectSize);
    lbTapBox = Rect.fromCenter(
        center: Offset(lbr.left, lbr.bottom),
        width: subscriptRectSize + subscriptAmendSize,
        height: subscriptRectSize + subscriptAmendSize);
    _unIgnores.add(lbTapBox);
  }

  _createRbSubscript() {
    Offset rbOffset = Offset(
        center.dx + cropWidth / 2 - subscriptRectSize / 2 + subscriptSize,
        center.dy + cropHeight / 2 - subscriptRectSize / 2 + subscriptSize);
    rbr = Rect.fromCenter(
        center: rbOffset, width: subscriptRectSize, height: subscriptRectSize);
    rbTapBox = Rect.fromCenter(
        center: Offset(rbr.right, rbr.bottom),
        width: subscriptRectSize + subscriptAmendSize,
        height: subscriptRectSize + subscriptAmendSize);
    _unIgnores.add(rbTapBox);
  }

  _createRtSubscript() {
    Offset rtOffset = Offset(
        center.dx + cropWidth / 2 - subscriptRectSize / 2 + subscriptSize,
        center.dy - cropHeight / 2 + subscriptRectSize / 2 - subscriptSize);
    rtr = Rect.fromCenter(
        center: rtOffset, width: subscriptRectSize, height: subscriptRectSize);
    rtTapBox = Rect.fromCenter(
        center: Offset(rtr.right, rtr.top),
        width: subscriptRectSize + subscriptAmendSize,
        height: subscriptRectSize + subscriptAmendSize);
    _unIgnores.add(rtTapBox);
  }

  _createLtSubscript() {
    Offset ltOffset = Offset(
        center.dx - cropWidth / 2 + subscriptRectSize / 2 - subscriptSize,
        center.dy - cropHeight / 2 + subscriptRectSize / 2 - subscriptSize);
    ltr = Rect.fromCenter(
        center: ltOffset, width: subscriptRectSize, height: subscriptRectSize);
    ltTapBox = Rect.fromCenter(
        center: Offset(ltr.left, ltr.top),
        width: subscriptRectSize + subscriptAmendSize,
        height: subscriptRectSize + subscriptAmendSize);
    _unIgnores.add(ltTapBox);
  }
}
