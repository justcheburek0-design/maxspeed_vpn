import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'vpn_service_interface.dart';
import 'platform/vpn_service_android.dart';
import 'platform/vpn_service_desktop.dart';
import 'platform/vpn_service_web.dart';

/// Создаёт платформозависимый VPN сервис.
VpnService createVpnService() {
  if (kIsWeb) {
    return WebVpnService();
  }
  if (Platform.isAndroid) {
    return AndroidVpnService();
  }
  return DesktopVpnService();
}
