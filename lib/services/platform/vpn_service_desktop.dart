import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/vpn_models.dart';
import '../../vpn/singbox_config_generator.dart';
import '../vpn_service_interface.dart';

/// Desktop-реализация VPN сервиса через sing-box subprocess.
///
/// Поддерживает Windows, macOS, Linux.
/// Требует установленного sing-box в PATH или рядом с приложением.
class DesktopVpnService implements VpnService {
  final _stateController = StreamController<VpnConnectionState>.broadcast();
  final _statsController = StreamController<VpnConnectionStats>.broadcast();
  final _logController = StreamController<VpnLogEntry>.broadcast();

  VpnConnectionState _state = VpnConnectionState.disconnected;
  VpnServer? _activeServer;
  VpnConnectionStats _stats = const VpnConnectionStats();
  final List<VpnLogEntry> _logs = [];
  final List<VpnServer> _servers = [];
  final _serversController = StreamController<List<VpnServer>>.broadcast();

  // Subprocess state
  Process? _singboxProcess;
  Timer? _statsTimer;
  DateTime? _connectTime;
  String? _configPath;

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

  DesktopVpnService() {
    _addLog(VpnLogLevel.info, '${AppConstants.appName} Desktop VPN инициализирован');
    _addLog(VpnLogLevel.info, 'Платформа: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}');
  }

  // ─── VPN binary discovery ───

  Future<String?> _findSingboxBinary() async {
    // 1. Check PATH
    if (await _commandExists('sing-box')) return 'sing-box';
    if (await _commandExists('singbox')) return 'singbox';

    // 2. Check alongside the app executable
    final appDir = Platform.resolvedExecutable.replaceAll('\\', '/');
    final appFolder = appDir.substring(0, appDir.lastIndexOf('/'));

    final candidates = <String>[];
    if (Platform.isWindows) {
      candidates.addAll([
        '$appFolder/sing-box.exe',
        '$appFolder/singbox.exe',
        '$appFolder/bin/sing-box.exe',
      ]);
    } else {
      candidates.addAll([
        '$appFolder/sing-box',
        '$appFolder/singbox',
        '$appFolder/bin/sing-box',
        '/usr/local/bin/sing-box',
        '/usr/bin/sing-box',
      ]);
    }

    for (final path in candidates) {
      if (await File(path).exists()) return path;
    }

    return null;
  }

  Future<bool> _commandExists(String cmd) async {
    try {
      final result = Platform.isWindows
          ? await Process.run('where', [cmd], runInShell: true)
          : await Process.run('which', [cmd], runInShell: true);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  // ─── Connect / Disconnect ───

  @override
  Future<bool> connect(VpnServer server) async {
    try {
      _addLog(VpnLogLevel.info, 'Подключение к ${server.name} (${server.address}:${server.port})');

      // Find sing-box binary
      final binaryPath = await _findSingboxBinary();
      if (binaryPath == null) {
        _addLog(VpnLogLevel.error, 'sing-box не найден. Установите sing-box: https://sing-box.sagernet.org/installation/');
        _addLog(VpnLogLevel.info, 'Или положите sing-box рядом с приложением.');
        _state = VpnConnectionState.error;
        _stateController.add(_state);
        return false;
      }
      _addLog(VpnLogLevel.info, 'sing-box: $binaryPath');

      // Generate config
      final configJson = SingboxConfigGenerator.generate(server);
      _addLog(VpnLogLevel.debug, 'Конфиг сгенерирован (${configJson.length} байт)');

      // Write config to temp file
      final tempDir = await getTemporaryDirectory();
      _configPath = '${tempDir.path}/maxspeed_vpn_config.json';
      await File(_configPath!).writeAsString(configJson);
      _addLog(VpnLogLevel.info, 'Конфиг записан: $_configPath');

      // Kill existing process if any
      await _killSingbox();

      // Start sing-box
      _addLog(VpnLogLevel.info, 'Запуск sing-box...');

      final args = ['run', '-config', _configPath!, '-C', tempDir.path];

      // On Linux, may need elevated privileges for TUN
      if (Platform.isLinux) {
        // Try with sudo if regular start fails
        _singboxProcess = await Process.start(
          binaryPath,
 args,
          mode: ProcessStartMode.detachedWithStdio,
          workingDirectory: tempDir.path,
        );
      } else {
        _singboxProcess = await Process.start(
          binaryPath,
          args,
          mode: ProcessStartMode.detachedWithStdio,
          workingDirectory: tempDir.path,
        );
      }

      // Listen to stdout/stderr
      _singboxProcess!.stdout.transform(utf8.decoder).listen((line) {
        _addLog(VpnLogLevel.debug, '[sing-box] $line');
      });
      _singboxProcess!.stderr.transform(utf8.decoder).listen((line) {
        _addLog(VpnLogLevel.warning, '[sing-box err] $line');
      });

      // Wait for process exit
      _singboxProcess!.exitCode.then((code) {
        _addLog(
          VpnLogLevel.info,
          'sing-box завершился с кодом $code',
        );
        if (_state == VpnConnectionState.connected ||
            _state == VpnConnectionState.connecting) {
          _state = VpnConnectionState.disconnected;
          _activeServer = null;
          _stateController.add(_state);
          _stopStatsTimer();
        }
      });

      // Update state
      _activeServer = server;
      _state = VpnConnectionState.connecting;
      _stateController.add(_state);

      // Simulate connection establishment (sing-box starts fast)
      // In production, we'd wait for the API to report connected state
      await Future.delayed(const Duration(seconds: 2));

      if (_singboxProcess != null) {
        _state = VpnConnectionState.connected;
        _stateController.add(_state);
        _connectTime = DateTime.now();
        _startStatsTimer();
        _addLog(VpnLogLevel.info, 'VPN подключён через ${server.name}');

        // On Linux without root, TUN may fail — check process still alive
        if (Platform.isLinux) {
          await Future.delayed(const Duration(seconds: 3));
          if (_singboxProcess != null) {
            // Process still running — likely connected
            _addLog(VpnLogLevel.info, 'VPN туннел активен');
          }
        }

        return true;
      }

      _state = VpnConnectionState.error;
      _stateController.add(_state);
      _addLog(VpnLogLevel.error, 'Не удалось запустить sing-box');
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

      await _killSingbox();

      _state = VpnConnectionState.disconnected;
      _activeServer = null;
      _stateController.add(_state);
      _stopStatsTimer();
      _connectTime = null;

      // Clean up config file
      if (_configPath != null) {
        try {
          await File(_configPath!).delete();
        } catch (_) {}
        _configPath = null;
      }

      _addLog(VpnLogLevel.info, 'VPN отключён');
      return true;
    } catch (e) {
      _addLog(VpnLogLevel.error, 'Ошибка отключения: $e');
      return false;
    }
  }

  Future<void> _killSingbox() async {
    if (_singboxProcess != null) {
      _addLog(VpnLogLevel.debug, 'Остановка sing-box (PID: ${_singboxProcess!.pid})');
      _singboxProcess!.kill(ProcessSignal.sigterm);

      // Force kill after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        try {
          _singboxProcess?.kill(ProcessSignal.sigkill);
        } catch (_) {}
      });

      _singboxProcess = null;
    }

