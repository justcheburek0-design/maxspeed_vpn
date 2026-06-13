import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var vpnChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Setup VPN platform channel
    guard let controller = engineBridge.pluginRegistry.registrar(forPlugin: "MaxSpeedVPN")?.messenger() else {
      return
    }

    vpnChannel = FlutterMethodChannel(name: "maxspeed/vpn", binaryMessenger: controller)
    vpnChannel?.setMethodCallHandler { [weak self] call, result in
      self?.handleVpnMethodCall(call: call, result: result)
    }
  }

  private func handleVpnMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "connect":
      // TODO: Implement NetworkExtension VPN connection
      // For now, return false — iOS VPN requires Packet Tunnel Provider extension
      result(FlutterError(code: "NOT_IMPLEMENTED",
                         message: "iOS VPN requires NetworkExtension. Use Android or Desktop for now.",
                         details: nil))

    case "disconnect":
      // TODO: Implement disconnect
      result(true)

    case "getStatus":
      result("disconnected")

    case "saveConfig":
      // Save config to shared UserDefaults for the tunnel extension
      guard let args = call.arguments as? [String: Any],
            let config = args["config"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "Missing config", details: nil))
        return
      }
      UserDefaults.standard.set(config, forKey: "vpn_config")
      result(true)

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
