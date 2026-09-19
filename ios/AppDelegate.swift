import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "beta/native", binaryMessenger: controller.binaryMessenger)
    channel.setMethodCallHandler { (call, result) in
      switch call.method {
      case "getDeviceId":
        result(UIDevice.current.identifierForVendor?.uuidString ?? "")
      case "getPlatformVersion":
        result("iOS \(UIDevice.current.systemVersion)")
      case "openSettings":
        if let url = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(url)
        }
        result(true)
      case "getBundleVersion":
        result(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
