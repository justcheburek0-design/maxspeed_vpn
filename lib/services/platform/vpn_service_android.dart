import 'dart:async';
import 'dart:convert';
import 'package:flutter_singbox_vpn/flutter_singbox.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/vpn_models.dart';
import '../../vpn/singbox_config_generator.dart';
import '../../vpn/subscription_parser.dart';
import '../vpn_service_interface.dart';

/// Android-реализация VPN сервиса на базе flutter_singbox_vpn.
class AndroidVpnService implements VpnService {
  final FlutterSingbox _singbox = FlutterSingbox();

  final _stateController = StreamController<VpnConnectionState>.broadcast();
  final _statsController = StreamController<VpnConnectionStats>.broadcast();
  final _logController = StreamController<VpnLogEntry>.broadcast();

  VpnConnectionState _state = VpnConnectionState.disconnected;
  VpnServer? _activeServer;
  VpnConnectionStats _stats = const VpnConnectionStats();
  final List<VpnLogEntry> _logs = [];
  final List<VpnServer> _servers = [];
  final _serversController = StreamController<List<VpnServer>>.broadcast();
  int _accumulatedUpload = 0;
  int _accumulatedDownload = 0;
  DateTime? _connectTime;
  Timer? _durationTimer;

  @override
  Stream<VpnConnectionState> get stateStream => _stateController.stream;
  @override
  Stream<VpnConnectionStats> get statsStream => _statsController.stream;
  @override
  Stream<VpnLogEntry> get logStream => _logController.stream;
  @override
  Stream<double> get downloadProgressStream => const Stream.empty();
  @override
  VpnConnectionState get state => _state;
  @override
  VpnServer? get activeServer => _activeServer;
  @override
  VpnConnectionStats get stats => _stats;
  @override
  List<VpnLogEntry> get logs => List.unmodifiable(_logs);
  @override
  List<VpnServer> get servers => List.unmodifiable(_servers);
  @override
  Stream<List<VpnServer>> get serversStream => _serversController.stream;

