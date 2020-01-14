import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ldc_image_crop/crop/crop_widget.dart';
import 'package:ldc_image_crop/crop/painter/image_clipper.dart';
import 'package:ldc_image_crop/custom_state.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';

///
/// 图片裁剪
///
class ImageCrop extends StatefulWidget {
  final String image;

  const ImageCrop({Key key, this.image}) : super(key: key);

  @override
  _ImageCropState createState() => _ImageCropState();
}

class _ImageCropState extends CustomState<ImageCrop> {
  GlobalKey _photoKey = GlobalKey();
  GlobalKey _cropKey = GlobalKey();
  GlobalKey _cropTargetKey = GlobalKey();
  CropController _cropController;
  ImageClipper _clipper;

  @override
  void initState() {
    super.initState();
    _cropController = CropController();
    PermissionHandler()
        .checkPermissionStatus(PermissionGroup.storage)
        .then((PermissionStatus status) {
      if (status != PermissionStatus.granted) {
        PermissionHandler().requestPermissions(<PermissionGroup>[
          PermissionGroup.storage, // 在这里添加需要的权限
        ]);
      }
    });
  }

  @override
  Widget buildWidget(BuildContext context) {
    return Container(
      child: Stack(
        textDirection: TextDirection.ltr,
        fit: StackFit.expand,
        alignment: AlignmentDirectional.center,
        children: <Widget>[
          RepaintBoundary(
            key: _cropKey,

            ///这里不一定非要用PhotoView，放上你想截的内容即可
            child: PhotoView(
              key: _photoKey,
              imageProvider: FileImage(File(widget.image)),
              maxScale: PhotoViewComputedScale.covered * 4.0,
              minScale: PhotoViewComputedScale.contained * 0.5,
              initialScale: PhotoViewComputedScale.contained * 1,
            ),
          ),
          CropWidget(
            controller: _cropController,
          ),
          _buildButtonLayout(),
          _buildCropLayout(),
        ],
      ),
    );
  }

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
                            hideLoading();
                            Navigator.pop(context, {"image": file});
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

  Widget _buildButtonLayout() {
    return Positioned(
      bottom: height(50),
      child: RaisedButton(
        onPressed: () async {
          _crop();
        },
        child: Text("裁剪"),
      ),
    );
  }

  Future _crop() async {
    ui.Image image = await _getImageByKey(_cropKey);
    _clipper = ImageClipper(image, _cropController.cropPxRect);
    setState(() {});
//    return Navigator.push(
//      context,
//      PageRouteBuilder(
//          transitionDuration: const Duration(milliseconds: 50),
//          transitionsBuilder: (BuildContext context,
//              Animation<double> animation,
//              Animation<double> secondaryAnimation,
//              Widget child) {
//            return FadeTransition(opacity: animation, child: child);
//          },
//          pageBuilder: (BuildContext context, Animation<double> animation,
//              Animation<double> secondaryAnimation) {
//            return Container(
//              width: double.infinity,
//              height: double.infinity,
//              child: Stack(
//                alignment: AlignmentDirectional.center,
//                children: <Widget>[
//                  Container(
//                    alignment: Alignment.center,
//                    child: Hero(
//                      tag: "crop",
//                      child: RepaintBoundary(
//                        key: _cropTargetKey,
//                        child: CustomPaint(
//                          size: Size(_cropController.cropRect.width,
//                              _cropController.cropRect.height),
//                          painter: clipper,
//                        ),
//                      ),
//                    ),
//                  ),
//                  Positioned(
//                      bottom: height(50),
//                      child: Row(
//                        crossAxisAlignment: CrossAxisAlignment.center,
//                        mainAxisAlignment: MainAxisAlignment.center,
//                        children: <Widget>[
//                          RaisedButton(
//                            onPressed: () {
//                              Navigator.pop(context);
//                            },
//                            child: Text("取消"),
//                          ),
//                          SizedBox(width: width(20)),
//                          RaisedButton(
//                            onPressed: () async {
//                              showLoading("保存中...");
//                              ui.Image image =
//                                  await _getImageByKey(_cropTargetKey);
//                              File file = await _saveImage(
//                                  image,
//                                  await getTemporaryDirectory(),
//                                  DateTime.now()
//                                          .millisecondsSinceEpoch
//                                          .toString() +
//                                      ".png");
//                              logger.log("file = ${file.path}");
//                              hideLoading();
//                              Nav.backUntil(context, widget.from);
////                              Nav.backTo(context, Routers.login,
////                                  param: {"image": file.path});
//                            },
//                            child: Text("保存"),
//                          )
//                        ],
//                      ))
//                ],
//              ),
//            );
//          }),
//    );
  }

  Future<File> _saveImage(
      ui.Image image, Directory dir, String fileName) async {
    ByteData byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    File file = File(dir.path + "/" + fileName);
    file.writeAsBytes(byteData.buffer.asUint8List());
    return file;
  }

  Future<ui.Image> _getImageByKey(GlobalKey key) async {
    RenderRepaintBoundary boundary = key.currentContext.findRenderObject();
    ui.Image image = await boundary.toImage(
        pixelRatio: ScreenUtil.pixelRatio); //传入pixelRatio，使用px为单位，提高图像清晰度
    return image;
  }
}
