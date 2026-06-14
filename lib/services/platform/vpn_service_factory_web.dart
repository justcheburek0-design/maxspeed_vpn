import 'vpn_service_interface.dart';
import 'vpn_service_web.dart';

VpnService platformCreateVpnService() => WebVpnService();
