import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let canvases = FlutterMethodChannel(name: "dataray/canvases", binaryMessenger: controller.binaryMessenger)
      canvases.setMethodCallHandler { call, result in
        do {
          let folder = try FileManager.default.url(for: .applicationSupportDirectory,
            in: .userDomainMask, appropriateFor: nil, create: true)
          let url = folder.appendingPathComponent("laser_canvases.json")
          switch call.method {
          case "read": result(FileManager.default.fileExists(atPath: url.path)
            ? try String(contentsOf: url, encoding: .utf8) : "[]")
          case "write":
            guard let json = call.arguments as? String else {
              result(FlutterError(code: "CANVAS", message: "JSON requerido", details: nil)); return
            }
            try json.write(to: url, atomically: true, encoding: .utf8)
            result(nil)
          default: result(FlutterMethodNotImplemented)
          }
        } catch { result(FlutterError(code: "CANVAS", message: error.localizedDescription, details: nil)) }
      }
      let settings = FlutterMethodChannel(name: "dataray/settings", binaryMessenger: controller.binaryMessenger)
      settings.setMethodCallHandler { call, result in
        switch call.method {
        case "readTheme": result(UserDefaults.standard.string(forKey: "dataray_theme"))
        case "writeTheme":
          guard let value = call.arguments as? String, ["light", "dark"].contains(value) else {
            result(FlutterError(code: "SETTINGS", message: "Invalid theme", details: nil)); return
          }
          UserDefaults.standard.set(value, forKey: "dataray_theme")
          result(nil)
        default: result(FlutterMethodNotImplemented)
        }
      }
      let channel = FlutterMethodChannel(name: "dataray/history", binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler { call, result in
        do {
          let directory = try FileManager.default.url(for: .applicationSupportDirectory,
            in: .userDomainMask, appropriateFor: nil, create: true)
          let url = directory.appendingPathComponent("test_history.json")
          switch call.method {
          case "read":
            result(FileManager.default.fileExists(atPath: url.path)
              ? try String(contentsOf: url, encoding: .utf8) : "[]")
          case "write":
            guard let json = call.arguments as? String else {
              result(FlutterError(code: "HISTORY", message: "JSON requerido", details: nil)); return
            }
            try json.write(to: url, atomically: true, encoding: .utf8)
            result(nil)
          default: result(FlutterMethodNotImplemented)
          }
        } catch {
          result(FlutterError(code: "HISTORY", message: error.localizedDescription, details: nil))
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}


