import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Downloads and caches sing-box binary for the current platform.
class SingboxDownloader {
  static const String _repoApi =
      'https://api.github.com/repos/SagerNet/sing-box/releases/latest';

  /// Returns the expected filename for the current platform.
  static String get _platformArchive {
    if (Platform.isWindows) return 'windows-amd64.zip';
    if (Platform.isMacOS) {
      // Detect ARM vs x86
      final result = Process.runSync('uname', ['-m']);
      final arch = result.stdout.toString().trim();
      return arch == 'arm64' ? 'darwin-arm64.tar.gz' : 'darwin-amd64.tar.gz';
    }
    if (Platform.isLinux) return 'linux-amd64.tar.gz';
    throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
  }

  static String get _binaryName =>
      Platform.isWindows ? 'sing-box.exe' : 'sing-box';

  static String get _archiveName => 'sing-box-$_platformArchive';

  /// Directory where sing-box binary is stored (next to the app).
  static Future<String> get _cacheDir async {
    final appDir = Platform.resolvedExecutable.replaceAll('\\', '/');
    final dir = appDir.substring(0, appDir.lastIndexOf('/'));
    return '$dir';
  }

  /// Full path to the expected sing-box binary.
  static Future<String> get binaryPath async {
    final dir = await _cacheDir;
    return '$dir/$_binaryName';
  }

  /// Check if sing-box binary already exists locally.
  static Future<bool> isDownloaded() async {
    return File(await binaryPath).exists();
  }

  /// Fetch the latest version from GitHub API.
  static Future<String?> _fetchLatestVersion() async {
    try {
      final r = await http.get(Uri.parse(_repoApi)).timeout(
        const Duration(seconds: 10),
      );
      if (r.statusCode == 200) {
        final data = json.decode(r.body) as Map<String, dynamic>;
        final tag = data['tag_name'] as String?;
        if (tag != null && tag.startsWith('v')) {
          return tag.substring(1); // strip 'v' prefix
        }
      }
    } catch (_) {}
    return null;
  }

  /// Download sing-box binary. Returns path to binary or null on failure.
  /// [onProgress] is called with (downloadedBytes, totalBytes).
  static Future<String?> download({
    void Function(int downloaded, int total)? onProgress,
  }) async {
    final version = await _fetchLatestVersion();
    if (version == null) return null;

    final url =
        'https://github.com/SagerNet/sing-box/releases/download/v$version/sing-box-$version-$_platformArchive';

    final dir = await _cacheDir;
    final archivePath = '$dir/sing-box-$version-$_platformArchive';
    final outputPath = await binaryPath;

    // Download archive
    try {
      final request = http.Request('get', Uri.parse(url));
      final response = await request.send().timeout(
        const Duration(minutes: 5),
      );

      if (response.statusCode != 200) return null;

      final total = response.contentLength ?? 0;
      var downloaded = 0;

      final archiveFile = File(archivePath);
      final sink = archiveFile.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloaded += chunk.length;
        if (total > 0) {
          onProgress?.call(downloaded, total);
        }
      }
      await sink.close();

      // Extract
      if (_archiveName.endsWith('.zip')) {
        // Windows: unzip
        if (Platform.isWindows) {
          final result = await Process.run(
            'powershell',
            [
              '-Command',
              'Expand-Archive',
              '-Path',
              archivePath,
              '-DestinationPath',
              dir,
              '-Force',
            ],
          );
          if (result.exitCode != 0) {
            // Fallback: try 7z or manual
            return null;
          }
        } else {
          final result = await Process.run('unzip', ['-o', archivePath, '-d', dir]);
          if (result.exitCode != 0) return null;
        }
      } else {
        // tar.gz: extract
        final result = await Process.run('tar', ['-xzf', archivePath, '-C', dir]);
        if (result.exitCode != 0) return null;
      }

      // The archive contains a sing-box-{ver}-{os}-{arch}/sing-box binary
      // Move it to the expected location
      final extractedDir = '$dir/sing-box-$version-${_platformArchive.replaceAll('.zip', '').replaceAll('.tar.gz', '')}';
      final extractedBinary = '$extractedDir/$_binaryName';

      if (await File(extractedBinary).exists()) {
        await File(extractedBinary).copy(outputPath);
        // Cleanup extracted dir
        try {
          await Directory(extractedDir).delete(recursive: true);
        } catch (_) {}
      } else if (await File('$dir/$_binaryName').exists()) {
        // Already in root of archive
        // binary is already at outputPath
      }

      // Cleanup archive
      try {
        await File(archivePath).delete();
      } catch (_) {}

      // Make executable on Unix
      if (!Platform.isWindows) {
        await Process.run('chmod', ['+x', outputPath]);
      }

      return await File(outputPath).exists() ? outputPath : null;
    } catch (_) {
      // Cleanup on failure
      try {
        await File(archivePath).delete();
      } catch (_) {}
      return null;
    }
  }
}
