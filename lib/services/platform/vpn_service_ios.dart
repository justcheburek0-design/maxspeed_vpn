import 'dart:async';

import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/vpn_models.dart';
import '../../vpn/singbox_config_generator.dart';
import '../vpn_service_interface.dart';

/// iOS реализация VPN сервиса через NetworkExtension.
///
/// Требует Packet Tunnel Provider extension для реального VPN.
/// Сейчас — skeleton с platform channel.
class IosVpnService implements VpnService {
  static const _channel = MethodChannel('maxspeed/vpn');

  final _stateController = StreamController<VpnConnectionState>.broadcast();
  final _statsController = StreamController<VpnConnectionStats>.broadcast();
  final _logController = StreamController<VpnLogEntry>.broadcast();

  VpnConnectionState _state = VpnConnectionState.disconnected;
  VpnServer? _activeServer;
  VpnConnectionStats _stats = const VpnConnectionStats();
  final List<VpnLogEntry> _logs = [];
  final List<VpnServer> _servers = [];
  final _serversController = StreamController<List<VpnServer>>.broadcast();

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
  @override
  List<VpnServer> get servers => List.unmodifiable(_servers);
  @override
  Stream<List<VpnServer>> get serversStream => _serversController.stream;

  IosVpnService() {
    _addLog(VpnLogLevel.info, '${AppConstants.appName} iOS VPN инициализирован');
  }

  @override
  Future<bool> connect(VpnServer server) async {
    try {
      _addLog(VpnLogLevel.info, 'Подключение к ${server.name}...');

      // Save config to shared storage for tunnel extension
      final config = SingboxConfigGenerator.generate(server);
      await _channel.invokeMethod('saveConfig', {'config': config});

      // Try to connect via platform channel
      // This will fail until Packet Tunnel Provider is implemented
      final result = await _channel.invokeMethod<bool>('connect');
      if (result == true) {
        _activeServer = server;
        _state = VpnConnectionState.connected;
        _stateController.add(_state);
        return true;
      }

      _addLog(VpnLogLevel.warning, 'iOS VPN требует NetworkExtension (в разработке)');
      _state = VpnConnectionState.disconnected;
      _stateController.add(_state);
      return false;
    } on PlatformException catch (e) {
      _addLog(VpnLogLevel.error, 'Ошибка: ${e.message}');
      _state = VpnConnectionState.error;
      _stateController.add(_state);
      return false;
    } catch (e) {
      _addLog(VpnLogLevel.error, 'Ошибка подключения: $e');
      _state = VpnConnectionState.error;
      _stateController.add(_state);
      return false;
    }
  }

  @override
  Future<bool> disconnect() async {
    try {
      _addLog(VpnLogLevel.info, 'Отключение VPN...');
      await _channel.invokeMethod('disconnect');
      _state = VpnConnectionState.disconnected;
      _activeServer = null;
      _stateController.add(_state);
      return true;
    } catch (e) {
      _addLog(VpnLogLevel.error, 'Ошибка отключения: $e');
      return false;
    }
  }

  @override
  Future<String> getStatus() async {
    try {
      final status = await _channel.invokeMethod<String>('getStatus');
      return status ?? 'unknown';
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
  Future<void> clearLogs() async {
    _logs.clear();
  }

  @override
  Future<void> updateServers(List<VpnServer> servers) async {
    _servers.clear();
    _servers.addAll(servers);
    _serversController.add(List.unmodifiable(_servers));
    _addLog(VpnLogLevel.info, 'Обновлено серверов: ${servers.length}');
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
  void dispose() {
    _stateController.close();
    _statsController.close();
    _logController.close();
    _serversController.close();
  }
}
