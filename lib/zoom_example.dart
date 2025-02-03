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
  var containerHeight = 400.0;
  var containerWidth = 10.0;
  var imageAspectRatio = 1000/1500;


  void scale() {
    // Calculate container and image aspect ratios
    double containerAspectRatio = containerWidth / containerHeight;

    // If container is relatively narrower than image (current case)
    if (containerAspectRatio < imageAspectRatio) {
      width = containerWidth;
      height = width / imageAspectRatio;
      var scale = containerHeight / height;

      var verticalTranslation = -((containerHeight - height) * scale / 2);
      var horizontalTranslation = -((containerWidth*scale - containerWidth)/2);
      _controller.value = Matrix4.identity()
        ..translate(horizontalTranslation, verticalTranslation)
        ..scale(scale);
    }
    // If container is relatively wider than image
    else {
      height = containerHeight;
      width = height * imageAspectRatio;
      var scale = containerWidth / width;

      var horizontalTranslation = -((containerWidth - width) * scale / 2);
      var verticalTranslation = -((containerHeight*scale - height)/2);
      _controller.value = Matrix4.identity()
        ..translate(horizontalTranslation, verticalTranslation)
        ..scale(scale);
      print('scale: $scale');
    }

    print('Container Width: $containerWidth');
    print('Image Width: $width');
    print('Container Height: $containerHeight');
    print('Image Height: $height');
    print('Container Aspect Ratio: $containerAspectRatio');
    print('Image Aspect Ratio: $imageAspectRatio');

  }

  @override
  void dispose() {
    _controller.removeListener(() {
      setState(() {});
    });
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(33.0),
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
                    // Calculate dimensions based on container width
                    width = containerWidth;
                    height = width / imageAspectRatio;
                    scale();
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        InteractiveViewer(
                          transformationController: _controller,
                          // boundaryMargin: const EdgeInsets.all(70.0),
                          minScale: 0.1,
                          maxScale: 9.0,
                          child: SizedBox(
                            width: containerWidth,
                            height: containerHeight,
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