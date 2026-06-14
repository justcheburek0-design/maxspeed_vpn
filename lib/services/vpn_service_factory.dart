import 'package:flutter/foundation.dart';
import 'vpn_service_interface.dart';

// Conditional imports: web vs native
// On web: only web service is compiled
// On native: only native factory is compiled (avoids dart:io in web builds)
import 'platform/vpn_service_web.dart' if (dart.library.io) 'platform/vpn_service_native_factory.dart';

/// Создаёт платформозависимый VPN сервис.
///
/// - Android: flutter_singbox_vpn plugin (native Kotlin)
/// - iOS: NetworkExtension via platform channel (skeleton)
/// - Desktop: sing-box subprocess (Windows/macOS/Linux)
/// - Web: stub with download links UI
VpnService createVpnService() {
  if (kIsWeb) {
    return WebVpnService();
  }
  // Native platforms — delegate to native factory
  return createNativeVpnService();
}
