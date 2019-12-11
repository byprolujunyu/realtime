import 'dart:async';

import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

List<CameraDescription> cameras;

Future<void> main() async {
  cameras = await availableCameras();
  runApp(CameraApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    //  Size size = MediaQuery.of(context).size;
    return MaterialApp(
      title: 'realtime-camera',
      home: Scaffold(
        body: CameraMain(),
      ),
    );
  }
}

class CameraMain extends StatefulWidget {
  final Size size;

  const CameraMain({Key key, this.size}) : super(key: key);

  @override
  _CameraMainState createState() => _CameraMainState();
}

class _CameraMainState extends State<CameraMain> {
  CameraController controller;

  bool ifProcess = false;
  List<Face> faces;
  double widthRate = 0;
  List<Rect> rects;
  CustomPainter painter;
  Size size;

  @override
  void initState() {
    getCamera();
    super.initState();
  }

  getCamera() async {
    try {
      controller = CameraController(
          cameras[0], ResolutionPreset.low); //controller.initialize();
      controller.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});

        controller.startImageStream((CameraImage image) async {
          if (!ifProcess) {
            final detector = FirebaseVision.instance.faceDetector();
            final versionImage = FirebaseVisionImage.fromBytes(
                image.planes[0].bytes,
                buildMetaData(
                    concatentedPlanes(image.planes), ImageRotation.rotation90));
            faces = await detector.processImage(versionImage);
            widthRate = image.width.toDouble();
            rects?.clear();
            faces.forEach((face) => rects?.add(Rect.fromLTWH(
                  face.boundingBox.left / widthRate,
                  face.boundingBox.top / widthRate,
                  face.boundingBox.width / widthRate,
                  face.boundingBox.height / widthRate,
                )));
            setState(() {
              faces = faces;
              ifProcess = false;
              rects = rects;
              widthRate = widthRate;
              painter = FacePaint(rects);
            });
          }
        });
      });
    } catch (e) {
      print(e);
    }
  }

  concatentedPlanes(List<Plane> planes) {
    WriteBuffer buffers = WriteBuffer();
    planes.forEach((plane) => buffers.putUint8List(plane.bytes));
    return buffers.done().buffer.asUint8List();
  }

  FirebaseVisionImageMetadata buildMetaData(
      CameraImage image, ImageRotation rotation) {
    return FirebaseVisionImageMetadata(
      rawFormat: image.format.raw,
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      planeData: image.planes.map((Plane plane) {
        return FirebaseVisionImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
//    if (controller == null||!controller.value.isInitialized) {
//      return Center(
//        child: CircularProgressIndicator(),
//      );
//    }
    if (!controller.value.isInitialized) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
    return Stack(
      children: <Widget>[
        AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: CameraPreview(controller),
        ),
        CustomPaint(
          painter: painter,
        ),
      ],
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}

class FacePaint extends CustomPainter {
  final List<Rect> rects;

  FacePaint(this.rects);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.red;

    for (Rect rect in rects) {
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(FacePaint oldDelegate) {
    return oldDelegate.rects != rects;
  }
}

class CameraApp extends StatefulWidget {
  @override
  _CameraAppState createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  CameraController controller;

  @override
  void initState() {
    super.initState();
    controller = CameraController(cameras[0], ResolutionPreset.medium);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container();
    }
    return MaterialApp(
      home: Scaffold(
        body: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: CameraPreview(controller)),
      ),
    );
  }
}
