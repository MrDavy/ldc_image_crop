import 'package:flutter/rendering.dart';
import 'package:ldc_image_crop/logger.dart';

class CropRenderIgnorePointer extends RenderProxyBox {
  Logger _logger = Logger("LRenderIgnorePointer");

  CropRenderIgnorePointer({
    RenderBox child,
    Offset center,
    List<Rect> unIgnores,
    bool ignoringSemantics,
  })  : _unIgnores = unIgnores,
        _center = center,
        _ignoringSemantics = ignoringSemantics,
        super(child);

  Offset _center;

  Offset get center => _center;

  List<Rect> _unIgnores;

  List<Rect> get unIgnores => _unIgnores;

  bool _ignoringSemantics;

  bool get ignoringSemantics => _ignoringSemantics;

  set ignoringSemantics(bool value) {
    if (value == _ignoringSemantics) return;
    if (_ignoringSemantics == null || !_ignoringSemantics)
      markNeedsSemanticsUpdate();
  }

  set center(Offset center) {
    this.center = center;

    if (_ignoringSemantics == null || !_ignoringSemantics)
      markNeedsSemanticsUpdate();
  }

  set unIgnores(List<Rect> unIgnores) {
    this._unIgnores = unIgnores;

    if (_ignoringSemantics == null || !_ignoringSemantics)
      markNeedsSemanticsUpdate();
  }

  @override
  bool hitTest(BoxHitTestResult result, {Offset position}) {
    return _hitUnIgnores(position) && super.hitTest(result, position: position);
  }

  bool _hitUnIgnores(Offset offset) {
    bool hitUnIgnore = false;
    if (_unIgnores?.isNotEmpty == true) {
      for (var rect in _unIgnores) {
        if (rect.contains(offset)) {
          hitUnIgnore = true;
          break;
        }
      }
    }
    return hitUnIgnore;
  }
  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    _logger.log("visitChildrenForSemantics");
    if (child != null) visitor(child);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Offset>('center', _center));
    properties.add(DiagnosticsProperty<List<Rect>>('unIgnores', _unIgnores));
    properties.add(
      DiagnosticsProperty<bool>(
        'ignoringSemantics',
        _ignoringSemantics,
      ),
    );
  }
}
