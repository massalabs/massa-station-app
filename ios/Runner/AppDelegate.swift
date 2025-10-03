import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Setup biometric storage method channel
    let controller = window?.rootViewController as! FlutterViewController
    let biometricChannel = FlutterMethodChannel(
      name: "com.massa.station/biometric_storage",
      binaryMessenger: controller.binaryMessenger
    )

    let biometricStorage = BiometricKeyStorage()

    biometricChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "storeBiometricKey":
        if let args = call.arguments as? [String: Any],
           let key = args["key"] as? String {
          let success = biometricStorage.storeKey(key: key)
          result(success)
        } else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Key not provided", details: nil))
        }

      case "retrieveBiometricKey":
        if let key = biometricStorage.retrieveKey() {
          result(key)
        } else {
          result(nil)
        }

      case "deleteBiometricKey":
        let success = biometricStorage.deleteKey()
        result(success)

      case "hasBiometricKey":
        let hasKey = biometricStorage.hasKey()
        result(hasKey)

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
