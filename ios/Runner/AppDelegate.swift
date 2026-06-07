import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let paymobChannelName = "paymob_sdk_flutter"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: paymobChannelName,
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { call, result in
        if call.method == "payWithPaymob" {
          result(FlutterError(
            code: "paymob_sdk_missing",
            message: "Paymob iOS SDK is not installed yet; falling back to hosted checkout.",
            details: nil
          ))
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
