import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ldc_image_crop/base_state.dart';
import 'package:ldc_image_crop/crop/notifiers/crop_view_draw_notifier.dart';
import 'package:ldc_image_crop/crop/painter/crop_mask.dart';
import 'package:ldc_image_crop/crop/pointer/crop_ignore_pointer.dart';
import 'package:provider/provider.dart';

///
/// 裁剪
///
class CropWidget extends StatefulWidget {
  final CropController controller;

  const CropWidget({Key key, this.controller}) : super(key: key);

  @override
  _CropWidgetState createState() => _CropWidgetState();
}

class _CropWidgetState extends BaseState<CropWidget> {
  CropDrawNotifier _cropCore;

  @override
  void initState() {
    super.initState();
    _cropCore = CropDrawNotifier(
      offset: Offset(0, 0),
      center:
          Offset(ScreenUtil.screenWidthDp / 2, ScreenUtil.screenHeightDp / 2),
      cropWidth: width(250),
      cropHeight: width(250),
      borderWidth: width(4),
      subscriptRectSize: width(16),
      subscriptSize: width(4),
      subscriptAmendSize: width(16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: _buildCropView(),
    );
  }

  Widget _buildCropView() {
    bool started = false;
    logger.log("_buildCropView");
    return GestureDetector(
      onPanDown: (details) async {
        _cropCore?.onPanDown(details);
      },
      onPanStart: (details) async {
        started = true;
        _cropCore.onPanStart(details);
      },
      onPanEnd: (details) async {
        if (started) {
          _cropCore.onPanEnd(details);
        }
      },
      onPanCancel: () async {
        _cropCore.onPanCancel();
      },
      onPanUpdate: (details) async {
        _cropCore.onPanUpdate(details);
      },
      child: ChangeNotifierProvider(
        create: (context) => _cropCore,
        child: CropIgnorePointer(
          center: _cropCore.center,
          unIgnores: _cropCore.unIgnores,
          child: Consumer<CropDrawNotifier>(
            builder: (context, _cropCore, child) {
              return Container(
                width: double.infinity,
                height: double.infinity,
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: CropMask(
                        cropWidth: _cropCore.cropWidth,
                        cropHeight: _cropCore.cropHeight,
                        borderWidth: _cropCore.borderWidth,
                        subscriptRectSize: _cropCore.subscriptRectSize,
                        subscriptSize: _cropCore.subscriptSize,
                        subscriptAmendSize: _cropCore.subscriptAmendSize,
                        center: _cropCore.center,
                        ltr: _cropCore.ltr,
                        rtr: _cropCore.rtr,
                        rbr: _cropCore.rbr,
                        lbr: _cropCore.lbr,
                        onChange: (crop) {
                          widget.controller?.cropRect = crop;
                        }),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class CropController {
  Rect _cropRect;
  Rect _cropPxRect;

  set cropRect(Rect rect) {
//    Logger("CropController").log(
//        "rect = $rect,center = ${rect.center}, pixelRatio = ${ScreenUtil.pixelRatio}");
    _cropRect = rect;
    double pixelRatio = ScreenUtil.pixelRatio;
    _cropPxRect = Rect.fromLTRB(rect.left * pixelRatio, rect.top * pixelRatio,
        rect.right * pixelRatio, rect.bottom * pixelRatio);
//    Logger("CropController")
//        .log("_cropRect = $_cropRect, _cropPxRect = $_cropPxRect");
  }

  Rect get cropRect => _cropRect;

  Rect get cropPxRect => _cropPxRect;
}
