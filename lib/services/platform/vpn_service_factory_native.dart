import 'dart:io' show Platform;

import '../vpn_service_interface.dart';
import 'vpn_service_android.dart';
import 'vpn_service_ios.dart';
import 'vpn_service_desktop.dart';

VpnService platformCreateVpnService() {
  if (Platform.isAndroid) {
    return AndroidVpnService();
  }
  if (Platform.isIOS) {
    return IosVpnService();
  }
  // Desktop: Windows, macOS, Linux
  return DesktopVpnService();
}
