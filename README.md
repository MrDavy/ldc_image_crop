# ldc_image_crop
A simple flutter project for image crop

自己写的一个Flutter的图片裁剪库，半成品来着，各位看官可以自己根据自己需求定制。

介绍：
做app登陆的时候，需要用到图片裁剪功能，由于刚接触Flutter不久，所以就萌生了自己写一个的想法，说干就干！让我们站在巨人的肩膀上前进吧。

flutter中图片裁剪主要采用drawImageRect(Image image, Rect src, Rect dst, Paint paint)方法来从图片上抠图，介绍如下：

/// Draws the subset of the given image described by the `src` argument into
/// the canvas in the axis-aligned rectangle given by the `dst` argument.
///
/// This might sample from outside the `src` rect by up to half the width of
/// an applied filter.
///
/// Multiple calls to this method with different arguments (from the same
/// image) can be batched into a single call to [drawAtlas] to improve
/// performance.
void drawImageRect(Image image, Rect src, Rect dst, Paint paint) {}

知道了用drawImageRect方法抠图，就好比知道饺子要怎么包了，我们所要做的就是把饺子馅、饺子皮准备好，在这里就是要把原图image、image上抠图的位置以及绘制抠图的位置和大小确定下来。

所以裁剪分四步走：
1. 获取Image对象
2. 绘制裁剪框
3. 裁剪
4. 裁剪结果保存

一、获取Image对象：

            原图显示采用image_picker和photo_view两个库，image_picker选图片或者视频等，photo_view呈现图片并支持缩放移动旋转。当然这里的photo_view可以换成其他Widget

PhotoView(
  key: _photoKey,
  imageProvider: AssetImage("assets/images/timg.jpg"),
  maxScale: PhotoViewComputedScale.covered * 4.0,
  minScale: PhotoViewComputedScale.contained * 0.5,
  initialScale: PhotoViewComputedScale.contained * 1,
)

查看photo_view的源码发现，最终渲染出来的还是Image Widget，所以有了第一种方案：
    
RenderObject renderObject = _photoKey.currentContext.findRenderObject();
ui.Image image = findImage(renderObject);

///采用递归的方式找出Photo中的Image对象
ui.Image findImage(RenderObject child) {
  ui.Image image;
  child.visitChildren((RenderObject child) {
    if (child != null) {
      if (child is RenderImage) {
        image = child.image;
        return;
      } else {
        image = findImage(child);
      }
    } else {
      return;
    }
  });
  return image;
}

这样拿到的Image是原图片大小，这里就有个问题，由于图片的大小和图片的大小不一样，确定裁剪框的位置时取到的坐标跟图片上的坐标不一致，简单点说就是你确定的裁剪框框住的图跟剪出来的图不一致。
        
                        

                                   图1                                                                                            图2

所以我没有采用这种方案，这里如果要想裁剪到你看到的图，应该需要将图片拉伸或压缩处理（未实践），这种结果不是我想要的。

我想要的结果就是我的框框住哪就裁哪，不管你的图片是否缩放旋转移动，说句高大上的话：所见即所得！哈哈~，所以继续想，框哪裁哪？所以我是不是只需要裁剪图片再屏幕上的当前帧就好了？所以，我的Image对象取photoview在屏幕上的当前帧不就行了？说干就干，这里需要用到flutter提供的一个截屏组件RepaintBoundary：

@override
RenderRepaintBoundary createRenderObject(BuildContext context) => RenderRepaintBoundary();

