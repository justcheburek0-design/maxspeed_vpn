import 'dart:io' show Platform;

import 'vpn_service_interface.dart';
import 'vpn_service_android.dart';
import 'vpn_service_ios.dart';
import 'vpn_service_desktop.dart';

/// Creates platform-specific VPN service for native platforms only.
/// This file is NOT compiled on web (conditional import in vpn_service_factory.dart).
VpnService createNativeVpnService() {
  if (Platform.isAndroid) {
    return AndroidVpnService();
  }
  if (Platform.isIOS) {
    return IosVpnService();
  }
  // Desktop: Windows, macOS, Linux
  return DesktopVpnService();
}
