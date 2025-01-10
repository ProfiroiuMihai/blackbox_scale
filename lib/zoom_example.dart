import 'dart:io';
import 'package:blackbox_scale/method_channel_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class ZoomExample extends StatefulWidget {
  const ZoomExample({super.key});

  @override
  State<ZoomExample> createState() => _ZoomExampleState();
}

class _ZoomExampleState extends State<ZoomExample> {
  final TransformationController _controller = TransformationController();
  double height = 0.0;
  double width = 0.0;
  var containerHeight = 300.0;
  var containerWidth = 400.0;
  var imageAspectRatio = 1000/1500;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTransformationChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTransformationChange);
    _controller.dispose();
    super.dispose();
  }

  void _onTransformationChange() {
    setState(() {});
  }

  Offset getTranslationFromMatrix() {
    final matrix = _controller.value;
    return Offset(matrix.storage[12], matrix.storage[13]);
  }

  Future<void> applyTransformation() async {
    try {
      final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
      final scale = _controller.value.getMaxScaleOnAxis();

   
      final data = await rootBundle.load('assets/fashion_02_background.jpg');
      final List<int> bytes = data.buffer.asUint8List();
      final tempPath = await getTemporaryDirectory();
      final tempFilename = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final tempFile = File('${tempPath.path}/$tempFilename');

      await tempFile.writeAsBytes(bytes);

      await MethodChannelHelper().testTransform(
        height: containerHeight/devicePixelRatio,
        width: containerWidth/devicePixelRatio,
        scale: scale,
        dx: flutterToIos(scale, getTranslationFromMatrix().dx, getTranslationFromMatrix().dy, width, height,).dx,
        dy: flutterToIos(scale, getTranslationFromMatrix().dx, getTranslationFromMatrix().dy, width, height, ).dy,
        imagePath: tempFile.path,
      );
    } catch (error, stackTrace) {
      print('Error in applyTransformation: $error');
      print('Stack trace: $stackTrace');
    }
  }

  Offset flutterToIos(
      double scale,
      double flutterX,
      double flutterY,
      double width,
      double height
      ) {


    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;


    double centerOffsetY = (containerHeight - height) / 2;
    double centerOffsetX = (containerWidth - width) / 2;

    double iosX = 1/devicePixelRatio * (centerOffsetX * scale + flutterX);
    double iosY = -1/devicePixelRatio * (flutterY + height * (scale-1) -
        centerOffsetY*scale + (containerHeight - height) * (scale-1));

    // Debug logging
    print('\n=== Flutter to iOS Conversion Debug ===');
    print('Input Parameters:');
    print('scale: $scale');
    print('flutterX: $flutterX');
    print('flutterY: $flutterY');
    print('width: $width');
    print('height: $height');
    print('centerOffsetY: $centerOffsetY');

    print('\nFinal Coordinates:');
    print('iosX: $iosX');
    print('iosY: $iosY');
    print('=====================================\n');

    return Offset(iosX, iosY);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: applyTransformation,
        label: const Text('Save To iOS View'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(108.0),
              child: Text(
                'InteractiveViewer Example',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black,
                ),
              ),
              height: containerHeight,
              width: containerWidth,
              child: ClipRRect(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // height = constraints.maxHeight;
                    // width = height * 1000 / 1500;


                    final containerAspectRatio = containerWidth / containerHeight;
                    if (imageAspectRatio > containerAspectRatio) {
                      // Image is wider relative to container
                      width = constraints.maxWidth;
                      height = containerWidth / imageAspectRatio;
                    } else {
                      // Image is taller relative to container
                      height = constraints.maxHeight;
                      width = containerHeight * imageAspectRatio;
                    }



                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        InteractiveViewer(
                          transformationController: _controller,
                          boundaryMargin: const EdgeInsets.all(70.0),
                          minScale: 0.1,
                          maxScale: 9.0,
                          child: SizedBox(
                            height: 900,
                            width: 900,
                            child: Image.asset(
                              'assets/fashion_02_background.jpg',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}