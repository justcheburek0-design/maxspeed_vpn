import 'dart:async';
import 'dart:convert';
import 'dart:io' show Directory, File, FileMode, Platform, Process, ProcessStartMode, exit;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart' show getApplicationCacheDirectory;
import '../core/constants/app_constants.dart';
import '../core/theme/app_themes.dart';
import 'update_info.dart';

/// Download progress state for UI binding.
class UpdateDownloadState {
  final double progress; // 0.0 – 1.0, or -1 for indeterminate
  final int receivedBytes;
  final int totalBytes;
  final String status; // 'downloading', 'paused', 'installing', 'done', 'error'
  final String? error;

  const UpdateDownloadState({
    required this.progress,
    required this.receivedBytes,
    required this.totalBytes,
    required this.status,
    this.error,
  });

  static const idle = UpdateDownloadState(
    progress: 0,
    receivedBytes: 0,
    totalBytes: 0,
    status: 'idle',
  );
}

/// Singleton that manages update checking + background download.
/// Survives widget rebuilds; does NOT survive app restart (re-checks file on start).
class UpdateManager {
  UpdateManager._();
  static final UpdateManager instance = UpdateManager._();

  final StreamController<UpdateDownloadState> _progressController =
      StreamController<UpdateDownloadState>.broadcast();
  Stream<UpdateDownloadState> get progressStream => _progressController.stream;

  UpdateDownloadState _state = UpdateDownloadState.idle;
  UpdateDownloadState get state => _state;

  UpdateInfo? _availableUpdate;
  UpdateInfo? get availableUpdate => _availableUpdate;

  bool _isDownloading = false;
  bool get isDownloading => _isDownloading;

  bool _isUpdateReady = false;
  bool get isUpdateReady => _isUpdateReady;

  /// Check if a downloaded update file already exists for a given version.
  Future<File?> getDownloadedFile(String version) async {
    try {
      final cacheDir = await getApplicationCacheDirectory();
      final ext = Platform.isAndroid ? '.apk'
          : Platform.isWindows ? '.zip'
          : Platform.isMacOS ? '.dmg'
          : Platform.isLinux ? ''
          : '.apk';
      final file = File('${cacheDir.path}/maxspeed_vpn_v$version$ext');
      if (file.existsSync() && file.lengthSync() > 0) return file;
    } catch (_) {}
    return null;
  }

  /// Legacy alias (kept for compatibility)
  Future<File?> getDownloadedApk(String version) => getDownloadedFile(version);

