import 'dart:io' show Platform;
import 'vpn_service_interface.dart';
import 'platform/vpn_service_android.dart';
import 'platform/vpn_service_desktop.dart';

/// Создаёт платформозависимый VPN сервис.
VpnService createVpnService() {
  if (Platform.isAndroid) {
    return AndroidVpnService();
  }
  return DesktopVpnService();
}
