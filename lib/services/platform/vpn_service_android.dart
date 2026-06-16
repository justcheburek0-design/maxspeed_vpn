import 'dart:async';
import 'dart:convert';
import 'package:flutter_singbox_client/flutter_singbox_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maxspeed_vpn/data/models/vpn_models.dart';
import 'package:maxspeed_vpn/vpn/singbox_config_generator.dart';
import 'package:maxspeed_vpn/services/vpn_service_interface.dart';

/// Android-реализация VPN сервиса на базе flutter_singbox_client.
class AndroidVpnService implements VpnService {
  final SingboxClient _client = SingboxClient();

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

  StreamSubscription<ServiceState>? _stateSub;
  StreamSubscription<TrafficStats>? _trafficSub;
  StreamSubscription<List<LogEntry>>? _logSub;
  StreamSubscription<String>? _faultSub;

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
    _init();
  }

  Future<void> _init() async {
    try {
      await _client.initialize();
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      _addLog(VpnLogLevel.error, 'sing-box initialize failed: $e');
    }
    await _loadServers();

    _stateSub = _client.serviceStateStream.listen((serviceState) {
      _updateStateFromServiceState(serviceState);
    });

    _trafficSub = _client.trafficStatsStream.listen((trafficStats) {
      final up = trafficStats.uplinkBps.toInt();
      final down = trafficStats.downlinkBps.toInt();
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

    _logSub = _client.coreLogStream.listen((logEntries) {
      for (final entry in logEntries) {
        final vpnEntry = VpnLogEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          timestamp: DateTime.now(),
          level: _mapLogLevel(entry.level),
          message: entry.message,
        );
        _logs.add(vpnEntry);
        if (_logs.length > 500) _logs.removeAt(0);
        _logController.add(vpnEntry);
      }
    });

    _faultSub = _client.faultStream.listen((error) {
      _addLog(VpnLogLevel.error, 'sing-box: $error');
      _updateState(VpnConnectionState.error);
    });
  }

  // ─── State mapping ───

  void _updateStateFromServiceState(ServiceState serviceState) {
    switch (serviceState) {
      case ServiceState.stopped:
        _updateState(VpnConnectionState.disconnected);
      case ServiceState.starting:
        _updateState(VpnConnectionState.connecting);
      case ServiceState.started:
        _updateState(VpnConnectionState.connected);
      case ServiceState.stopping:
        _updateState(VpnConnectionState.disconnecting);
    }
  }

  void _updateState(VpnConnectionState newState) {
    _state = newState;
    _stateController.add(_state);
    if (newState == VpnConnectionState.connected) {
      _connectTime = DateTime.now();
      _startDurationTimer();
    } else if (newState == VpnConnectionState.disconnected ||
        newState == VpnConnectionState.error) {
      _stopDurationTimer();
      if (newState == VpnConnectionState.disconnected) {
        _activeServer = null;
      }
    }
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

  VpnLogLevel _mapLogLevel(LogLevel level) {
    switch (level) {
      case LogLevel.trace:
      case LogLevel.debug:
        return VpnLogLevel.debug;
      case LogLevel.info:
        return VpnLogLevel.info;
      case LogLevel.warn:
        return VpnLogLevel.warning;
      case LogLevel.error:
      case LogLevel.fatal:
      case LogLevel.panic:
        return VpnLogLevel.error;
    }
  }

  // ─── Duration timer ───

  void _startDurationTimer() {
    _stopDurationTimer();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_connectTime != null && _state == VpnConnectionState.connected) {
        final duration = DateTime.now().difference(_connectTime!);
        _stats = _stats.copyWith(duration: duration);
        _statsController.add(_stats);
      }
    });
  }

  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
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
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {}
  }

  Future<void> _saveServers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _servers.map((s) => _serverToJson(s)).toList();
      await prefs.setString('servers', jsonEncode(list));
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {}
  }

  Map<String, dynamic> _serverToJson(VpnServer s) => {
    'id': s.id,
    'name': s.name,
    'address': s.address,
    'port': s.port,
    'protocol': s.protocol.name,
    'security': s.security.name,
    'uuid': s.uuid,
    'sni': s.sni,
    'fingerprint': s.fingerprint,
    'publicKey': s.publicKey,
    'shortId': s.shortId,
    'path': s.path,
    'host': s.host,
    'alpn': s.alpn,
    'flow': s.flow,
    'mode': s.mode,
    'rawConfig': s.rawConfig,
    'isFavorite': s.isFavorite,
    'ping': s.ping,
    'country': s.country,
    'flag': s.flag,
  };

  VpnServer? _serverFromJson(Map<String, dynamic> m) {
    try {
      return VpnServer(
        id: m['id'] ?? '',
        name: m['name'] ?? '',
        address: m['address'] ?? '',
        port: m['port'] ?? 443,
        protocol: VpnProtocol.values.firstWhere(
          (p) => p.name == m['protocol'],
          orElse: () => VpnProtocol.vless,
        ),
        security: VpnSecurity.values.firstWhere(
          (s) => s.name == m['security'],
          orElse: () => VpnSecurity.none,
        ),
        uuid: m['uuid'],
        sni: m['sni'],
        fingerprint: m['fingerprint'],
        publicKey: m['publicKey'],
        shortId: m['shortId'],
        path: m['path'],
        host: m['host'],
        alpn: m['alpn'],
        flow: m['flow'],
        mode: m['mode'],
        rawConfig: Map<String, dynamic>.from(m['rawConfig'] ?? {}),
        isFavorite: m['isFavorite'] ?? false,
        ping: m['ping'],
        country: m['country'],
        flag: m['flag'],
      );
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return null;
    }
  }

  // ─── VpnService interface ───

  @override
  Future<bool> connect(VpnServer server) async {
    _activeServer = server;
    _accumulatedUpload = 0;
    _accumulatedDownload = 0;
    _updateState(VpnConnectionState.connecting);

    final config = SingboxConfigGenerator.generate(server);
    _addLog(
      VpnLogLevel.info,
      'Подключение к ${server.name} (${server.address}:${server.port})',
    );
    _addLog(
      VpnLogLevel.info,
      'Конфиг (${config.length} bytes): '
      '${config.length > 500 ? '${config.substring(0, 500)}...' : config}',
    );

    // Fire-and-forget: MethodChannel blocks main thread, so we don't await.
    // Result arrives via stateStream.
    unawaited(
      _client
          .connect(SessionOptions(config: config))
          .then((_) {
            _addLog(VpnLogLevel.info, 'connect OK');
          })
          .catchError((e) {
            _addLog(VpnLogLevel.error, 'connect FAILED: $e');
            _updateState(VpnConnectionState.error);
          }),
    );
    return true;
  }

  @override
  Future<bool> disconnect() async {
    _updateState(VpnConnectionState.disconnecting);
    unawaited(
      _client
          .disconnect()
          .then((_) {
            _addLog(VpnLogLevel.info, 'disconnect OK');
          })
          .catchError((e) {
            _addLog(VpnLogLevel.error, 'disconnect FAILED: $e');
          }),
    );
    return true;
  }

  @override
  Future<void> updateServers(List<VpnServer> servers) async {
    _servers
      ..clear()
      ..addAll(servers);
    _serversController.add(List.unmodifiable(_servers));
    await _saveServers();
  }

  @override
  Future<String> getStatus() async {
    try {
      final serviceState = await _client.getServiceState();
      return serviceState.name;
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return _state.name;
    }
  }

  @override
  Future<void> clearLogs() async {
    _logs.clear();
    _logController.add(
      VpnLogEntry(
        id: 'clear',
        timestamp: DateTime.now(),
        level: VpnLogLevel.info,
        message: 'Logs cleared',
      ),
    );
  }

  @override
  Future<List<InstalledApp>> getInstalledApps() async => [];

  @override
  Future<void> setPerAppProxyMode(String mode) async {
    // Not supported via flutter_singbox_client yet
  }

  @override
  Future<void> setPerAppProxyList(List<String> packages) async {
    // Not supported via flutter_singbox_client yet
  }

  @override
  Future<List<String>> getPerAppProxyList() async => [];

  @override
  Future<bool> copyConfigToClipboard(VpnServer server) async => false;

  @override
  Future<void> dispose() async {
    _stopDurationTimer();
    await _stateSub?.cancel();
    await _trafficSub?.cancel();
    await _logSub?.cancel();
    await _faultSub?.cancel();
    await _client.dispose();
    await _stateController.close();
    await _statsController.close();
    await _logController.close();
    await _serversController.close();
  }
}