  /// Call once on app start. Checks for update, downloads in background if found.
  Future<void> initialize() async {
    // Check if we already downloaded an update that hasn't been installed
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    // Check for any newer downloaded update file
    try {
      final cacheDir = await getApplicationCacheDirectory();
      final dir = Directory(cacheDir.path);
      if (dir.existsSync()) {
        final allFiles = dir.listSync().whereType<File>()
            .where((f) => f.path.contains('maxspeed_vpn_v'));
        for (final f in allFiles) {
          final name = f.uri.pathSegments.last;
          final versionMatch = RegExp(r'v(\d+\.\d+\.\d+)').firstMatch(name);
          if (versionMatch != null) {
            final v = versionMatch.group(1)!;
            if (_compareVersions(v, currentVersion) > 0) {
              _isUpdateReady = true;
              _state = const UpdateDownloadState(
                progress: 1.0,
                receivedBytes: 0,
                totalBytes: 0,
                status: 'done',
              );
              _progressController.add(_state);
              debugPrint('UpdateManager: found downloaded update for $v');
              return;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('UpdateManager: error checking downloaded updates: $e');
    }

    // Then check for new updates from GitHub
    await checkAndDownloadInBackground();
  }

  /// Check for update from GitHub. If found, starts background download.
  /// Returns UpdateInfo if a new version is available, null otherwise.
  Future<UpdateInfo?> checkAndDownloadInBackground() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await http.get(
        Uri.parse(AppConstants.githubRepoApi),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final latestVersion = (data['tag_name'] as String?)?.replaceFirst('v', '') ?? '';
      final body = data['body'] as String? ?? '';
      final publishedAt = DateTime.tryParse(data['published_at'] as String? ?? '') ?? DateTime.now();

      final assets = data['assets'] as List<dynamic>? ?? [];
      String? downloadUrl;
      for (final asset in assets) {
        final name = asset['name'] as String? ?? '';
        if (_matchesPlatform(name)) {
          downloadUrl = asset['browser_download_url'] as String?;
          break;
        }
      }
      if (downloadUrl == null && assets.isNotEmpty) {
        downloadUrl = assets.first['browser_download_url'] as String?;
      }
      if (downloadUrl == null) return null;

      if (_compareVersions(latestVersion, currentVersion) > 0) {
        _availableUpdate = UpdateInfo(
          version: latestVersion,
          downloadUrl: downloadUrl,
          releaseNotes: body,
          publishedAt: publishedAt,
        );
        // Start background download
        _startBackgroundDownload(_availableUpdate!);
        return _availableUpdate;
      }
      return null;
    } catch (e) {
      debugPrint('UpdateManager: check failed: $e');
      return null;
    }
  }

  /// Manually trigger download (e.g. user tapped "Update" in settings).
  /// If already downloaded, just installs. Otherwise starts/resumes download.
  Future<void> downloadAndInstall(BuildContext context) async {
    if (_availableUpdate == null) {
      // Check first
      final info = await checkAndDownloadInBackground();
      if (info == null || !context.mounted) return;
    }

    // Check if already downloaded
    final apk = await getDownloadedApk(_availableUpdate!.version);
    if (apk != null) {
      _installUpdate(context, apk);
      return;
    }

    // Start fresh download with dialog
    if (!_isDownloading) {
      _startBackgroundDownload(_availableUpdate!);
    }

    if (context.mounted) {
      _showDownloadDialog(context, _availableUpdate!);
    }
  }

  // ─── Background download with retry ───

  Future<void> _startBackgroundDownload(UpdateInfo info, {int attempt = 0}) async {
    if (_isDownloading) return;
    _isDownloading = true;

    const maxRetries = 5;
    const baseDelay = Duration(seconds: 3);

    try {
      final cacheDir = await getApplicationCacheDirectory();
      final ext = Platform.isAndroid ? '.apk'
          : Platform.isWindows ? '.zip'
          : Platform.isMacOS ? '.dmg'
          : Platform.isLinux ? ''
          : '.apk';
      final file = File('${cacheDir.path}/maxspeed_vpn_v${info.version}$ext');

      // Already downloaded?
      if (file.existsSync() && file.lengthSync() > 0) {
        _state = const UpdateDownloadState(
          progress: 1.0, receivedBytes: 0, totalBytes: 0, status: 'done',
        );
        _isUpdateReady = true;
        _progressController.add(_state);
        _isDownloading = false;
        return;
      }

      final client = http.Client();
      final request = http.Request('GET', Uri.parse(info.downloadUrl));

      // Resume support: if partial file exists, set Range header
      int startByte = 0;
      if (file.existsSync()) {
        startByte = file.lengthSync();
        request.headers['Range'] = 'bytes=$startByte-';
      }

      http.StreamedResponse response;
      try {
        response = await client.send(request).timeout(const Duration(seconds: 30));
      } on TimeoutException {
        client.close();
        if (attempt < maxRetries) {
          _state = const UpdateDownloadState(
            progress: -1, receivedBytes: 0, totalBytes: 0, status: 'paused',
          );
          _progressController.add(_state);
          await Future.delayed(baseDelay * (attempt + 1));
          _isDownloading = false;
          return _startBackgroundDownload(info, attempt: attempt + 1);
        }
        rethrow;
      }

      if (response.statusCode != 200 && response.statusCode != 206) {
        client.close();
        if (attempt < maxRetries) {
          _state = UpdateDownloadState(
            progress: -1, receivedBytes: startByte, totalBytes: 0,
            status: 'paused', error: 'Server: ${response.statusCode}',
          );
          _progressController.add(_state);
          await Future.delayed(baseDelay * (attempt + 1));
          _isDownloading = false;
          return _startBackgroundDownload(info, attempt: attempt + 1);
        }
        throw Exception('HTTP ${response.statusCode}');
      }

      final total = response.contentLength ?? 0;
      final sink = file.openWrite(mode: startByte > 0 ? FileMode.append : FileMode.write);

      int received = startByte;
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) {
          _state = UpdateDownloadState(
            progress: received / total,
            receivedBytes: received,
            totalBytes: total,
            status: 'downloading',
          );
          _progressController.add(_state);
        }
      }
      await sink.close();
      client.close();

      _state = const UpdateDownloadState(
        progress: 1.0, receivedBytes: 0, totalBytes: 0, status: 'done',
      );
      _isUpdateReady = true;
      _progressController.add(_state);
    } catch (e) {
      debugPrint('UpdateManager: download error (attempt $attempt): $e');
      if (attempt < maxRetries) {
        _state = const UpdateDownloadState(
          progress: -1, receivedBytes: 0, totalBytes: 0, status: 'paused',
        );
        _progressController.add(_state);
        await Future.delayed(baseDelay * (attempt + 1));
        _isDownloading = false;
        return _startBackgroundDownload(info, attempt: attempt + 1);
      }
      _state = UpdateDownloadState(
        progress: 0, receivedBytes: 0, totalBytes: 0,
        status: 'error', error: e.toString(),
      );
      _progressController.add(_state);
    } finally {
      _isDownloading = false;
    }
  }

  // ─── UI ───

  void _showDownloadDialog(BuildContext context, UpdateInfo info) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _UpdateDownloadDialog(
        info: info,
        manager: instance,
      ),
    );
  }

  Future<void> _installUpdate(BuildContext context, File file) async {
    if (Platform.isAndroid) {
      await _installApk(context, file);
    } else if (Platform.isWindows) {
      await _installWindows(file);
    } else if (Platform.isMacOS) {
      await _installMacOS(file);
    } else if (Platform.isLinux) {
      await _installLinux(file);
    } else {
      debugPrint('UpdateManager: unsupported platform for install');
    }
  }

  /// Windows: extract .zip → run new .exe → exit(0)
  Future<void> _installWindows(File zipFile) async {
    try {
      // Determine target directory (where current exe lives)
      final currentExe = Platform.resolvedExecutable;
      final currentExeDir = File(currentExe).parent;
      final targetDir = Directory('${currentExeDir.path}\\..');
      final tempDir = Directory('${targetDir.path}\\update_temp');

      debugPrint('UpdateManager: installing Windows update from ${zipFile.path}');
      debugPrint('UpdateManager: targetDir=${targetDir.path}');

      // Clean temp if exists
      if (tempDir.existsSync()) await tempDir.delete(recursive: true);
      await tempDir.create(recursive: true);

      // Extract zip via PowerShell
      final extractResult = await Process.run(
        'powershell',
        ['-Command', 'Expand-Archive -Path "${zipFile.path}" -DestinationPath "${tempDir.path}" -Force'],
        runInShell: true,
      );
      if (extractResult.exitCode != 0) {
        debugPrint('UpdateManager: extract failed: ${extractResult.stderr}');
        return;
      }

      // Find the new exe inside extracted folder
      final extractedFiles = tempDir.listSync(recursive: true);
      final newExe = extractedFiles
          .whereType<File>()
          .firstWhere((f) => f.path.endsWith('.exe'), orElse: () => throw Exception('No .exe in zip'));

      // Create a batch script that:
      // 1. Waits for current process to exit
      // 2. Copies new files over old ones
      // 3. Starts the new exe
      // 4. Cleans up
      final batchScript = '''
@echo off
timeout /t 2 /nobreak >nul
xcopy "${tempDir.path}\\*" "${targetDir.path}" /E /Y /I
start "" "${currentExe}"
del "%~f0"
''';
      final batchFile = File('${targetDir.path}\\update.bat');
      await batchFile.writeAsString(batchScript);

      // Run the batch script detached
      await Process.start(
        'cmd',
        ['/c', 'start', '', batchFile.path],
        mode: ProcessStartMode.detached,
        runInShell: true,
      );

      debugPrint('UpdateManager: update script launched, exiting app');
      // Exit the app so the batch script can replace files
      exit(0);
    } catch (e) {
      debugPrint('UpdateManager: Windows install error: $e');
    }
  }

  /// macOS: mount .dmg → copy to /Applications → restart
  Future<void> _installMacOS(File dmgFile) async {
    try {
      debugPrint('UpdateManager: installing macOS update from ${dmgFile.path}');
      // Mount DMG
      final mountResult = await Process.run('hdiutil', ['attach', dmgFile.path]);
      if (mountResult.exitCode != 0) {
        debugPrint('UpdateManager: mount failed: ${mountResult.stderr}');
        return;
      }
      // Parse mount point from output
      final output = mountResult.stdout as String;
      final lines = output.split('\n');
      String? mountPoint;
      for (final line in lines) {
        if (line.contains('/Volumes/')) {
          mountPoint = line.trim().split('\t').last.trim();
          break;
        }
      }
      if (mountPoint == null) {
        debugPrint('UpdateManager: could not find mount point');
        return;
      }
      // Copy .app to /Applications
      final apps = Directory(mountPoint).listSync().where((e) => e.path.endsWith('.app'));
      for (final app in apps) {
        final appName = app.path.split('/').last;
        final target = '/Applications/$appName';
        await Process.run('cp', ['-R', app.path, target]);
        debugPrint('UpdateManager: copied $appName to /Applications');
      }
      // Unmount
      await Process.run('hdiutil', ['detach', mountPoint]);
      // Restart
      final currentExe = Platform.resolvedExecutable;
      await Process.start(currentExe, [], mode: ProcessStartMode.detached);
      exit(0);
    } catch (e) {
      debugPrint('UpdateManager: macOS install error: $e');
    }
  }

  /// Linux: replace binary → restart
  Future<void> _installLinux(File binaryFile) async {
    try {
      final currentExe = Platform.resolvedExecutable;
      await Process.run('cp', [binaryFile.path, currentExe]);
      await Process.run('chmod', ['+x', currentExe]);
      await Process.start(currentExe, [], mode: ProcessStartMode.detached);
      exit(0);
    } catch (e) {
      debugPrint('UpdateManager: Linux install error: $e');
    }
  }

  /// Android: use MethodChannel (existing behavior)
  Future<void> _installApk(BuildContext context, File file) async {
    const channel = MethodChannel('ru.maxspeed.maxspeed_vpn/installer');
    try {
      final result = await channel.invokeMethod('installApk', {'path': file.path});
      if (result != true) throw Exception('installApk returned false');
    } catch (e) {
      debugPrint('installApk failed: $e');
      try {
        await channel.invokeMethod('openFile', {'path': file.path});
      } catch (_) {}
    }
  }

  // ─── Helpers ───

  static bool _matchesPlatform(String filename) {
    if (Platform.isAndroid) return filename.endsWith('.apk');
    if (Platform.isIOS) return filename.endsWith('.ipa') || filename.contains('ios');
    if (Platform.isMacOS) return filename.endsWith('.dmg') || filename.contains('macos');
    if (Platform.isLinux) return filename.endsWith('.deb') || filename.endsWith('.AppImage') || filename.contains('linux');
    if (Platform.isWindows) return filename.endsWith('.zip') || filename.endsWith('.exe') || filename.contains('windows');
    return false;
  }

  static int _compareVersions(String a, String b) {
    String strip(String v) => v.contains('+') ? v.substring(0, v.indexOf('+')) : v;
    final aParts = strip(a).split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final bParts = strip(b).split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final maxLen = aParts.length > bParts.length ? aParts.length : bParts.length;
    while (aParts.length < maxLen) aParts.add(0);
    while (bParts.length < maxLen) bParts.add(0);
    for (int i = 0; i < maxLen; i++) {
      if (aParts[i] != bParts[i]) return aParts[i].compareTo(bParts[i]);
    }
    return 0;
  }

  void dispose() {
    _progressController.close();
  }
}

