import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:maxspeed_vpn/core/constants/app_constants.dart';
import 'package:maxspeed_vpn/data/models/vpn_models.dart';
import 'package:maxspeed_vpn/services/vpn_service_interface.dart';

/// iOS VPN via NetworkExtension platform channel.
///
/// Channel: maxspeed/vpn
/// Methods: connect, disconnect, getStatus, saveConfig
/// Events: onStatusChanged (from native side via EventChannel)
class IosVpnService implements VpnService {
  static const _channel = MethodChannel('maxspeed/vpn');
  static const _eventChannel = EventChannel('maxspeed/vpn/status');

  final _stateController = StreamController<VpnConnectionState>.broadcast();
  final _statsController = StreamController<VpnConnectionStats>.broadcast();
  final _logController = StreamController<VpnLogEntry>.broadcast();

  VpnConnectionState _state = VpnConnectionState.disconnected;
  VpnServer? _activeServer;
  VpnConnectionStats _stats = const VpnConnectionStats();
  final List<VpnLogEntry> _logs = [];
  final List<VpnServer> _servers = [];
  final _serversController = StreamController<List<VpnServer>>.broadcast();

  StreamSubscription<dynamic>? _statusSub;
  DateTime? _connectTime;
  Timer? _statsTimer;

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

  IosVpnService() {
    _addLog(VpnLogLevel.info, '${AppConstants.appName} iOS VPN init');
    _statusSub = _eventChannel.receiveBroadcastStream().listen(_onStatusEvent);
  }

  void _onStatusEvent(dynamic event) {
    if (event is String) {
      _addLog(VpnLogLevel.debug, 'Native status: $event');
      switch (event) {
        case 'connected':
          _setState(VpnConnectionState.connected);
          _connectTime = DateTime.now();
          _startStatsTimer();
        case 'disconnected':
          _setState(VpnConnectionState.disconnected);
          _activeServer = null;
          _stopStatsTimer();
        case 'connecting':
          _setState(VpnConnectionState.connecting);
        case 'error':
          _setState(VpnConnectionState.error);
      }
    }
  }

  @override
  Future<bool> connect(VpnServer server) async {
    try {
      _addLog(VpnLogLevel.info, 'Connecting to ${server.name}...');
      _setState(VpnConnectionState.connecting);

      final result = await _channel.invokeMethod<bool>('connect', {
        'address': server.address,
        'port': server.port,
        'uuid': server.uuid,
        'protocol': server.protocol,
        'name': server.name,
      });

      if (result == true) {
        _activeServer = server;
        // State will be updated by native status event
        return true;
      }

      _addLog(VpnLogLevel.warning, 'iOS VPN requires NetworkExtension');
      _setState(VpnConnectionState.disconnected);
      return false;
    } on PlatformException catch (e) {
      _addLog(VpnLogLevel.error, 'Platform error: ${e.message}');
      _setState(VpnConnectionState.error);
      return false;
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      _addLog(VpnLogLevel.error, 'Connect error: $e');
      _setState(VpnConnectionState.error);
      return false;
    }
  }

  @override
  Future<bool> disconnect() async {
    try {
      _addLog(VpnLogLevel.info, 'Disconnecting...');
      await _channel.invokeMethod('disconnect');
      _setState(VpnConnectionState.disconnected);
      _activeServer = null;
      _stopStatsTimer();
      return true;
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      _addLog(VpnLogLevel.error, 'Disconnect error: $e');
      return false;
    }
  }

  @override
  Future<String> getStatus() async {
    try {
      final s = await _channel.invokeMethod<String>('getStatus');
      return s ?? 'unknown';
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return 'error';
    }
  }

  @override
  Future<List<InstalledApp>> getInstalledApps() async => [];

  @override
  Future<void> setPerAppProxyMode(String mode) async {}

  @override
  Future<void> setPerAppProxyList(List<String> packages) async {}

  @override
  Future<List<String>> getPerAppProxyList() async => [];

  @override
  Future<void> clearLogs() async => _logs.clear();

  @override
  Future<void> updateServers(List<VpnServer> servers) async {
    _servers
      ..clear()
      ..addAll(servers);
    _serversController.add(List.unmodifiable(_servers));
    _addLog(VpnLogLevel.info, 'Servers updated: ${servers.length}');
  }

  // ── Stats timer (iOS doesn't have local stats API — track duration) ──

  void _startStatsTimer() {
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_connectTime == null) return;
      final duration = DateTime.now().difference(_connectTime!);
      _stats = VpnConnectionStats(duration: duration);
      _statsController.add(_stats);
    });
  }

  void _stopStatsTimer() {
    _statsTimer?.cancel();
    _statsTimer = null;
    _stats = const VpnConnectionStats();
    _statsController.add(_stats);
  }

  // ── Helpers ──

  void _setState(VpnConnectionState s) {
    _state = s;
    _stateController.add(s);
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
    if (kDebugMode) print('[VPN][${level.name}] $message');
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _stopStatsTimer();
    _stateController.close();
    _statsController.close();
    _logController.close();
    _serversController.close();
  }

  @override
  Future<bool> copyConfigToClipboard(VpnServer server) async => false;
}
