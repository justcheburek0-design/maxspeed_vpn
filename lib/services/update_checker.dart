import 'dart:convert';
import 'dart:io' show Platform, File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../core/theme/app_themes.dart';

class UpdateInfo {
  final String version;
  final String downloadUrl;
  final String releaseNotes;
  final DateTime publishedAt;

  const UpdateInfo({
    required this.version,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.publishedAt,
  });
}

class UpdateChecker {
  static const String _repoApiUrl =
      'https://api.github.com/repos/justcheburek0-design/maxspeed_vpn/releases/latest';

  /// Проверяет наличие обновления.
  /// На web всегда возвращает null (обновление через перезагрузку страницы).
  static Future<UpdateInfo?> checkForUpdate() async {
    // On web, updates are handled by page reload
    if (kIsWeb) return null;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await http.get(
        Uri.parse(_repoApiUrl),
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
        // Pick the right asset for current platform
        if (_matchesPlatform(name)) {
          downloadUrl = asset['browser_download_url'] as String?;
          break;
        }
      }

      // Fallback: any asset URL
      if (downloadUrl == null && assets.isNotEmpty) {
        downloadUrl = assets.first['browser_download_url'] as String?;
      }

      if (downloadUrl == null) return null;

      if (_compareVersions(latestVersion, currentVersion) > 0) {
        return UpdateInfo(
          version: latestVersion,
          downloadUrl: downloadUrl,
          releaseNotes: body,
          publishedAt: publishedAt,
        );
      }

      return null;
    } catch (e) {
      debugPrint('Update check failed: $e');
      return null;
    }
  }

  static bool _matchesPlatform(String filename) {
    if (Platform.isAndroid) return filename.endsWith('.apk');
    if (Platform.isIOS) return filename.endsWith('.ipa') || filename.contains('ios');
    if (Platform.isMacOS) return filename.endsWith('.dmg') || filename.contains('macos');
    if (Platform.isLinux) return filename.endsWith('.deb') || filename.endsWith('.AppImage') || filename.contains('linux');
    if (Platform.isWindows) return filename.endsWith('.exe') || filename.contains('windows');
    return false;
  }

  static int _compareVersions(String a, String b) {
    // Strip build metadata (+N) for comparison: "1.3.1+5" → "1.3.1"
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

  static Future<void> downloadAndInstall(BuildContext context, UpdateInfo info) async {
    // On non-Android platforms, open download URL in browser
    if (!Platform.isAndroid) {
      try {
        final uri = Uri.parse(info.downloadUrl);
        // url_launcher would be better, but for now just show the URL
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Обновление'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Скачайте обновление для вашей платформы (${_currentPlatformLabel()}):'),
                  const SizedBox(height: 12),
                  SelectableText(
                    info.downloadUrl,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Закрыть'),
                ),
              ],
            ),
          );
        }
      } catch (_) {}
      return;
    }

    // Android: show download dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DownloadDialog(url: info.downloadUrl, version: info.version),
    );
  }

  static String _currentPlatformLabel() {
    if (Platform.isIOS) return 'iOS';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    if (Platform.isWindows) return 'Windows';
    return 'Android';
  }
}

class _DownloadDialog extends StatefulWidget {
  final String url;
  final String version;
  const _DownloadDialog({required this.url, required this.version});

  @override State<_DownloadDialog> createState() => _DownloadDialogState();
}

class _DownloadDialogState extends State<_DownloadDialog> {
  double _progress = 0;
  String _status = 'Подготовка...';
  bool _done = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _download();
  }

  Future<void> _download() async {
    try {
      setState(() => _status = 'Загрузка обновления...');

      final client = http.Client();
      final request = http.Request('GET', Uri.parse(widget.url));
      final response = await client.send(request).timeout(const Duration(minutes: 5));

      if (response.statusCode != 200) {
        setState(() { _status = 'Ошибка сервера: ${response.statusCode}'; _error = true; });
        return;
      }

      final total = response.contentLength ?? 0;

      // Download directly to app cache dir so FileProvider can access it
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/maxspeed_vpn_v${widget.version}.apk');
      // Clean up any previous download
      if (file.existsSync()) file.deleteSync();
      final sink = file.openWrite();

      int received = 0;
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) {
          setState(() {
            _progress = received / total;
            final mb = (received / 1024 / 1024).toStringAsFixed(1);
            final totalMb = (total / 1024 / 1024).toStringAsFixed(1);
            _status = 'Загрузка... $mb / $totalMb MB';
          });
        }
      }
      await sink.close();
      client.close();

      setState(() { _status = 'Установка...'; _done = true; });

      // Small delay so UI updates before install intent
      await Future.delayed(const Duration(milliseconds: 500));
      await _openApk(file);

      // Close dialog after successful install launch
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() { _status = 'Ошибка: $e'; _error = true; });
    }
  }

  static const _channel = MethodChannel('ru.maxspeed.maxspeed_vpn/installer');

  Future<void> _openApk(File file) async {
    try {
      if (Platform.isAndroid) {
        final result = await _channel.invokeMethod('installApk', {'path': file.path});
        if (result != true) {
          throw Exception('installApk returned false');
        }
      }
    } catch (e) {
      debugPrint('installApk failed: $e');
      // Fallback: try opening the file directly
      try {
        final uri = Uri.file(file.path);
        // This may not work without FileProvider, but worth trying
        await _channel.invokeMethod('openFile', {'path': file.path});
      } catch (e2) {
        debugPrint('openFile fallback also failed: $e2');
        // Last resort: show path to user
        if (mounted) {
          setState(() {
            _status = 'Скачано: ${file.path}\nОткройте файл вручную';
            _error = true;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = GlassTheme.of(context);
    return AlertDialog(
      backgroundColor: theme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Обновление', style: TextStyle(color: theme.onSurface)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_done && !_error)
            CircularProgressIndicator(value: _progress > 0 ? _progress : null, color: theme.primary),
          if (_done) Icon(Icons.check_circle, color: theme.success, size: 48),
          if (_error) Icon(Icons.error, color: theme.error, size: 48),
          const SizedBox(height: 16),
          Text(_status, style: TextStyle(color: theme.onSurfaceVariant), textAlign: TextAlign.center),
          if (!_done && !_error && _progress > 0) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(value: _progress, color: theme.primary),
            const SizedBox(height: 4),
            Text('${(_progress * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 12, color: theme.outline)),
          ],
        ],
      ),
      actions: [
        if (_done || _error)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_done ? 'Готово' : 'Закрыть', style: TextStyle(color: theme.primary)),
          ),
      ],
    );
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
          Text('Новая версия: ${info.version}', style: TextStyle(color: theme.primary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (info.releaseNotes.isNotEmpty) ...[
            Text('Что нового:', style: TextStyle(color: theme.onSurfaceVariant, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Text(
                  info.releaseNotes,
                  style: TextStyle(color: theme.onSurfaceVariant, fontSize: 13),
                ),
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
            UpdateChecker.downloadAndInstall(context, info);
          },
          child: const Text('Обновить'),
        ),
      ],
    ),
  );
}
