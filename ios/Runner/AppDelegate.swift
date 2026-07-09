import Flutter
import UIKit
import AudioToolbox

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    
    if let controller = window?.rootViewController as? FlutterViewController {
      let soundChannel = FlutterMethodChannel(name: "com.example.eazy_store/sound",
                                                binaryMessenger: controller.binaryMessenger)
      soundChannel.setMethodCallHandler({
        (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        if call.method == "playBeep" {
          // System Sound ID 1057 คือเสียง Beep/Alert มาตรฐานของ iOS
          AudioServicesPlaySystemSound(1057)
          result(nil)
        } else {
          result(FlutterMethodNotImplemented)
        }
      })
    }
    
    return result
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
