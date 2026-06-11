import 'dart:async';
import '../../data/models/vpn_models.dart';
import '../vpn_service_interface.dart';

/// Web-реализация VPN сервиса.
/// 
/// В браузере VPN невозможен напрямую. Приложение работает как:
/// - Просмотр/управление подписками
/// - Копирование конфигов для ручного импорта
/// - Скачивание нативного клиента
class WebVpnService implements VpnService {
  final _stateController = StreamController<VpnConnectionState>.broadcast();
  final _statsController = StreamController<VpnConnectionStats>.broadcast();
  final _logController = StreamController<VpnLogEntry>.broadcast();

  VpnConnectionState _state = VpnConnectionState.disconnected;
  VpnServer? _activeServer;
  VpnConnectionStats _stats = const VpnConnectionStats();
  final List<VpnLogEntry> _logs = [];

  @override
  Stream<VpnConnectionState> get stateStream => _stateController.stream;
  @override
  Stream<VpnConnectionStats> get statsStream => _statsController.stream;
  @override
  Stream<VpnLogEntry> get logStream => _logController.stream;
  @override
  VpnConnectionState get state => _state;
  @override
  VpnServer? get activeServer => _activeServer;
  @override
  VpnConnectionStats get stats => _stats;
  @override
  List<VpnLogEntry> get logs => List.unmodifiable(_logs);

  WebVpnService() {
    _addLog(VpnLogLevel.info, 'MaxSpeedVPN Web');
    _addLog(VpnLogLevel.info, 'VPN в браузере невозможен — используйте нативный клиент');
  }

  @override
  Future<bool> connect(VpnServer server) async {
    _addLog(VpnLogLevel.warning, 'VPN недоступен в браузере');
    _addLog(VpnLogLevel.info, 'Скачайте нативный клиент для ${server.name}');
    return false;
  }

  @override
  Future<bool> disconnect() async => true;

  @override
  Future<String> getStatus() async => 'web_unsupported';

  @override
  Future<List<InstalledApp>> getInstalledApps() async => [];

  @override
  Future<void> setPerAppProxyMode(String mode) async {}

  @override
  Future<void> setPerAppProxyList(List<String> packages) async {}

  @override
  Future<List<String>> getPerAppProxyList() async => [];

  void _addLog(VpnLogLevel level, String message) {
    final entry = VpnLogEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      level: level,
      message: message,
    );
    _logs.add(entry);
    if (_logs.length > 500) _logs.removeAt(0);
    _logController.add(entry);
  }

  @override
  Future<void> clearLogs() async {
    _logs.clear();
  }

  @override
  void dispose() {
    _stateController.close();
    _statsController.close();
    _logController.close();
  }
}
