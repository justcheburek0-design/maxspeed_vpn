import 'dart:async';
import 'package:maxspeed_vpn/data/models/vpn_models.dart';

/// Абстрактный VPN сервис — платформонезависимый интерфейс.
/// Каждая платформа предоставляет свою реализацию.
abstract class VpnService {
  Stream<VpnConnectionState> get stateStream;
  Stream<VpnConnectionStats> get statsStream;
  Stream<VpnLogEntry> get logStream;
  VpnConnectionState get state;
  VpnServer? get activeServer;
  VpnConnectionStats get stats;
  List<VpnLogEntry> get logs;
  List<VpnServer> get servers;
  Stream<List<VpnServer>> get serversStream;

  /// Download progress stream (0.0 to 1.0). Only used on desktop.
  /// Override in platform implementations that support it.
  Stream<double> get downloadProgressStream;

  Future<bool> connect(VpnServer server);
  Future<bool> disconnect();
  Future<void> updateServers(List<VpnServer> servers);
  Future<String> getStatus();
  Future<void> clearLogs();

  /// Получить список установленных приложений (только Android).
  /// На других платформах возвращает пустой список.
  Future<List<InstalledApp>> getInstalledApps();

  /// Установить режим per-app прокси (только Android).
  Future<void> setPerAppProxyMode(String mode);
  Future<void> setPerAppProxyList(List<String> packages);
  Future<List<String>> getPerAppProxyList();

  /// Copy config to clipboard (web). Returns false on other platforms.
  Future<bool> copyConfigToClipboard(VpnServer server) async => false;

  void dispose();
}
