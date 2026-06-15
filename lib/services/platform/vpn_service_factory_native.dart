import 'dart:io' show Platform;

import 'package:maxspeed_vpn/services/vpn_service_interface.dart';
import 'package:maxspeed_vpn/services/platform/vpn_service_android.dart';
import 'package:maxspeed_vpn/services/platform/vpn_service_ios.dart';
import 'package:maxspeed_vpn/services/platform/vpn_service_desktop.dart';

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
