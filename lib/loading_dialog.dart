import 'dart:ffi';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/*
 * 加载动画
 */
class LoadingDialog extends Dialog {
  final String msg;

  LoadingDialog({Key key, this.msg}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: SizedBox(
          width: 100,
          height: 100,
          child: Container(
            decoration: ShapeDecoration(
                color: Color(0x7f000000),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(
                        ScreenUtil.getInstance().setWidth(8))))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                CircularProgressIndicator(
                  strokeWidth: 2,
                ),
                Padding(
                  padding: EdgeInsets.only(
                      top: ScreenUtil.getInstance().setHeight(12)),
                  child: Text(
                    msg,
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: ScreenUtil.getInstance().setSp(12)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
