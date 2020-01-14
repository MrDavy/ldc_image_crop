import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ldc_image_crop/base_state.dart';
import 'package:ldc_image_crop/loading_dialog.dart';
import 'package:provider/provider.dart';

abstract class CustomState<T extends StatefulWidget> extends BaseState<T> {
  bool dialogShowing = false;
  BuildContext buildContext;
  BuildContext scaffoldContext;

  @override
  Widget build(BuildContext context) {
    buildContext = context;
    return buildWidget(context);
  }

  Widget buildWidget(BuildContext context);

  void hideLoading() {
    if (dialogShowing && Navigator.of(context).canPop()) {
      dialogShowing = Navigator.of(context).pop();
    }
  }

  showLoading(msg) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => LoadingDialog(msg: msg));
    dialogShowing = true;
  }
}
