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

    // Calculate viewport center in Flutter coordinates
    final viewportCenterX = width / 2;
    final viewportCenterY = height / 2;

    // Calculate the actual visible region
    final visibleWidth = width / scale;
    final visibleHeight = height / scale;

    // Calculate top-left corner of visible region
    final visibleTopLeftX = -translation.dx / scale;
    final visibleTopLeftY = -translation.dy / scale;

    // Calculate center of visible region
    final visibleCenterX = visibleTopLeftX + (visibleWidth / 2);
    final visibleCenterY = visibleTopLeftY + (visibleHeight / 2);

    print('''
=== Flutter Transformation Details ===
Container Size: ${width.toStringAsFixed(2)} x ${height.toStringAsFixed(2)}
Scale: ${scale.toStringAsFixed(2)}
Original Translation: (${translation.dx.toStringAsFixed(2)}, ${translation.dy.toStringAsFixed(2)})
Adjusted Translation for iOS: (${adjustedTranslation.dx.toStringAsFixed(2)}, ${adjustedTranslation.dy.toStringAsFixed(2)})
Viewport Center: (${viewportCenterX.toStringAsFixed(2)}, ${viewportCenterY.toStringAsFixed(2)})
Visible Region Size: ${visibleWidth.toStringAsFixed(2)} x ${visibleHeight.toStringAsFixed(2)}
Visible Region Top-Left: (${visibleTopLeftX.toStringAsFixed(2)}, ${visibleTopLeftY.toStringAsFixed(2)})
Visible Region Center: (${visibleCenterX.toStringAsFixed(2)}, ${visibleCenterY.toStringAsFixed(2)})
Raw Matrix:
${_formatMatrix(_matrix)}
==============================
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

    // Add scale-based offset adjustment (half of width/height multiplied by scale)
    // this is just a experiment that does not work
    final scaleOffsetX = (width / 4) * (scale-1)*0;
    final scaleOffsetY = (width ) * (scale-1) *0;

    // Flip Y coordinate for iOS coordinate system
    final flippedDY = -translation.dy;

    // Adjust for coordinate system difference and scaling
    final adjustedDX = -(translation.dx + scaleOffsetX);
    final adjustedDY = -(flippedDY + scaleOffsetY);

    return Offset(adjustedDX, adjustedDY);
  }

  Future<void> applyTransformation() async {
    try {
      final scale = _controller.value.getMaxScaleOnAxis();
      final adjustedTranslation = getTranslationForIOS();

      // Only log when floating action button is pressed
      _logTransformationDetails();
      print('''
=== Sending to iOS ===
Original Translation: ${getTranslationFromMatrix()}
Adjusted Translation: $adjustedTranslation
Height: $height
Width: $width
Scale: $scale
==================
      ''');

      showSpinnerLoadingModal(
          context: context, title: 'Applying Transformation');
      final data = await rootBundle.load(
        'assets/fashion_02_background.jpg',
      );
      final List<int> bytes = data.buffer.asUint8List();
      final tempPath = await getTemporaryDirectory();
      final tempFilename =
          '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final tempFile = File('${tempPath.path}/$tempFilename');

      await tempFile.writeAsBytes(bytes);

      await MethodChannelHelper().testTransform(
        height: height,
        width: width,
        scale: scale,
        dx: adjustedTranslation.dx,
        dy: adjustedTranslation.dy,
        imagePath: tempFile.path,
      );
      Navigator.of(context).pop();
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
                              maxScale: 4.0,
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