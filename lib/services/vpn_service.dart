import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_singbox_vpn/flutter_singbox.dart';
import '../data/models/vpn_models.dart';
import '../vpn/singbox_config_generator.dart';

class VpnService {
  final FlutterSingbox _singbox = FlutterSingbox();

  final _stateController = StreamController<VpnConnectionState>.broadcast();
  final _statsController = StreamController<VpnConnectionStats>.broadcast();
  final _logController = StreamController<VpnLogEntry>.broadcast();

  VpnConnectionState _state = VpnConnectionState.disconnected;
  VpnServer? _activeServer;
  VpnConnectionStats _stats = const VpnConnectionStats();
  final List<VpnLogEntry> _logs = [];
  int _accumulatedUpload = 0;
  int _accumulatedDownload = 0;
  DateTime? _connectTime;
  Timer? _durationTimer;

  Stream<VpnConnectionState> get stateStream => _stateController.stream;
  Stream<VpnConnectionStats> get statsStream => _statsController.stream;
  Stream<VpnLogEntry> get logStream => _logController.stream;
  VpnConnectionState get state => _state;
  VpnServer? get activeServer => _activeServer;
  VpnConnectionStats get stats => _stats;
  List<VpnLogEntry> get logs => List.unmodifiable(_logs);

  VpnService() {
    _singbox.onStatusChanged.listen((statusMap) {
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

  Future<bool> connect(VpnServer server) async {
    try {
      _activeServer = server;
      _state = VpnConnectionState.connecting;
      _stateController.add(_state);
      _accumulatedUpload = 0;
      _accumulatedDownload = 0;

      // Save config and start VPN (plugin handles VpnService.prepare internally)
      final config = SingboxConfigGenerator.generate(server);
      await _singbox.saveConfig(config);
      final started = await _singbox.startVPN();

      if (!started) {
        _state = VpnConnectionState.error;
        _activeServer = null;
        _stateController.add(_state);
        _addLog(VpnLogLevel.error, 'Failed to start VPN');
      }

      return started;
    } catch (e) {
      _state = VpnConnectionState.error;
      _activeServer = null;
      _stateController.add(_state);
      _addLog(VpnLogLevel.error, 'Connection error: $e');
      return false;
    }
  }

  Future<bool> disconnect() async {
    try {
      _state = VpnConnectionState.disconnecting;
      _stateController.add(_state);
      final stopped = await _singbox.stopVPN();
      return stopped;
    } catch (e) {
      return false;
    }
  }

  Future<String> getStatus() async {
    return await _singbox.getVPNStatus();
  }

  Future<List<Map<String, dynamic>>> getInstalledApps() async {
    return await _singbox.getInstalledApps();
  }

  Future<void> setPerAppProxyMode(String mode) async {
    await _singbox.setPerAppProxyMode(mode);
  }

  Future<void> setPerAppProxyList(List<String> packages) async {
    await _singbox.setPerAppProxyList(packages);
  }

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

  Future<void> clearLogs() async {
    _logs.clear();
    await _singbox.clearLogs();
  }

  void dispose() {
    _durationTimer?.cancel();
    _stateController.close();
    _statsController.close();
    _logController.close();
  }
}
