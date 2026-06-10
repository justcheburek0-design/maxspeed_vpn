import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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

  /// Проверяет наличие обновления. Возвращает UpdateInfo если есть новая версия, иначе null.
  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await http.get(
        Uri.parse(_repoApiUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final latestVersion = (data['tag_name'] as String?)?.replaceFirst('v', '') ?? '';
      final body = data['body'] as String? ?? '';
      final publishedAt = DateTime.tryParse(data['published_at'] as String? ?? '') ?? DateTime.now();

      // Находим APK в assets
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

      // Сравниваем версии
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

  /// Сравнивает две версии. Возвращает >0 если a > b, <0 если a < b, 0 если равны.
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
    // Показываем прогресс
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DownloadDialog(url: info.downloadUrl),
    );
  }
}

class _DownloadDialog extends StatefulWidget {
  final String url;
  const _DownloadDialog({required this.url});

  @override State<_DownloadDialog> createState() => _DownloadDialogState();
}

class _DownloadDialogState extends State<_DownloadDialog> {
  double _progress = 0;
  String _status = 'Загрузка...';
  bool _done = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _download();
  }

  Future<void> _download() async {
    try {
      final client = http.StreamedRequest('GET', Uri.parse(widget.url));
      final response = await client.send().timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        setState(() { _status = 'Ошибка загрузки: ${response.statusCode}'; _error = true; });
        return;
      }

      final total = response.contentLength ?? 0;
      final dir = Directory('/storage/emulated/0/Download');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final file = File('${dir.path}/maxspeed_vpn_update.apk');
      final sink = file.openWrite();

      int received = 0;
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) {
          setState(() {
            _progress = received / total;
            _status = 'Загрузка... ${(_progress * 100).toStringAsFixed(0)}%';
          });
        }
      }
      await sink.close();

      setState(() { _status = 'Загрузка завершена!'; _done = true; });

      // Открываем установщик
      final uri = Uri.parse('content://${file.path}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Fallback: через file://
        final fallbackUri = Uri.file(file.path);
        if (await canLaunchUrl(fallbackUri)) {
          await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      setState(() { _status = 'Ошибка: $e'; _error = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1a2a1a),
      title: Text('Обновление', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_done && !_error) CircularProgressIndicator(value: _progress, color: Color(0xFFa8e63d)),
          if (_done) Icon(Icons.check_circle, color: Colors.green, size: 48),
          if (_error) Icon(Icons.error, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(_status, style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
          if (!_done && !_error) const SizedBox(height: 12),
          if (!_done && !_error) LinearProgressIndicator(value: _progress, color: Color(0xFFa8e63d)),
        ],
      ),
      actions: [
        if (_done || _error)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_done ? 'Готово' : 'Закрыть'),
          ),
      ],
    );
  }
}

/// Показывает диалог обновления
Future<void> showUpdateDialog(BuildContext context, UpdateInfo info) async {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1a2a1a),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.system_update, color: Color(0xFFa8e63d)),
          const SizedBox(width: 12),
          Text('Доступно обновление', style: TextStyle(color: Colors.white)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Новая версия: ${info.version}', style: TextStyle(color: Color(0xFFa8e63d), fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (info.releaseNotes.isNotEmpty) ...[
            Text('Что нового:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Container(
              constraints: BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Text(
                  info.releaseNotes,
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('Позже', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFa8e63d),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            Navigator.pop(ctx);
            UpdateChecker.downloadAndInstall(context, info);
          },
          child: Text('Обновить'),
        ),
      ],
    ),
  );
}
