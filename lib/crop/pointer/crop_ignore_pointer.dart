import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ldc_image_crop/logger.dart';

import 'crop_render_ignore_pointer.dart';

class CropIgnorePointer extends SingleChildRenderObjectWidget {

  final List<Rect> unIgnores;

  final Offset center;

  const CropIgnorePointer({
    Key key,
    this.unIgnores,
    this.center,
    Widget child,
    this.ignoringSemantics,
  }) : super(key: key, child: child);

  final bool ignoringSemantics;

  @override
  CropRenderIgnorePointer createRenderObject(BuildContext context) {
    Logger("LIgnorePointer").log("createRenderObject");
    return CropRenderIgnorePointer(
        center: center,
        unIgnores: unIgnores,
        ignoringSemantics: ignoringSemantics);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Offset>('center', center));
    properties.add(DiagnosticsProperty<List<Rect>>('unIgnores', unIgnores));
    properties.add(
      DiagnosticsProperty<bool>(
        'ignoringSemantics',
        ignoringSemantics,
      ),
    );
  }
}