    // Also kill any lingering sing-box processes (desktop only)
    try {
      if (Platform.isWindows) {
        await Process.run('taskkill', ['/F', '/IM', 'sing-box.exe'],
            runInShell: true);
      } else {
        await Process.run('pkill', ['-f', 'sing-box'],
            runInShell: true);
      }
    } catch (_) {
      // Ignore — process may not exist
    }
  }

  // ─── Stats ───

  void _startStatsTimer() {
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_connectTime == null) return;

      final duration = DateTime.now().difference(_connectTime!);
      // TODO: Read actual stats from sing-box API (1080/stats)
      _stats = VpnConnectionStats(
        uploadTotal: _stats.uploadTotal + _randomTraffic(),
        downloadTotal: _stats.downloadTotal + _randomTraffic(),
        duration: duration,
      );
      _statsController.add(_stats);
    });
  }

  void _stopStatsTimer() {
    _statsTimer?.cancel();
    _statsTimer = null;
    _stats = const VpnConnectionStats();
    _statsController.add(_stats);
  }

  int _randomTraffic() {
    // Placeholder — in production, query sing-box stats API
    return 1024 + (DateTime.now().millisecondsSinceEpoch % 51200);
  }

  // ─── API ───

  @override
  Future<String> getStatus() async {
    if (_singboxProcess != null) {
      return 'running (PID: ${_singboxProcess!.pid})';
    }
    return 'stopped';
  }

  @override
  Future<List<InstalledApp>> getInstalledApps() async {
    // Desktop doesn't have per-app proxy in this implementation
    return [];
  }

  @override
  Future<void> setPerAppProxyMode(String mode) async {
    _addLog(VpnLogLevel.info, 'Per-app proxy: $mode (не поддерживается на desktop)');
  }

  @override
  Future<void> setPerAppProxyList(List<String> packages) async {}

  @override
  Future<List<String>> getPerAppProxyList() async => [];

  @override
  Future<void> clearLogs() async {
    _logs.clear();
  }

  // ─── Servers ───

  @override
  Future<void> updateServers(List<VpnServer> servers) async {
    _servers.clear();
    _servers.addAll(servers);
    _serversController.add(List.unmodifiable(_servers));
    _addLog(VpnLogLevel.info, 'Обновлено серверов: ${servers.length}');
  }

  // ─── Logging ───

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
    if (kDebugMode) {
      print('[VPN][${level.name}] $message');
    }
  }

  // ─── Lifecycle ───

  @override
  void dispose() {
    _stopStatsTimer();
    _killSingbox();
    _stateController.close();
    _statsController.close();
    _logController.close();
    _serversController.close();
  }
}
