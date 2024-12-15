import 'dart:io';
import 'package:blackbox_scale/method_channel_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'helpers.dart';

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

  void _logTransformationDetails() {
    final scale = _controller.value.getMaxScaleOnAxis();
    final translation = getTranslationFromMatrix();
    final adjustedTranslation = getTranslationForIOS();
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    // Flutter coordinates calculations (in logical pixels)
    final flutterViewportCenterX = width / 2;
    final flutterViewportCenterY = height / 2;
    final flutterVisibleWidth = width / scale;
    final flutterVisibleHeight = height / scale;
    final flutterVisibleTopLeftX = -translation.dx / scale;
    final flutterVisibleTopLeftY = -translation.dy / scale;
    final flutterVisibleCenterX = flutterVisibleTopLeftX + (flutterVisibleWidth / 2);
    final flutterVisibleCenterY = flutterVisibleTopLeftY + (flutterVisibleHeight / 2);

    // iOS coordinates calculations (in points)
    final iosWidth = width / devicePixelRatio;
    final iosHeight = height / devicePixelRatio;
    final iosScale = scale * devicePixelRatio;
    final iosVisibleWidth = iosWidth / scale;
    final iosVisibleHeight = iosHeight / scale;
    final iosVisibleTopLeftX = -adjustedTranslation.dx / scale;
    final iosVisibleTopLeftY = -adjustedTranslation.dy / scale;

    print('''
=== Coordinate System Comparison ===
Device Pixel Ratio: ${devicePixelRatio.toStringAsFixed(2)}

FLUTTER COORDINATES (Logical Pixels):
Container Size: ${width.toStringAsFixed(2)} x ${height.toStringAsFixed(2)}
Scale: ${scale.toStringAsFixed(2)}
Translation: (${translation.dx.toStringAsFixed(2)}, ${translation.dy.toStringAsFixed(2)})
Viewport Center: (${flutterViewportCenterX.toStringAsFixed(2)}, ${flutterViewportCenterY.toStringAsFixed(2)})
Visible Region:
  - Size: ${flutterVisibleWidth.toStringAsFixed(2)} x ${flutterVisibleHeight.toStringAsFixed(2)}
  - Top-Left: (${flutterVisibleTopLeftX.toStringAsFixed(2)}, ${flutterVisibleTopLeftY.toStringAsFixed(2)})
  - Center: (${flutterVisibleCenterX.toStringAsFixed(2)}, ${flutterVisibleCenterY.toStringAsFixed(2)})

iOS COORDINATES (Points):
Container Size: ${iosWidth.toStringAsFixed(2)} x ${iosHeight.toStringAsFixed(2)}
Scale: ${iosScale.toStringAsFixed(2)}
Translation: (${adjustedTranslation.dx.toStringAsFixed(2)}, ${adjustedTranslation.dy.toStringAsFixed(2)})
Visible Region:
  - Size: ${iosVisibleWidth.toStringAsFixed(2)} x ${iosVisibleHeight.toStringAsFixed(2)}
  - Top-Left: (${iosVisibleTopLeftX.toStringAsFixed(2)}, ${iosVisibleTopLeftY.toStringAsFixed(2)})

Raw Transformation Matrix:
${_formatMatrix(_matrix)}
==============================
''');

    print('''
=== Values Being Sent to iOS ===
Container Size: ${iosWidth.toStringAsFixed(2)} x ${iosHeight.toStringAsFixed(2)}
Scale: ${iosScale.toStringAsFixed(2)}
Translation: (${adjustedTranslation.dx.toStringAsFixed(2)}, ${adjustedTranslation.dy.toStringAsFixed(2)})
==================
''');
  }

  String _formatMatrix(Matrix4 matrix) {
    return 'Matrix4(\n'
        '  ${matrix.storage[0].toStringAsFixed(2)}, ${matrix.storage[1].toStringAsFixed(2)}, ${matrix.storage[2].toStringAsFixed(2)}, ${matrix.storage[3].toStringAsFixed(2)},\n'
        '  ${matrix.storage[4].toStringAsFixed(2)}, ${matrix.storage[5].toStringAsFixed(2)}, ${matrix.storage[6].toStringAsFixed(2)}, ${matrix.storage[7].toStringAsFixed(2)},\n'
        '  ${matrix.storage[8].toStringAsFixed(2)}, ${matrix.storage[9].toStringAsFixed(2)}, ${matrix.storage[10].toStringAsFixed(2)}, ${matrix.storage[11].toStringAsFixed(2)},\n'
        '  ${matrix.storage[12].toStringAsFixed(2)}, ${matrix.storage[13].toStringAsFixed(2)}, ${matrix.storage[14].toStringAsFixed(2)}, ${matrix.storage[15].toStringAsFixed(2)}\n'
        ')';
  }

  Offset getTranslationFromMatrix() {
    final matrix = _controller.value;
    return Offset(matrix.storage[12], matrix.storage[13]);
  }

  Offset getTranslationForIOS() {
    final translation = getTranslationFromMatrix();
    final scale = _controller.value.getMaxScaleOnAxis();
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    // 1. Convert Flutter's logical pixels to iOS points by dividing by device pixel ratio
    final flutterToIosX = translation.dx / devicePixelRatio;
    final flutterToIosY = translation.dy / devicePixelRatio;

    // 2. Adjust for coordinate system differences:
    // - Flutter: origin at top-left, positive Y goes down
    // - iOS: origin at top-left, positive Y goes down (same as Flutter, no flip needed)
    // - We negate the translation because moving content right/down in Flutter
    //   means moving the viewport left/up in iOS
    final adjustedDX = -flutterToIosX;
    final adjustedDY = -flutterToIosY;

    return Offset(adjustedDX, adjustedDY);
  }

  Future<void> applyTransformation() async {
    try {
      // Log transformation details before processing
      _logTransformationDetails();

      final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
      final scale = _controller.value.getMaxScaleOnAxis();
      final translation = getTranslationForIOS();

      // Print key values in a more concise format
      print('''
=== IMPORTANT TRANSFORMATION VALUES ===
Scale: ${scale.toStringAsFixed(2)}
Device Pixel Ratio: ${devicePixelRatio.toStringAsFixed(2)}
Flutter Translation: ${getTranslationFromMatrix().dx.toStringAsFixed(2)}, ${getTranslationFromMatrix().dy.toStringAsFixed(2)}
iOS Translation: ${translation.dx.toStringAsFixed(2)}, ${translation.dy.toStringAsFixed(2)}
Container Size (Flutter): ${width.toStringAsFixed(2)} x ${height.toStringAsFixed(2)}
Container Size (iOS): ${(width/devicePixelRatio).toStringAsFixed(2)} x ${(height/devicePixelRatio).toStringAsFixed(2)}
===================================
''');

      // Convert dimensions to iOS points
      final iosWidth = width / devicePixelRatio;
      final iosHeight = height / devicePixelRatio;

      final data = await rootBundle.load('assets/fashion_02_background.jpg');
      final List<int> bytes = data.buffer.asUint8List();
      final tempPath = await getTemporaryDirectory();
      final tempFilename = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final tempFile = File('${tempPath.path}/$tempFilename');

      await tempFile.writeAsBytes(bytes);


      await MethodChannelHelper().testTransform(
        height: iosHeight,
        width: iosWidth,
        scale: 2,
        dx: iosWidth - 71.33,
        dy: 71.33,
        imagePath: tempFile.path,
      );
    } catch (error, stackTrace) {
      print('Error in applyTransformation: $error');
      print('Stack trace: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: applyTransformation,
        label: const Text('Save To iOS View'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
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
                height: MediaQuery.of(context).size.height - 170,
                child: ClipRRect(
                  child: LayoutBuilder(
                    builder: (context, constrains) {
                      height = constrains.maxHeight;
                      width = constrains.maxWidth;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          AspectRatio(
                            aspectRatio: 1080 / 1920,
                            child: InteractiveViewer(
                              transformationController: _controller,
                              boundaryMargin: const EdgeInsets.all(20.0),
                              minScale: 0.1,
                              maxScale: 2.0,
                              child: Container(
                                color: Colors.black,
                                child: Image.asset(
                                'assets/fashion_02_background.jpg',
                                fit: BoxFit.contain,
                              )),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Transform Example (using same matrix)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                height: MediaQuery.of(context).size.height - 170,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.black,
                  ),
                ),
                child: ClipRRect(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AspectRatio(
                        aspectRatio: 1080 / 1920,
                        child: Transform(
                          transform: _matrix,
                          child: Image.asset(
                            'assets/fashion_02_background.jpg',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Transformation Matrix:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    _formatMatrix(_matrix),
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}