class RenderRepaintBoundary extends RenderProxyBox {
    ...
/// Capture an image of the current state of this render object and its children.

/// The following is an example of how to go from a `GlobalKey` on a
/// `RepaintBoundary` to a PNG:
///
/// ```dart
/// class PngHome extends StatefulWidget {
///   PngHome({Key key}) : super(key: key);
///
///   @override
///   _PngHomeState createState() => _PngHomeState();
/// }
///
/// class _PngHomeState extends State<PngHome> {
///   GlobalKey globalKey = GlobalKey();
///
///   Future<void> _capturePng() async {
///     RenderRepaintBoundary boundary = globalKey.currentContext.findRenderObject();
///     ui.Image image = await boundary.toImage();
///     ByteData byteData = await image.toByteData(format: ui.ImageByteFormat.png);
///     Uint8List pngBytes = byteData.buffer.asUint8List();
///     print(pngBytes);
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return RepaintBoundary(
///       key: globalKey,
///       child: Center(
///         child: FlatButton(
///           child: Text('Hello World', textDirection: TextDirection.ltr),
///           onPressed: _capturePng,
///         ),
///       ),
///     );
///   }
/// }

}
RenderRepaintBoundary可以截屏获得Image对象，并提供了一个example。就它了~

第二种方案：

RepaintBoundary(
  key: _cropKey,///通过key拿到RenderRepaintBoundary对象
  child: PhotoView(///这里可以是任何其他Widget
    key: _photoKey,
    imageProvider: AssetImage("assets/images/timg.jpg"),
    maxScale: PhotoViewComputedScale.covered * 4.0,
    minScale: PhotoViewComputedScale.contained * 0.5,
    initialScale: PhotoViewComputedScale.contained * 1,
  ),
)

RenderRepaintBoundary boundary = _cropKey.currentContext.findRenderObject();
ui.Image image = await boundary.toImage(pixelRatio: ScreenUtil.pixelRatio); 

这里有个要注意的点toImage的一个参数pixelRatio，文档解释如下：
/// The returned [ui.Image] has uncompressed raw RGBA bytes in the dimensions
/// of the render object, multiplied by the [pixelRatio].
///
/// To use [toImage], the render object must have gone through the paint phase
/// (i.e. [debugNeedsPaint] must be false).
///
/// The [pixelRatio] describes the scale between the logical pixels and the
/// size of the output image. It is independent of the
/// [window.devicePixelRatio] for the device, so specifying 1.0 (the default)
/// will give you a 1:1 mapping between logical pixels and the output pixels
/// in the image.
///...
///  * [OffsetLayer.toImage] for a similar API at the layer level.
///  * [dart:ui.Scene.toImage] for more information about the image returned.
Future<ui.Image> toImage({ double pixelRatio = 1.0 }) {
  assert(!debugNeedsPaint);
  final OffsetLayer offsetLayer = layer;
  return offsetLayer.toImage(Offset.zero & size, pixelRatio: pixelRatio);
}
这里可以看出，得到的Image的中的宽高是逻辑像素，因此如果需要得到图片的真是大小就需要multiplied by the [pixelRatio]

测试：
图片大小：1080*2338
手机屏幕分辨率：1080*2248

                                           图3

从图上可以看出，我们的图片宽高等比缩放了，所以两边有黑色空隙。
pixelRatio=1 
image = [397×771]     ///截出来的图片大小，此时是图片的逻辑像素尺寸，包括了屏幕两边的黑色空隙。

pixelRatio=ScreenUtil.pixelRatio     ///ScreenUtil.pixelRatio是当前手机的像素密度，我的手机是差不多2.7
image = [1080×2118]  ///此时是图片的真实大小  

之所以要说这是因为，调用void drawImageRect(Image image, Rect src, Rect dst, Paint paint) {}需要注意Image、src、dst的宽高尺寸要是同样的pixelRatio。本人在用第一种方案测试的时候获取到的image对象中的宽高是图片的实际尺寸，也就是逻辑像素*手机当前的像素密度pixelRatio，我们通过Rect.fromCenter、Rect.fromLTWH等获取到的Rect对象中的宽高是逻辑像素单位，也就是逻辑像素*1。测试代码就不放了~。

ok，这里我们已经拿到了Image对象，饺子皮擀好了~


二、绘制裁剪框
    
        如图3，屏幕中的白色框就是我们的裁剪框，裁剪框的位置也就是我们要在图片上抠出来的区域。这里使用flutter提供的CustomPainter类的canvas绘图，采用使用BlendMode.dstOut 裁剪掉重叠的部分：



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
    canvas.save();//这里需要先save一下canvas，否则后边BlendMode.dstOut模式会把父容器也抠掉

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

    ///裁剪框
    rect =
        Rect.fromCenter(center: center, width: cropWidth, height: cropHeight);

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

使用：
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
  CropNotifier _cropCore;

  @override
  void initState() {
    super.initState();
    ///初始化裁剪框的参数
    _cropCore = CropNotifier(
      offset: Offset(0, 0),
      center:
          Offset(ScreenUtil.screenWidthDp / 2, ScreenUtil.screenHeightDp / 2),///默认取屏幕中间点为裁剪框中心
      cropWidth: width(250),
      cropHeight: width(250),
      borderWidth: width(4),
      subscriptRectSize: width(16),
      subscriptSize: width(4),
      subscriptAmendSize: width(16),//裁剪
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
          unIgnores: _cropCore.unIgnores,///
          child: Consumer<CropNotifier>(
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
  Rect _cropRect;///裁剪框，提供给外部
  Rect _cropPxRect;///裁剪框，_cropRect*pixelRatio


  set cropRect(Rect rect) {
    Logger("CropController").log(
        "rect = $rect,center = ${rect.center}, pixelRatio = ${ScreenUtil.pixelRatio}");
    _cropRect = rect;
    double pixelRatio = ScreenUtil.pixelRatio;
    _cropPxRect = Rect.fromLTRB(rect.left * pixelRatio, rect.top * pixelRatio,
        rect.right * pixelRatio, rect.bottom * pixelRatio);
    Logger("CropController")
        .log("_cropRect = $_cropRect, _cropPxRect = $_cropPxRect");
  }


  Rect get cropRect => _cropRect;


  Rect get cropPxRect => _cropPxRect;
}

///记录并计算裁剪框的数据
class CropNotifier extends ChangeNotifier {
    ...
}

这里使用GestureDetector处理触摸事件，触摸到裁剪框四个角的时候可以移动裁剪框的位置，主要通过Provider刷新数据。

///放上其他几个文件的定义，事件拦截容器，根据传入的List<Rect> 判断自己是否需要处理事件，用于裁剪框的位置移动
class CropIgnorePointer extends SingleChildRenderObjectWidget {

  final List<Rect> unIgnores;

  final Offset center;

  const CropIgnorePointer({
    Key key,
    this.unIgnores,
    this.center,
    Widget child,
  }) : super(key: key, child: child);

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
    );
  }
}


class CropRenderIgnorePointer extends RenderProxyBox {
  Logger _logger = Logger("LRenderIgnorePointer");

