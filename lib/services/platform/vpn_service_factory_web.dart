import 'package:maxspeed_vpn/services/vpn_service_interface.dart';
import 'package:maxspeed_vpn/services/platform/vpn_service_web.dart';

VpnService platformCreateVpnService() => WebVpnService();
