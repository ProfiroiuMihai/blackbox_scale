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

      final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
      final scale = _controller.value.getMaxScaleOnAxis();

      // Print key values in a more concise format


      // Convert dimensions to iOS points
      final iosWidth = width / devicePixelRatio;
      final iosHeight = height / devicePixelRatio;

      final data = await rootBundle.load('assets/fashion_02_background.jpg');
      final List<int> bytes = data.buffer.asUint8List();
      final tempPath = await getTemporaryDirectory();
      final tempFilename = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final tempFile = File('${tempPath.path}/$tempFilename');

      await tempFile.writeAsBytes(bytes);

      print('''
=== IMPORTANT TRANSFORMATION VALUES ===
Scale: ${scale.toStringAsFixed(2)}
Device Pixel Ratio: ${devicePixelRatio.toStringAsFixed(2)}
Flutter Translation: ${getTranslationFromMatrix().dx.toStringAsFixed(2)}, ${getTranslationFromMatrix().dy.toStringAsFixed(2)}
ios Translation : ${    flutterToIos(scale,getTranslationFromMatrix().dx, getTranslationFromMatrix().dy, width, height, iosWidth, iosHeight).dx.toStringAsFixed(2)},
           ${flutterToIos(scale,getTranslationFromMatrix().dx, getTranslationFromMatrix().dy, width, height, iosWidth, iosHeight).dy.toStringAsFixed(2)}
Container Size (Flutter): ${width.toStringAsFixed(2)} x ${height.toStringAsFixed(2)}
Container Size (iOS): ${(width/devicePixelRatio).toStringAsFixed(2)} x ${(height/devicePixelRatio).toStringAsFixed(2)}
===================================
''');



      await MethodChannelHelper().testTransform(
        height: iosHeight,
        width: iosWidth,
        scale: scale,
        dx: flutterToIos(scale,getTranslationFromMatrix().dx, getTranslationFromMatrix().dy, width, height, iosWidth, iosHeight).dx,
         dy: flutterToIos(scale,getTranslationFromMatrix().dx, getTranslationFromMatrix().dy, width, height, iosWidth, iosHeight).dy,


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
      double height,
      double iosWidth,
      double iosHeight
      ) {
    // Validate input values
    if (width <= 0 || height <= 0 || iosWidth <= 0 || iosHeight <= 0) {
      throw ArgumentError("Width, Height, iOSWidth, and iOSHeight must be positive values.");
    }

    // Apply the derived linear transformations
    double iosX = (iosWidth / width) * flutterX;
    double iosY = (-iosHeight / height) * flutterY - iosHeight*(scale-1);

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
                height: MediaQuery.of(context).size.height - 400,
                child: ClipRRect(
                  child: LayoutBuilder(
                    builder: (context, constrains) {
                      height = constrains.maxHeight;
                      width = height * 1000/ 1499;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          AspectRatio(
                            aspectRatio: 1000 / 1499,
                            child: InteractiveViewer(
                              transformationController: _controller,
                              boundaryMargin: const EdgeInsets.all(20.0),
                              minScale: 0.1,
                              maxScale: 5.0,
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
                        aspectRatio: 1000 / 1499,
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