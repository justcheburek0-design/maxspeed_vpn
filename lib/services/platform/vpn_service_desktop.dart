import 'dart:async';
import '../../data/models/vpn_models.dart';
import '../vpn_service_interface.dart';

/// Desktop-реализация VPN сервиса.
/// 
/// На десктопе VPN работает через нативный sing-box бинарник,
/// запускаемый как subprocess. Требует интеграции с platform channels
/// или FFI для управления процессом.
/// 
/// Пока — stub с заготовкой для будущей реализации.
class DesktopVpnService implements VpnService {
  final _stateController = StreamController<VpnConnectionState>.broadcast();
  final _statsController = StreamController<VpnConnectionStats>.broadcast();
  final _logController = StreamController<VpnLogEntry>.broadcast();

  VpnConnectionState _state = VpnConnectionState.disconnected;
  VpnServer? _activeServer;
  VpnConnectionStats _stats = const VpnConnectionStats();
  final List<VpnLogEntry> _logs = [];
  Timer? _durationTimer;
  DateTime? _connectTime;

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

  DesktopVpnService() {
    _addLog(VpnLogLevel.info, 'Desktop VPN сервис инициализирован');
    _addLog(VpnLogLevel.warning, 'VPN на десктопе требует нативного sing-box бинарника');
  }

  @override
  Future<bool> connect(VpnServer server) async {
    _addLog(VpnLogLevel.info, 'Подключение к ${server.name} (${server.address}:${server.port})');
    _addLog(VpnLogLevel.warning, 'Функция в разработке — требуется нативный sing-box');
    
    // TODO: Запустить sing-box как subprocess с сгенерированным конфигом
    // 1. Сгенерировать конфиг через SingboxConfigGenerator.generate(server)
    // 2. Записать во временный файл
    // 3. Запустить: sing-box run -config /tmp/maxspeed_vpn.json
    // 4. Мониторить stdout/stderr для логов
    // 5. Отслеживать трафик через TUN интерфейс
    
    _activeServer = server;
    _state = VpnConnectionState.error;
    _stateController.add(_state);
    _addLog(VpnLogLevel.error, 'VPN на этой платформе пока не реализован');
    return false;
  }

  @override
  Future<bool> disconnect() async {
    _state = VpnConnectionState.disconnected;
    _activeServer = null;
    _durationTimer?.cancel();
    _connectTime = null;
    _stateController.add(_state);
    _addLog(VpnLogLevel.info, 'VPN отключён');
    return true;
  }

  @override
  Future<String> getStatus() async => 'desktop_unsupported';

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
    _durationTimer?.cancel();
    _stateController.close();
    _statsController.close();
    _logController.close();
  }
}
