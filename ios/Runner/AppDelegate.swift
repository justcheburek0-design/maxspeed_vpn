import Flutter
import UIKit
import NetworkExtension

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var vpnChannel: FlutterMethodChannel?
  private var statusEventChannel: FlutterEventChannel?
  private var vpnStatusSink: FlutterEventSink?
  private var vpnManager: NETunnelProviderManager?
  private var currentConfig: String?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController

    // Method channel for VPN control
    vpnChannel = FlutterMethodChannel(name: "maxspeed/vpn", binaryMessenger: controller.binaryMessenger)
    vpnChannel?.setMethodCallHandler { [weak self] call, result in
      self?.handleMethodCall(call: call, result: result)
    }

    // Event channel for status streaming to Dart
    statusEventChannel = FlutterEventChannel(name: "maxspeed/vpn/status", binaryMessenger: controller.binaryMessenger)
    statusEventChannel?.setStreamHandler(VpnStatusStreamHandler { [weak self] status in
      self?.vpnStatusSink?(status)
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "connect":
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
        return
      }
      startVPN(args: args, result: result)

    case "disconnect":
      stopVPN(result: result)

    case "getStatus":
      let status = vpnManager?.connection.status.description ?? "not_configured"
      result(status)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func startVPN(args: [String: Any], result: @escaping FlutterResult) {
    guard let _ = args["address"] as? String else {
      result(false)
      return
    }

    // Load or create tunnel provider manager
    NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
      if let error = error {
        print("Failed to load managers: \(error)")
        result(false)
        return
      }

      let manager: NETunnelProviderManager
      if let existing = managers?.first {
        manager = existing
      } else {
        manager = NETunnelProviderManager()
      }

      let protocolConfig = NETunnelProviderProtocol()
      protocolConfig.providerBundleIdentifier = "com.maxspeedvpn.packetTunnel"
      let address = args["address"] as? String ?? ""
      let port = args["port"].map { "\($0)" } ?? ""
      protocolConfig.serverAddress = address + ":" + port
      manager.protocolConfiguration = protocolConfig
      manager.localizedDescription = "MaxSpeedVPN"
      manager.isEnabled = true

      manager.saveToPreferences { [weak self] error in
        if let error = error {
          print("Failed to save manager: \(error)")
          self?.vpnStatusSink?("error")
          result(false)
          return
        }

        self?.vpnManager = manager

        // Start the tunnel
        do {
          try manager.connection.startVPNTunnel()
          self?.vpnStatusSink?("connecting")
          result(true)
        } catch {
          print("Failed to start tunnel: \(error)")
          self?.vpnStatusSink?("error")
          result(false)
        }
      }
    }
  }

  private func stopVPN(result: @escaping FlutterResult) {
    vpnManager?.connection.stopVPNTunnel()
    vpnStatusSink?("disconnected")
    result(true)
  }
}

/// Stream handler for VPN status events
class VpnStatusStreamHandler: NSObject, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?
  private var observer: NSObjectProtocol?

  init(onEvent: @escaping (String?) -> Void) {
    super.init()
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = events

    // Observe NEVPNStatus changes
    observer = NotificationCenter.default.addObserver(
      forName: .NEVPNStatusDidChange,
      object: nil,
      queue: .main
    ) { [weak self] notification in
      if let connection = notification.object as? NEVPNConnection {
        let status: String
        switch connection.status {
        case .invalid: status = "error"
        case .disconnected: status = "disconnected"
        case .connecting: status = "connecting"
        case .connected: status = "connected"
        case .reasserting: status = "connecting"
        case .disconnecting: status = "disconnected"
        @unknown default: status = "unknown"
        }
        self?.eventSink?(status)
      }
    }

    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    if let observer = observer {
      NotificationCenter.default.removeObserver(observer)
    }
    observer = nil
    eventSink = nil
    return nil
  }
}

extension NEVPNStatus {
  var description: String {
    switch self {
    case .invalid: return "invalid"
    case .disconnected: return "disconnected"
    case .connecting: return "connecting"
    case .connected: return "connected"
    case .reasserting: return "reasserting"
    case .disconnecting: return "disconnecting"
    @unknown default: return "unknown"
    }
  }
}
