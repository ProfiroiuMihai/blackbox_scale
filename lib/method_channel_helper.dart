import 'package:flutter/services.dart';

class MethodChannelHelper {
  static const platformChannel = MethodChannel('com.blackbox_scale.app/helper');

//we need to reverse dx and dy for some reason are the opposite

  Future<void> testTransform({
    required double height,
    required double width,
    required double scale,
    required double dx,
    required double dy,
    required String imagePath,
  }) async {
    try {
      // Prepare parameters to send
      final Map<String, dynamic> arguments = {
        'height': height,
        'width': width,
        'scale': scale,
        'dx': dx,
        'dy': dy,
        'imagePath': imagePath,
      };

      // Call native method and await response
      final result = await platformChannel.invokeMethod('testTransform', arguments);

      // Convert result to Map<String, dynamic>
      return result;

    } catch (e) {
      print('Error sending image transform data: $e');
      rethrow;
    }
  }
}
