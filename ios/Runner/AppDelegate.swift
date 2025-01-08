import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(
      name: "com.blackbox_scale.app/helper",
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else { return }

      switch call.method {
      case "testTransform":
        if let args = call.arguments as? [String: Any],
           let height = args["height"] as? Double,
           let width = args["width"] as? Double,
           let scale = args["scale"] as? Double,
           let dx = args["dx"] as? Double,
           let dy = args["dy"] as? Double,
           let imagePath = args["imagePath"] as? String {

          // Handle the transformation here
          self.handleTransformation(
            height: height,
            width: width,
            scale: scale,
            dx: dx,
            dy: dy,
            imagePath: imagePath,
            result: result
          )
        } else {
          result(FlutterError(
            code: "INVALID_ARGUMENTS",
            message: "Invalid arguments provided",
            details: nil
          ))
        }

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func handleTransformation(
    height: Double,
    width: Double,
    scale: Double,
    dx: Double,
    dy: Double,
    imagePath: String,
    result: @escaping FlutterResult
  ) {
    // Implement your transformation logic here
    // For example:
    guard let image = UIImage(contentsOfFile: imagePath) else {
      result(FlutterError(
        code: "IMAGE_LOAD_ERROR",
        message: "Failed to load image from path",
        details: nil
      ))
      return
    }
      
      if let transformedImage = processImage(image, containerSize: .init(width:width, height: height), scale: .init(x: scale, y: scale), offset: .init(x: dx, y: dy)) {
          UIImageWriteToSavedPhotosAlbum(transformedImage, nil, nil, nil)
                 result("Processed Successfully")
      }
  }
    
    
  func processImage(_ image: UIImage, containerSize: CGSize, scale: CGPoint, offset: CGPoint) -> UIImage? {
      // Debug logging
      print("Input parameters:")
      print("Original image size: \(image.size)")
      print("Container size: \(containerSize)")
      print("Scale: \(scale)")
      print("Offset: \(offset)")

      UIGraphicsBeginImageContextWithOptions(containerSize, false, 0.0)
      defer { UIGraphicsEndImageContext() }

      guard let context = UIGraphicsGetCurrentContext(),
            let cgImage = image.cgImage else {
          print("Failed to get context or CGImage")
          return nil
      }

      // Clear the context
      context.clear(CGRect(origin: .zero, size: containerSize))

      // Flip the coordinate system
      context.translateBy(x: 0, y: containerSize.height)
      context.scaleBy(x: 1.0, y: -1.0)

      // Calculate aspect ratios
      let imageAspect = image.size.width / image.size.height
      let containerAspect = containerSize.width / containerSize.height

      print("Aspect ratios:")
      print("Image aspect ratio: \(imageAspect)")
      print("Container aspect ratio: \(containerAspect)")

      // Calculate the size that maintains aspect ratio
      var scaledSize = containerSize
      if imageAspect > containerAspect {
          // Image is wider than container
          scaledSize.height = containerSize.width / imageAspect
          print("Image is wider - adjusting height to: \(scaledSize.height)")
      } else {
          // Image is taller than container
          scaledSize.width = containerSize.height * imageAspect
          print("Image is taller - adjusting width to: \(scaledSize.width)")
      }



      // Calculate drawing rect with offset
      let drawingRect = CGRect(
          x: offset.x ,
          y: offset.y ,
          width: scaledSize.width*scale.x,
          height: scaledSize.height*scale.x
      )

      print("Final drawing rect: \(drawingRect)")

      // Validate drawing rect
      if drawingRect.width <= 0 || drawingRect.height <= 0 {
          print("ERROR: Invalid drawing rect dimensions")
          return nil
      }

         context.setFillColor(UIColor.red.withAlphaComponent(0.3).cgColor)
          context.fill(CGRect(origin: .zero, size: containerSize))


      // Draw the image
      context.draw(cgImage, in: drawingRect)

      let resultImage = UIGraphicsGetImageFromCurrentImageContext()
      print("Result image size: \(String(describing: resultImage?.size))")

      return resultImage
  }
}