/// Dialog that shows download progress, driven by UpdateManager's stream.
class _UpdateDownloadDialog extends StatefulWidget {
  final UpdateInfo info;
  final UpdateManager manager;
  const _UpdateDownloadDialog({required this.info, required this.manager});
  @override State<_UpdateDownloadDialog> createState() => _UpdateDownloadDialogState();
}

class _UpdateDownloadDialogState extends State<_UpdateDownloadDialog> {
  @override
  void initState() {
    super.initState();
    // If already done, auto-close after brief delay
    if (widget.manager.state.status == 'done') {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = GlassTheme.of(context);
    return StreamBuilder<UpdateDownloadState>(
      stream: widget.manager.progressStream,
      initialData: widget.manager.state,
      builder: (context, snapshot) {
        final state = snapshot.data ?? UpdateDownloadState.idle;
        final isDone = state.status == 'done';
        final isError = state.status == 'error';

        return AlertDialog(
          backgroundColor: theme.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Обновление', style: TextStyle(color: theme.onSurface)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isDone && !isError)
                CircularProgressIndicator(
                  value: state.progress > 0 ? state.progress : null,
                  color: theme.primary,
                ),
              if (isDone) Icon(Icons.check_circle, color: theme.success, size: 48),
              if (isError) Icon(Icons.error, color: theme.error, size: 48),
              const SizedBox(height: 16),
              Text(
                _statusText(state),
                style: TextStyle(color: theme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              if (!isDone && !isError && state.progress > 0) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(value: state.progress, color: theme.primary),
                const SizedBox(height: 4),
                Text(
                  '${(state.progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 12, color: theme.outline),
                ),
              ],
            ],
          ),
          actions: [
            if (isDone)
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  // Find the downloaded file and install
                  final file = await widget.manager.getDownloadedFile(widget.info.version);
                  if (file != null && context.mounted) {
                    widget.manager._installUpdate(context, file);
                  }
                },
                child: Text('Установить', style: TextStyle(color: theme.primary)),
              ),
            if (isError)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Закрыть', style: TextStyle(color: theme.primary)),
              ),
          ],
        );
      },
    );
  }

  String _statusText(UpdateDownloadState state) {
    switch (state.status) {
      case 'downloading':
        if (state.totalBytes > 0) {
          final mb = (state.receivedBytes / 1024 / 1024).toStringAsFixed(1);
          final totalMb = (state.totalBytes / 1024 / 1024).toStringAsFixed(1);
          return 'Скачивание... $mb / $totalMb MB';
        }
        return 'Скачивание...';
      case 'paused':
        return 'Нет подключения. Повтор...';
      case 'done':
        return 'Скачивание завершено!';
      case 'error':
        return 'Ошибка: ${state.error ?? "неизвестная"}';
      default:
        return 'Подготовка...';
    }
  }
}

