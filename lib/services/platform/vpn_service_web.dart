import 'dart:async';

import 'package:flutter/services.dart';

import '../../data/models/vpn_models.dart';
import '../../vpn/singbox_config_generator.dart';
import '../vpn_service_interface.dart';

/// Web implementation — no VPN in browser.
/// Features: subscription management, config export, clipboard copy.
class WebVpnService implements VpnService {
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

  WebVpnService() {
    _addLog(VpnLogLevel.info, 'MaxSpeedVPN Web');
    _addLog(VpnLogLevel.info, 'VPN unavailable in browser — use native client');
  }

  /// Generate config and copy to clipboard. Returns true if copied.
  Future<bool> copyConfigToClipboard(VpnServer server) async {
    try {
      final config = SingboxConfigGenerator.generate(server);
      await Clipboard.setData(ClipboardData(text: config));
      _addLog(
        VpnLogLevel.info,
        'Config for ${server.name} copied to clipboard',
      );
      return true;
    } catch (e) {
      _addLog(VpnLogLevel.error, 'Clipboard error: $e');
      return false;
    }
  }

  /// Generate shareable URI for the server
  String getShareText(VpnServer server) {
    if (server.rawLink.isNotEmpty) return server.rawLink;
    return '${server.protocol.displayName.toLowerCase()}://${server.address}:${server.port}';
  }

  @override
  Future<bool> connect(VpnServer server) async {
    _addLog(VpnLogLevel.warning, 'VPN unavailable in browser');
    return false;
  }

  @override
  Future<bool> disconnect() async => true;

  @override
  Future<String> getStatus() async => 'web';

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
  Future<void> clearLogs() async => _logs.clear();

  @override
  Future<void> updateServers(List<VpnServer> servers) async {
    _servers.clear();
    _servers.addAll(servers);
    _serversController.add(List.unmodifiable(_servers));
  }

  @override
  void dispose() {
    _stateController.close();
    _statsController.close();
    _logController.close();
    _serversController.close();
  }
}