  CropRenderIgnorePointer({
    RenderBox child,
    Offset center,
    List<Rect> unIgnores,
  })  : _unIgnores = unIgnores,
        _center = center,
        super(child);

  Offset _center;

  Offset get center => _center;

  List<Rect> _unIgnores;

  List<Rect> get unIgnores => _unIgnores;


///在这里判断是否需要自己处理事件
  @override
  bool hitTest(BoxHitTestResult result, {Offset position}) {
    return _hitUnIgnores(position) && super.hitTest(result, position: position);
  }

///判断是否命中自定义的区域
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
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Offset>('center', _center));
    properties.add(DiagnosticsProperty<List<Rect>>('unIgnores', _unIgnores));
  }
}

ok，到这里裁剪框就算画出来了，拖动看看，这里可以根据自己的需要对框进行定制，比如圆形，圆角矩形等




三、裁剪、保存

上边我们说了裁剪用到drawImageRect(Image image, Rect src, Rect dst, Paint paint)函数，通过该函数从Image上抠出_cropPxRect所在位置和大小的图片

/// 图片裁剪
class ImageClipper extends CustomPainter {
  final ui.Image image;
  final Rect clipperRect;


  ImageClipper(this.image, this.clipperRect);


  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();
    Rect rect =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    Logger("ImageClipper").log(
        "size = $size, image = $image, container = $rect, clipperRect = $clipperRect");
    Rect targetRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, clipperRect,targetRect, paint);///从iamge中抠出clipperRect所在位置和大小的图，绘制到targetRect，也就是ImageClipper所在的容器中
  }


  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

主要裁剪代码：
Future crop() async {
///拿到待裁剪的Image
    RenderRepaintBoundary boundary = _cropKey.currentContext.findRenderObject();
    ui.Image image = await boundary.toImage(
        pixelRatio: ScreenUtil.pixelRatio); //传入pixelRatio，使用px为单位，提高图像清晰度
///    ui.Image image = findImage(_photoKey.currentContext.findRenderObject());
    dLog("image = $image");
///裁剪
    _clipper = ImageClipper(
        image, _cropController.cropPxRect); //配合上边pixelRatio传入的rect以px为单位
        setState((){});
  }

放上裁剪后的图片显示代码，这里我对图片进行了保存，用path_provider插件获取目录，其实这里拿到image后你就可以自己定制了

Widget _buildCropLayout() {
    return _clipper != null
        ? Container(
            color: Colors.black,
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              alignment: AlignmentDirectional.center,
              children: <Widget>[
                Container(
                  alignment: Alignment.center,
                  child: Hero(
                    tag: "crop",
                    child: RepaintBoundary(
                      key: _cropTargetKey,
                      child: CustomPaint(
                        size: Size(_cropController.cropRect.width,
                            _cropController.cropRect.height),
                        painter: _clipper,
                      ),
                    ),
                  ),
                ),
                Positioned(
                    bottom: height(50),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        RaisedButton(
                          onPressed: () {
//                            Navigator.pop(context);
                            _clipper = null;
                            setState(() {});
                          },
                          child: Text("取消"),
                        ),
                        SizedBox(width: width(30)),
                        RaisedButton(
                          onPressed: () async {
                            showLoading("保存中...");
                            ui.Image image =
                                await _getImageByKey(_cropTargetKey);
                            File file = await _saveImage(
                                image,
                                await getTemporaryDirectory(),
                                "ldc${DateTime.now().millisecondsSinceEpoch.toString()}.png");
//                            logger.log("file = ${file.path}");
                            hideLoading();
                            Nav.back(context, param: {"image": file});
                          },
                          child: Text("保存"),
                        )
                      ],
                    ))
              ],
            ),
          )
        : Container();
  }


///保存图片
Future<File> _saveImage(
    ui.Image image, Directory dir, String fileName) async {
  ByteData byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  File file = File(dir.path + "/" + fileName);
  file.writeAsBytes(byteData.buffer.asUint8List());
  return file;
}

///裁剪
Future<ui.Image> _getImageByKey(GlobalKey key) async {
  RenderRepaintBoundary boundary = key.currentContext.findRenderObject();
  ui.Image image = await boundary.toImage(
      pixelRatio: ScreenUtil.pixelRatio);
  return image;
}

看看效果：



ok，到此就裁剪完成了，说的可能不是很清楚，稍微看下代码就能明白了~

