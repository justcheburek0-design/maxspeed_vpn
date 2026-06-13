import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'vpn_service_interface.dart';
import 'platform/vpn_service_android.dart';
import 'platform/vpn_service_ios.dart';
import 'platform/vpn_service_desktop.dart';
import 'platform/vpn_service_web.dart';

/// Создаёт платформозависимый VPN сервис.
///
/// - Android: flutter_singbox_vpn plugin (native Kotlin)
/// - iOS: NetworkExtension via platform channel (skeleton — needs Packet Tunnel Provider)
/// - Desktop: sing-box subprocess (Windows/macOS/Linux)
/// - Web: stub with download links UI
VpnService createVpnService() {
  if (kIsWeb) {
    return WebVpnService();
  }
  if (Platform.isAndroid) {
    return AndroidVpnService();
  }
  if (Platform.isIOS) {
    return IosVpnService();
  }
  // Desktop: Windows, macOS, Linux
  return DesktopVpnService();
}
