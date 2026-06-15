import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:maxspeed_vpn/core/constants/app_constants.dart';
import 'package:maxspeed_vpn/data/models/vpn_models.dart';
import 'package:maxspeed_vpn/vpn/singbox_config_generator.dart';
import 'package:maxspeed_vpn/services/vpn_service_interface.dart';
import 'package:maxspeed_vpn/services/platform/singbox_downloader.dart';

/// Desktop VPN via sing-box subprocess.
///
/// sing-box exposes a REST API on localhost:1080 by default.
/// Stats are fetched from http://127.0.0.1:1080/traffic.
class DesktopVpnService implements VpnService {
  final _stateController = StreamController<VpnConnectionState>.broadcast();
  final _statsController = StreamController<VpnConnectionStats>.broadcast();
  final _logController = StreamController<VpnLogEntry>.broadcast();
  final _downloadProgressController = StreamController<double>.broadcast();

  VpnConnectionState _state = VpnConnectionState.disconnected;
  VpnServer? _activeServer;
  VpnConnectionStats _stats = const VpnConnectionStats();
  final List<VpnLogEntry> _logs = [];
  final List<VpnServer> _servers = [];
  final _serversController = StreamController<List<VpnServer>>.broadcast();

  Process? _process;
  Timer? _statsTimer;
  DateTime? _connectTime;
  String? _configPath;
  final int _apiPort = 1080;

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

  /// Download progress stream (0.0 to 1.0).
  @override
  Stream<double> get downloadProgressStream =>
      _downloadProgressController.stream;

  DesktopVpnService() {
    _addLog(VpnLogLevel.info, '${AppConstants.appName} Desktop VPN init');
    _addLog(
      VpnLogLevel.info,
      'OS: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
    );
  }

  // ── Binary discovery ──

  Future<String?> _findSingbox() async {
    for (final name in ['sing-box', 'singbox']) {
      if (await _which(name)) return name;
    }
    final appFolder = Platform.resolvedExecutable.replaceAll('\\', '/');
    final dir = appFolder.substring(0, appFolder.lastIndexOf('/'));
    final suffix = Platform.isWindows ? '.exe' : '';
    for (final p in [
      '$dir/sing-box$suffix',
      '$dir/singbox$suffix',
      '$dir/bin/sing-box$suffix',
      '/usr/local/bin/sing-box',
      '/usr/bin/sing-box',
    ]) {
      if (await File(p).exists()) return p;
    }
    return null;
  }

  Future<bool> _which(String cmd) async {
    try {
      final r = Platform.isWindows
          ? await Process.run('where', [cmd], runInShell: true)
          : await Process.run('which', [cmd], runInShell: true);
      return r.exitCode == 0;
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return false;
    }
  }

  // ── Connect ──

  @override
  Future<bool> connect(VpnServer server) async {
    try {
      _addLog(
        VpnLogLevel.info,
        'Connecting to ${server.name} (${server.address}:${server.port})',
      );

      // Check internet connectivity first
      if (!await _checkInternet()) {
        _addLog(
          VpnLogLevel.error,
          'No internet connection. Check your network.',
        );
        _setState(VpnConnectionState.error);
        return false;
      }

      var bin = await _findSingbox();
      if (bin == null) {
        _addLog(VpnLogLevel.info, 'sing-box not found, downloading...');

        // Check if already downloaded by our downloader
        if (await SingboxDownloader.isDownloaded()) {
          bin = await SingboxDownloader.binaryPath;
          _addLog(VpnLogLevel.info, 'Found cached sing-box: $bin');
        } else {
          // Download from GitHub
          _setState(
            VpnConnectionState.connecting,
          ); // show connecting state during download
          final downloaded = await SingboxDownloader.download(
            onProgress: (received, total) {
              if (total > 0) {
                final pct = received / total;
                _downloadProgressController.add(pct);
              }
            },
          );
          if (downloaded != null) {
            bin = downloaded;
            _addLog(VpnLogLevel.info, 'sing-box downloaded: $bin');
          } else {
            _addLog(
              VpnLogLevel.error,
              'Failed to download sing-box. Check internet or install manually: https://sing-box.sagernet.org/installation/',
            );
            _setState(VpnConnectionState.error);
            return false;
          }
        }
      }
      _addLog(VpnLogLevel.info, 'sing-box: $bin');

      // Generate config with API enabled
      final configJson = SingboxConfigGenerator.generate(server);
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      _configPath = '$exeDir\\maxspeed_vpn_config.json';
      await File(_configPath!).writeAsString(configJson);

      await _killSingbox();
      _process = null;

      _addLog(VpnLogLevel.info, 'Starting sing-box...');
      _process = await Process.start(
        bin,
        ['run', '-config', _configPath!, '-C', exeDir],
        workingDirectory: exeDir,
        runInShell: Platform.isWindows,
      );

      // Log stdout/stderr
      _process!.stdout.transform(utf8.decoder).listen((line) {
        _addLog(VpnLogLevel.debug, '[sb] $line');
      });
      _process!.stderr.transform(utf8.decoder).listen((line) {
        _addLog(VpnLogLevel.warning, '[sb!] $line');
      });

      unawaited(
        _process!.exitCode.then((code) {
          _addLog(VpnLogLevel.info, 'sing-box exited: $code');
          if (_state == VpnConnectionState.connected ||
              _state == VpnConnectionState.connecting) {
            _setState(VpnConnectionState.disconnected);
            _activeServer = null;
            _stopStatsTimer();
          }
        }),
      );

      _activeServer = server;
      _setState(VpnConnectionState.connecting);

      // Wait for sing-box API to become available (max 10s)
      if (await _waitForApi(timeout: const Duration(seconds: 10))) {
        _setState(VpnConnectionState.connected);
        _connectTime = DateTime.now();
        _startStatsTimer();
        _addLog(VpnLogLevel.info, 'VPN connected via ${server.name}');
        return true;
      }

      // If API didn't respond but process is still running, assume connected
      if (_process != null) {
        _setState(VpnConnectionState.connected);
        _connectTime = DateTime.now();
        _startStatsTimer();
        _addLog(VpnLogLevel.info, 'VPN connected (API check skipped)');
        return true;
      }

      _setState(VpnConnectionState.error);
      _addLog(VpnLogLevel.error, 'sing-box failed to start');
      return false;
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      _addLog(VpnLogLevel.error, 'Connect error: $e');
      _setState(VpnConnectionState.error);
      return false;
    }
  }

