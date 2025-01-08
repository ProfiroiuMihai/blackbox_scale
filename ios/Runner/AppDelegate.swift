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
    
    
  func processImage(
      _ image: UIImage,
      containerSize: CGSize,   // The size of the "view" or bounding box in which you want to draw
      scale: CGPoint,          // User-provided scale from Flutter (we’ll assume scale.x is the uniform scale)
      offset: CGPoint          // User-provided offset
  ) -> UIImage? {
      // 1. Begin a new image context at `containerSize`.
      UIGraphicsBeginImageContextWithOptions(containerSize, /*opaque*/ false, /*scale*/ 0.0)
      defer { UIGraphicsEndImageContext() }

      // 2. Grab references for our context and the CGImage
      guard
          let context = UIGraphicsGetCurrentContext(),
          let cgImage = image.cgImage
      else {
          return nil
      }

      // 3. Clear the context
      context.clear(CGRect(origin: .zero, size: containerSize))

      // 4. Flip the coordinate system (so 0,0 is top-left instead of bottom-left)
      context.translateBy(x: 0, y: containerSize.height)
      context.scaleBy(x: 1.0, y: -1.0)

      // 5. Calculate the aspect ratio of the original image
      let originalWidth = CGFloat(cgImage.width)
      let originalHeight = CGFloat(cgImage.height)
      let imageAspect = originalWidth / originalHeight

      // 6. Calculate the aspect ratio of the container
      let containerAspect = containerSize.width / containerSize.height

      // 7. Compute the *fitted* size so that the image is NOT stretched
      var fittedWidth: CGFloat
      var fittedHeight: CGFloat

      // “Fit” means the limiting dimension is whichever dimension hits first (width or height)
      if imageAspect > containerAspect {
          // Image is "wider" (in aspect ratio) than the container
          // => limit by container width
          fittedWidth = containerSize.width
          fittedHeight = fittedWidth / imageAspect
      } else {
          // Image is "taller" or same ratio => limit by container height
          fittedHeight = containerSize.height
          fittedWidth = fittedHeight * imageAspect
      }

      // 8. Apply a *uniform* user scaling factor
      //    (We’ll assume you want the user’s "scale.x" to scale both dimensions the same)
      //    If you truly want separate x/y scales, see the note below.
      fittedWidth *= scale.x
      fittedHeight *= scale.x

      // 9. Calculate the final position
      //    We’ll center it within containerSize by default,
      //    plus any additional user offset.
      let xPos = offset.x + (containerSize.width - fittedWidth) / 2.0
      let yPos = offset.y + (containerSize.height - fittedHeight) / 2.0

      // 10. Draw the image in that rect
      let drawingRect = CGRect(x: xPos, y: yPos, width: fittedWidth, height: fittedHeight)
      context.draw(cgImage, in: drawingRect)

      // 11. Extract the final UIImage from the context
      return UIGraphicsGetImageFromCurrentImageContext()
  }

   }