// ─── Legacy API (kept for compatibility with update_api_native.dart) ───

class UpdateChecker {
  static Future<UpdateInfo?> checkForUpdate() async {
    return UpdateManager.instance.checkAndDownloadInBackground();
  }

  static Future<void> downloadAndInstall(BuildContext context, UpdateInfo info) async {
    UpdateManager.instance._availableUpdate = info;
    await UpdateManager.instance.downloadAndInstall(context);
  }
}

Future<void> showUpdateDialog(BuildContext context, UpdateInfo info) async {
  final theme = GlassTheme.of(context);
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: theme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.system_update, color: theme.primary),
          const SizedBox(width: 12),
          Text('Доступно обновление', style: TextStyle(color: theme.onSurface)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Новая версия: ${info.version}',
              style: TextStyle(color: theme.primary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (info.releaseNotes.isNotEmpty) ...[
            Text('Что нового:',
                style: TextStyle(color: theme.onSurfaceVariant, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Text(info.releaseNotes,
                    style: TextStyle(color: theme.onSurfaceVariant, fontSize: 13)),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('Позже', style: TextStyle(color: theme.outline)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primary,
            foregroundColor: theme.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            Navigator.pop(ctx);
            UpdateManager.instance._availableUpdate = info;
            UpdateManager.instance.downloadAndInstall(context);
          },
          child: const Text('Обновить'),
        ),
      ],
    ),
  );
}
