import 'dart:async';
import 'package:flutter/services.dart';
import '../data/models/vpn_models.dart';
import '../vpn/singbox_config_generator.dart';

class VpnService {
  static const _channel = MethodChannel('maxspeed.vpn');

  final _stateController = StreamController<VpnConnectionState>.broadcast();
  final _statsController = StreamController<VpnConnectionStats>.broadcast();
  final _logController = StreamController<VpnLogEntry>.broadcast();

  VpnConnectionState _state = VpnConnectionState.disconnected;
  VpnServer? _activeServer;
  VpnConnectionStats _stats = const VpnConnectionStats();
  final List<VpnLogEntry> _logs = [];
  Timer? _statsTimer;

  Stream<VpnConnectionState> get stateStream => _stateController.stream;
  Stream<VpnConnectionStats> get statsStream => _statsController.stream;
  Stream<VpnLogEntry> get logStream => _logController.stream;
  VpnConnectionState get state => _state;
  VpnServer? get activeServer => _activeServer;
  VpnConnectionStats get stats => _stats;
  List<VpnLogEntry> get logs => List.unmodifiable(_logs);

  VpnService() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onStateChanged':
        final stateStr = call.arguments as String?;
        if (stateStr != null) {
          _state = _parseState(stateStr);
          _stateController.add(_state);
        }
        break;
      case 'onStats':
        final args = call.arguments as Map?;
        if (args != null) {
          _stats = VpnConnectionStats(
            bytesSent: args['bytesSent'] as int? ?? 0,
            bytesReceived: args['bytesReceived'] as int? ?? 0,
            uploadSpeed: args['uploadSpeed'] as int? ?? 0,
            downloadSpeed: args['downloadSpeed'] as int? ?? 0,
            duration: Duration(seconds: args['duration'] as int? ?? 0),
            pingMs: args['pingMs'] as int?,
            serverName: args['serverName'] as String?,
          );
          _statsController.add(_stats);
        }
        break;
      case 'onLog':
        final args = call.arguments as Map?;
        if (args != null) {
          final entry = VpnLogEntry(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            timestamp: DateTime.now(),
            level: _parseLogLevel(args['level'] as String? ?? 'info'),
            message: args['message'] as String? ?? '',
            details: args['details'] as String?,
          );
          _logs.add(entry);
          if (_logs.length > 1000) _logs.removeAt(0);
          _logController.add(entry);
        }
        break;
    }
  }

  VpnConnectionState _parseState(String s) {
    switch (s) {
      case 'connected': return VpnConnectionState.connected;
      case 'connecting': return VpnConnectionState.connecting;
      case 'disconnecting': return VpnConnectionState.disconnecting;
      case 'error': return VpnConnectionState.error;
      case 'reconnecting': return VpnConnectionState.reconnecting;
      default: return VpnConnectionState.disconnected;
    }
  }

  VpnLogLevel _parseLogLevel(String s) {
    switch (s) {
      case 'debug': return VpnLogLevel.debug;
      case 'warning': return VpnLogLevel.warning;
      case 'error': return VpnLogLevel.error;
      default: return VpnLogLevel.info;
    }
  }

  Future<bool> connect(VpnServer server) async {
    try {
      _state = VpnConnectionState.connecting;
      _stateController.add(_state);
      _activeServer = server;

      final config = SingboxConfigGenerator.generate(server);
      _addLog(VpnLogLevel.info, 'Generating sing-box config for ${server.displayName}');

      final result = await _channel.invokeMethod<bool>('connect', {
        'config': config,
        'serverName': server.displayName,
      });

      if (result == true) {
        _state = VpnConnectionState.connected;
        _stateController.add(_state);
        _startStatsTimer();
        _addLog(VpnLogLevel.info, 'Connected to ${server.displayName}');
        return true;
      } else {
        _state = VpnConnectionState.error;
        _stateController.add(_state);
        _addLog(VpnLogLevel.error, 'Failed to connect to ${server.displayName}');
        return false;
      }
    } catch (e) {
      _state = VpnConnectionState.error;
      _stateController.add(_state);
      _addLog(VpnLogLevel.error, 'Connection error: $e');
      return false;
    }
  }

  Future<bool> disconnect() async {
    try {
      _state = VpnConnectionState.disconnecting;
      _stateController.add(_state);
      _stopStatsTimer();

      final result = await _channel.invokeMethod<bool>('disconnect');
      _state = VpnConnectionState.disconnected;
      _stateController.add(_state);
      _activeServer = null;
      _stats = const VpnConnectionStats();
      _addLog(VpnLogLevel.info, 'Disconnected');
      return result ?? true;
    } catch (e) {
      _state = VpnConnectionState.disconnected;
      _stateController.add(_state);
      _addLog(VpnLogLevel.error, 'Disconnect error: $e');
      return false;
    }
  }

  Future<bool> ping(VpnServer server) async {
    try {
      final result = await _channel.invokeMethod<int>('ping', {
        'host': server.address,
        'port': server.port,
      });
      return result != null && result > 0;
    } catch (e) {
      return false;
    }
  }

  void _startStatsTimer() {
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _channel.invokeMethod('getStats');
    });
  }

  void _stopStatsTimer() {
    _statsTimer?.cancel();
    _statsTimer = null;
  }

  void _addLog(VpnLogLevel level, String message) {
    final entry = VpnLogEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      level: level,
      message: message,
    );
    _logs.add(entry);
    if (_logs.length > 1000) _logs.removeAt(0);
    _logController.add(entry);
  }

  void clearLogs() {
    _logs.clear();
    _addLog(VpnLogLevel.info, 'Logs cleared');
  }

  void dispose() {
    _stopStatsTimer();
    _stateController.close();
    _statsController.close();
    _logController.close();
  }
}
