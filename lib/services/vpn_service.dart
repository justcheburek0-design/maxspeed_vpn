import 'vpn_service_factory.dart';
import 'vpn_service_interface.dart';

/// Обёртка над фабрикой для обратной совместимости.
/// Используйте createVpnService() напрямую для нового кода.
VpnService createVpnServiceCompat() => createVpnService();