  AndroidVpnService() {
    _singbox.onStatusChanged.listen((statusMap) {
      // Handle alert messages from sing-box native service
      if (statusMap['type'] == 'alert') {
        final alertMsg = statusMap['message'] as String? ?? 'Unknown error';
        _addLog(VpnLogLevel.error, 'sing-box: $alertMsg');
        _updateStateFromSingbox(0); // Stopped
        return;
      }
      final code = statusMap['statusCode'] as int? ?? 0;
      _updateStateFromSingbox(code);
    });

    _singbox.onTrafficUpdate.listen((statsMap) {
      final up = statsMap['uplinkSpeed'] as int? ?? 0;
      final down = statsMap['downlinkSpeed'] as int? ?? 0;
      _accumulatedUpload += up;
      _accumulatedDownload += down;
      _stats = _stats.copyWith(
        uploadSpeed: up,
        downloadSpeed: down,
        uploadTotal: _accumulatedUpload,
        downloadTotal: _accumulatedDownload,
      );
      _statsController.add(_stats);
    });

    _singbox.onLogMessage.listen((logEvent) {
      if (logEvent['type'] == 'log') {
        final msg = logEvent['message'] as String? ?? '';
        final entry = VpnLogEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          timestamp: DateTime.now(),
          level: _parseLogLevel(msg),
          message: msg,
        );
        _logs.add(entry);
        if (_logs.length > 500) _logs.removeAt(0);
        _logController.add(entry);
      }
    });
    _loadServers();
  }

  // ─── Server storage ───

  Future<void> _loadServers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('servers');
      if (json != null && json.isNotEmpty) {
        final list = jsonDecode(json) as List;
        _servers.clear();
        for (final item in list) {
          final s = _serverFromJson(item as Map<String, dynamic>);
          if (s != null) _servers.add(s);
        }
        _serversController.add(List.unmodifiable(_servers));
      }
    } catch (_) {}
  }

  Future<void> _saveServers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _servers.map((s) => _serverToJson(s)).toList();
      await prefs.setString('servers', jsonEncode(list));
    } catch (_) {}
  }

  Map<String, dynamic> _serverToJson(VpnServer s) => {
    'id': s.id, 'name': s.name, 'address': s.address, 'port': s.port,
    'protocol': s.protocol.name, 'security': s.security.name,
    'uuid': s.uuid, 'sni': s.sni, 'fingerprint': s.fingerprint,
    'publicKey': s.publicKey, 'shortId': s.shortId, 'path': s.path,
    'host': s.host, 'alpn': s.alpn, 'flow': s.flow, 'mode': s.mode,
    'rawConfig': s.rawConfig, 'isFavorite': s.isFavorite,
    'ping': s.ping, 'country': s.country, 'flag': s.flag,
  };

  VpnServer? _serverFromJson(Map<String, dynamic> m) {
    try {
      return VpnServer(
        id: m['id'] ?? '', name: m['name'] ?? '', address: m['address'] ?? '',
        port: m['port'] ?? 443,
        protocol: VpnProtocol.values.firstWhere((p) => p.name == m['protocol'], orElse: () => VpnProtocol.vless),
        security: VpnSecurity.values.firstWhere((s) => s.name == m['security'], orElse: () => VpnSecurity.none),
        uuid: m['uuid'], sni: m['sni'], fingerprint: m['fingerprint'],
        publicKey: m['publicKey'], shortId: m['shortId'], path: m['path'],
        host: m['host'], alpn: m['alpn'], flow: m['flow'], mode: m['mode'],
        rawConfig: Map<String, dynamic>.from(m['rawConfig'] ?? {}),
        isFavorite: m['isFavorite'] ?? false, ping: m['ping'],
        country: m['country'], flag: m['flag'],
      );
    } catch (_) { return null; }
  }

  /// Загрузить сервера из подписки (вызывается из UI)
  Future<void> loadSubscription(String url) async {
    try {
      String content;
      if (url.startsWith('http://') || url.startsWith('https://')) {
        final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          content = response.body;
        } else {
          _addLog(VpnLogLevel.error, 'Subscription HTTP ${response.statusCode}');
          return;
        }
      } else if (url.startsWith('data:')) {
        content = Uri.decodeFull(url.substring(url.indexOf(',') + 1));
      } else {
        content = url;
      }
      final parsed = SubscriptionParser.parse(content);
      _servers.clear();
      _servers.addAll(parsed);
      await _saveServers();
      _serversController.add(List.unmodifiable(_servers));
      _addLog(VpnLogLevel.info, 'Загружено ${parsed.length} серверов');
    } catch (e) {
      _addLog(VpnLogLevel.error, 'Ошибка загрузки подписки: $e');
    }
  }

  /// Заменить список серверов (после парсинга подписки)
  Future<void> updateServers(List<VpnServer> newServers) async {
    _servers.clear();
    _servers.addAll(newServers);
    await _saveServers();
    _serversController.add(List.unmodifiable(_servers));
  }

  VpnLogLevel _parseLogLevel(String msg) {
    final lower = msg.toLowerCase();
    if (lower.contains('error') || lower.contains('fatal')) return VpnLogLevel.error;
    if (lower.contains('warn')) return VpnLogLevel.warning;
    if (lower.contains('debug')) return VpnLogLevel.debug;
    return VpnLogLevel.info;
  }

  void _updateStateFromSingbox(int code) {
    switch (code) {
      case 0:
        _state = VpnConnectionState.disconnected;
        _activeServer = null;
        _durationTimer?.cancel();
        _connectTime = null;
        break;
      case 1:
        _state = VpnConnectionState.connecting;
        break;
      case 2:
        _state = VpnConnectionState.connected;
        _connectTime = DateTime.now();
        _startDurationTimer();
        break;
      case 3:
        _state = VpnConnectionState.disconnecting;
        break;
    }
    _stateController.add(_state);
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_connectTime != null) {
        _stats = _stats.copyWith(
          duration: DateTime.now().difference(_connectTime!),
          serverName: _activeServer?.name,
        );
        _statsController.add(_stats);
      }
    });
  }

  @override
  Future<bool> connect(VpnServer server) async {
    try {
      _activeServer = server;
      _state = VpnConnectionState.connecting;
      _stateController.add(_state);
      _accumulatedUpload = 0;
      _accumulatedDownload = 0;

      final config = SingboxConfigGenerator.generate(server);
      _addLog(VpnLogLevel.info, 'Подключение к ${server.name} (${server.address}:${server.port})');
      _addLog(VpnLogLevel.info, 'Конфиг (${config.length} bytes): ${config.length > 500 ? '${config.substring(0, 500)}...' : config}');

      try {
        await _singbox.saveConfig(config);
        _addLog(VpnLogLevel.info, 'saveConfig OK');
      } catch (e) {
        _addLog(VpnLogLevel.error, 'saveConfig FAILED: $e');
        _state = VpnConnectionState.error;
        _activeServer = null;
        _stateController.add(_state);
        return false;
      }

      bool started;
      try {
        started = await _singbox.startVPN().timeout(
          const Duration(seconds: 60),
          onTimeout: () {
            _addLog(VpnLogLevel.error, 'startVPN таймаут (60с)');
            return false;
          },
        );
        _addLog(VpnLogLevel.info, 'startVPN вернул: $started');
      } catch (e) {
        _addLog(VpnLogLevel.error, 'startVPN EXCEPTION: $e');
        started = false;
      }

      if (!started) {
        _state = VpnConnectionState.error;
        _activeServer = null;
        _stateController.add(_state);
        _addLog(VpnLogLevel.error, 'Не удалось запустить VPN');
        return false;
      }

      // Ждём подтверждения что сервис реально стартанул (statusCode == 2 = Started)
      _addLog(VpnLogLevel.info, 'Ожидание статуса Started...');
      final completer = Completer<VpnConnectionState>();
      late StreamSubscription sub;
      late StreamSubscription logSub;
      final singboxLogs = <String>[];
      sub = _stateController.stream.listen((state) {
        if (state == VpnConnectionState.connected) {
          if (!completer.isCompleted) completer.complete(state);
          sub.cancel();
          logSub.cancel();
        } else if (state == VpnConnectionState.disconnected) {
          if (!completer.isCompleted) completer.complete(state);
          sub.cancel();
          logSub.cancel();
        }
      });
      // Collect sing-box logs during connection attempt
      logSub = _singbox.onLogMessage.listen((logEvent) {
        if (logEvent['type'] == 'log') {
          final msg = logEvent['message'] as String? ?? '';
          singboxLogs.add(msg);
        }
      });
      // Also try to get buffered logs from sing-box
      try {
        final buffered = await _singbox.getLogs();
        if (buffered.isNotEmpty) {
          singboxLogs.addAll(buffered);
          _addLog(VpnLogLevel.info, 'Получено ${buffered.length} буферизованных логов sing-box');
        }
      } catch (_) {}

      try {
        final confirmedState = await completer.future.timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            _addLog(VpnLogLevel.error, 'Таймаут ожидания статуса Started (30с)');
            return VpnConnectionState.disconnected;
          },
        );
        if (confirmedState != VpnConnectionState.connected) {
          // Log collected sing-box messages for diagnostics
          if (singboxLogs.isNotEmpty) {
            for (final msg in singboxLogs) {
              _addLog(VpnLogLevel.debug, 'sing-box: $msg');
            }
          } else {
            _addLog(VpnLogLevel.debug, 'sing-box: нет логов (sing-box не запустил ядро?)');
          }
          _addLog(VpnLogLevel.error, 'VPN не перешёл в connected, состояние: $confirmedState');
          _state = VpnConnectionState.error;
          _activeServer = null;
          _stateController.add(_state);
          return false;
        }
        _addLog(VpnLogLevel.info, 'VPN подтверждён: connected');
      } finally {
        sub.cancel();
      }

      return true;
    } catch (e) {
      _state = VpnConnectionState.error;
      _activeServer = null;
      _stateController.add(_state);
      _addLog(VpnLogLevel.error, 'Ошибка подключения: $e');
      return false;
    }
  }

  @override
  Future<bool> disconnect() async {
    try {
      _state = VpnConnectionState.disconnecting;
      _stateController.add(_state);
      return await _singbox.stopVPN();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String> getStatus() async => await _singbox.getVPNStatus();

  @override
  Future<List<InstalledApp>> getInstalledApps() async {
    final result = await _singbox.getInstalledApps();
    final apps = <InstalledApp>[];
    for (final item in result) {
      final map = item as Map;
      final pkg = map['packageName'] as String? ?? '';
      final name = map['appName'] as String? ?? pkg.split('.').last;
      if (pkg.isNotEmpty) apps.add(InstalledApp(packageName: pkg, appName: name));
    }
    return apps;
  }

  @override
  Future<void> setPerAppProxyMode(String mode) async {
    await _singbox.setPerAppProxyMode(mode);
  }

  @override
  Future<void> setPerAppProxyList(List<String> packages) async {
    await _singbox.setPerAppProxyList(packages);
  }

  @override
  Future<List<String>> getPerAppProxyList() async {
    return await _singbox.getPerAppProxyList();
  }

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
    await _singbox.clearLogs();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _stateController.close();
    _statsController.close();
    _logController.close();
  }

  @override
  Future<bool> copyConfigToClipboard(VpnServer server) async {
    // Android: no clipboard copy (config applied automatically)
    return false;
  }
}
