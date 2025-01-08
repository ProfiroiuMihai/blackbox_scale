import 'dart:io';
import 'package:blackbox_scale/method_channel_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:math' as math;


class ZoomExample extends StatefulWidget {
  const ZoomExample({super.key});

  @override
  State<ZoomExample> createState() => _ZoomExampleState();
}

class _ZoomExampleState extends State<ZoomExample> {
  final TransformationController _controller = TransformationController();
  Matrix4 _matrix = Matrix4.identity();
  var height = 0.0;
  var width = 0.0;

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
    setState(() {
      _matrix = _controller.value;
    });
  }



  void calculation() async {

    const iosWidth = 300.0;
    const iosHeight = 400.0;
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    // Current Flutter scale
    var flutterScale = _controller.value.getMaxScaleOnAxis();
    if (flutterScale <= 1.0) {
      flutterScale = 0;
    }
    flutterScale=flutterScale-1;

    final flutterTranslation = Offset(
      _controller.value.storage[12],
      _controller.value.storage[13],
    );

    // 2) Original image size
    const double originalImageWidth = 1000.0;
    const double originalImageHeight = 1500.0;


      double originalAspectRatio = originalImageWidth / originalImageHeight;
      double containerAspectRatio = iosWidth / iosHeight;
      double dampeningFactor = originalAspectRatio / containerAspectRatio;


      // Normalize the flutter point relative to the container center
      double normalizedX = flutterTranslation.dx / iosWidth;
      double normalizedY = flutterTranslation.dy / iosHeight;

      // Apply the transformation with dampening factor for x-coordinate
      double iosX = iosWidth * flutterScale * dampeningFactor * normalizedX;
      double iosY = (iosHeight / 2) * flutterScale * normalizedY;



      print('''
--- TRANSFORM LOG ---
devicePixelRatio : $devicePixelRatio
iOS Container    : ${iosWidth.toStringAsFixed(2)} × ${iosHeight.toStringAsFixed(2)}
Flutter Scale    : $flutterScale
FlutterTranslation (dx, dy) : (${flutterTranslation.dx}, ${flutterTranslation.dy})
dx, dy           : ($iosX, $iosY)
---------------------
''');

      // 7. Now call your methodChannel
      try {
        // Prepare a temp file with your image
        final tempPath = await getTemporaryDirectory();
        final tempFilename = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final tempFile = File('${tempPath.path}/$tempFilename');

        final data = await rootBundle.load('assets/fashion_02_background.jpg');
        await tempFile.writeAsBytes(data.buffer.asUint8List());

        // Pass the newly computed dx, dy to iOS
        await MethodChannelHelper().testTransform(
          height: iosHeight,
          width: iosWidth,
          scale: flutterScale,
          dx: iosX,
          dy: iosY,
          imagePath: tempFile.path,
        );
        await MethodChannelHelper().testTransform(
          height: iosHeight,
          width: iosWidth,
          scale: flutterScale,
          dx: -380,
          dy: 600,
          imagePath: tempFile.path,
        );
        await MethodChannelHelper().testTransform(
          height: iosHeight,
          width: iosWidth,
          scale: flutterScale,
          dx: -380,
          dy: -600,
          imagePath: tempFile.path,
        );


      } catch (e) {
        print('Error: $e');
      }
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

            final iosWidth = width / devicePixelRatio;
            final iosHeight = height / devicePixelRatio;

            final flutterTranslation = Offset(
              _controller.value.storage[12],
              _controller.value.storage[13],
            );

            final iosTranslation = Offset(
              (iosWidth / width) * flutterTranslation.dx,
              (-iosHeight / height) * flutterTranslation.dy -
                  iosHeight * (scale - 1),
            );

            print('''
Scale: ${scale.toStringAsFixed(2)}
Device Pixel Ratio: ${devicePixelRatio.toStringAsFixed(2)}
Flutter Translation: ${flutterTranslation.dx.toStringAsFixed(2)}, ${flutterTranslation.dy.toStringAsFixed(2)}
iOS Translation: ${iosTranslation.dx.toStringAsFixed(2)}, ${iosTranslation.dy.toStringAsFixed(2)}
''');

            await MethodChannelHelper().testTransform(
              height: iosHeight,
              width: iosWidth,
              scale: scale,
              dx: iosTranslation.dx,
              dy: iosTranslation.dy,
              imagePath: tempFile.path,
            );

          } catch (e) {
          print('Error: $e');
        }
     // calculation();
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
              height: 400,
              width: 266.66,
              child: ClipRRect(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    height = constraints.maxHeight;
                    width = height * 1000 / 1500;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        InteractiveViewer(
                            transformationController: _controller,
                            boundaryMargin: const EdgeInsets.all(20.0),
                            minScale: 0.1,
                            maxScale: 4.0,
                            child: SizedBox(
                              height: 400,
                              width: 400,
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