  Future<bool> _waitForApi({required Duration timeout}) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      try {
        final r = await http
            .get(Uri.parse('http://127.0.0.1:$_apiPort/'))
            .timeout(const Duration(seconds: 1));
        if (r.statusCode < 500) return true;
        // ignore: avoid_catches_without_on_clauses
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 300));
    }
    return false;
  }

  // ── Disconnect ──

  @override
  Future<bool> disconnect() async {
    try {
      _addLog(VpnLogLevel.info, 'Disconnecting...');
      await _killSingbox();
      _setState(VpnConnectionState.disconnected);
      _activeServer = null;
      _stopStatsTimer();
      _connectTime = null;
      if (_configPath != null) {
        try {
          await File(_configPath!).delete();
          // ignore: avoid_catches_without_on_clauses
        } catch (_) {}
        _configPath = null;
      }
      _addLog(VpnLogLevel.info, 'VPN disconnected');
      return true;
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      _addLog(VpnLogLevel.error, 'Disconnect error: $e');
      return false;
    }
  }

  Future<void> _killSingbox() async {
    if (_process != null) {
      _addLog(VpnLogLevel.debug, 'Killing sing-box PID: ${_process!.pid}');
      _process!.kill();
      Future.delayed(const Duration(seconds: 3), () {
        try {
          _process?.kill(ProcessSignal.sigkill);
          // ignore: avoid_catches_without_on_clauses
        } catch (_) {}
      });
      _process = null;
    }
    try {
      if (Platform.isWindows) {
        await Process.run('taskkill', [
          '/F',
          '/IM',
          'sing-box.exe',
        ], runInShell: true);
      } else {
        await Process.run('pkill', ['-f', 'sing-box'], runInShell: true);
      }
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {}
  }

  // ── Stats from sing-box API ──

  void _startStatsTimer() {
    _statsTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _fetchStats(),
    );
  }

  void _stopStatsTimer() {
    _statsTimer?.cancel();
    _statsTimer = null;
    _stats = const VpnConnectionStats();
    _statsController.add(_stats);
  }

  Future<void> _fetchStats() async {
    try {
      final r = await http
          .get(Uri.parse('http://127.0.0.1:$_apiPort/traffic'))
          .timeout(const Duration(seconds: 3));
      if (r.statusCode == 200) {
        final data = json.decode(r.body) as Map<String, dynamic>;
        final up = _extractBytes(data, 'up');
        final down = _extractBytes(data, 'down');
        final duration = _connectTime != null
            ? DateTime.now().difference(_connectTime!)
            : Duration.zero;
        _stats = VpnConnectionStats(
          uploadTotal: up,
          downloadTotal: down,
          duration: duration,
        );
        _statsController.add(_stats);
      }
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      // API may not respond yet or connection issue — use duration-only update
      if (_connectTime != null) {
        final duration = DateTime.now().difference(_connectTime!);
        _stats = VpnConnectionStats(
          uploadTotal: _stats.uploadTotal,
          downloadTotal: _stats.downloadTotal,
          duration: duration,
        );
        _statsController.add(_stats);
      }
    }
  }

  int _extractBytes(Map<String, dynamic> data, String key) {
    // sing-box API returns bytes as integer or string
    final v = data[key];
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  // ── Platform interface stubs ──

  @override
  Future<String> getStatus() async {
    if (_process != null) {
      try {
        final r = await http
            .get(Uri.parse('http://127.0.0.1:$_apiPort/'))
            .timeout(const Duration(seconds: 2));
        return 'running (PID: ${_process!.pid}, API: ${r.statusCode})';
        // ignore: avoid_catches_without_on_clauses
      } catch (_) {
        return 'running (PID: ${_process!.pid}, API unreachable)';
      }
    }
    return 'stopped';
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

  /// Check internet connectivity by pinging a reliable host.
  Future<bool> _checkInternet() async {
    try {
      final result = await InternetAddress.lookup(
        'github.com',
      ).timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _stopStatsTimer();
    _killSingbox();
    _stateController.close();
    _statsController.close();
    _logController.close();
    _serversController.close();
    _downloadProgressController.close();
  }

  @override
  Future<bool> copyConfigToClipboard(VpnServer server) async => false;
}
