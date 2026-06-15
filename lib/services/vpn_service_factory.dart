import 'package:maxspeed_vpn/services/vpn_service_interface.dart';

// Conditional imports: web vs native factory
// On web: only web factory is compiled (no dart:io references)
// On native: only native factory is compiled
import 'package:maxspeed_vpn/services/platform/vpn_service_factory_web.dart'
    if (dart.library.io) 'platform/vpn_service_factory_native.dart';

/// Создаёт платформозависимый VPN сервис.
/// Delegates to platform-specific factory via conditional import.
VpnService createVpnService() => platformCreateVpnService();
