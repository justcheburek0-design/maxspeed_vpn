import 'dart:convert';
import 'dart:io';
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

  static Future<UpdateInfo?> checkForUpdate() async {
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
      String? apkUrl;
      for (final asset in assets) {
        final name = asset['name'] as String? ?? '';
        if (name.endsWith('.apk')) {
          apkUrl = asset['browser_download_url'] as String?;
          break;
        }
      }

      if (apkUrl == null) return null;

      if (_compareVersions(latestVersion, currentVersion) > 0) {
        return UpdateInfo(
          version: latestVersion,
          downloadUrl: apkUrl,
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

  static int _compareVersions(String a, String b) {
    final aParts = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final bParts = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final maxLen = aParts.length > bParts.length ? aParts.length : bParts.length;
    while (aParts.length < maxLen) aParts.add(0);
    while (bParts.length < maxLen) bParts.add(0);
    for (int i = 0; i < maxLen; i++) {
      if (aParts[i] != bParts[i]) return aParts[i].compareTo(bParts[i]);
    }
    return 0;
  }

  static Future<void> downloadAndInstall(BuildContext context, UpdateInfo info) async {
    // Show download dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DownloadDialog(url: info.downloadUrl, version: info.version),
    );
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

      // Save to app cache directory (FileProvider can access it)
      final cacheDir = await getApplicationCacheDirectory();
      final file = File('${cacheDir.path}/maxspeed_vpn_v${widget.version}.apk');
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

      setState(() { _status = 'Загрузка завершена!'; _done = true; });

      // Try to open installer
      await _openInstaller(file);
    } catch (e) {
      setState(() { _status = 'Ошибка: $e'; _error = true; });
    }
  }

  static const _channel = MethodChannel('ru.maxspeed.maxspeed_vpn/installer');

  Future<void> _openInstaller(File file) async {
    try {
      // Copy to Downloads for accessibility
      Directory? downloadDir;
      if (Platform.isAndroid) {
        downloadDir = Directory('/storage/emulated/0/Download');
        if (!downloadDir.existsSync()) downloadDir.createSync(recursive: true);
      } else {
        downloadDir = await getApplicationCacheDirectory();
      }
      final destFile = File('${downloadDir!.path}/maxspeed_vpn_update.apk');
      await file.copy(destFile.path);

      // Use native Android Intent to install APK
      if (Platform.isAndroid) {
        final result = await _channel.invokeMethod('installApk', {'path': destFile.path});
        if (result != true) {
          setState(() {
            _status = 'Откройте файл вручную:\n${destFile.path}';
          });
        }
      }
    } catch (e) {
      setState(() {
        _status = 'Установите вручную:\n/storage/emulated/0/Download/maxspeed_vpn_update.apk';
      });
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

/// Показывает диалог обновления
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
