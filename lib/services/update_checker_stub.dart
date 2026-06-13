import 'package:flutter/material.dart';

/// Stub for web — no-op update checker.
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
  static Future<UpdateInfo?> checkForUpdate() async => null; // web: always null
  static Future<void> downloadAndInstall(BuildContext context, UpdateInfo info) async {}
}

Future<void> showUpdateDialog(BuildContext context, UpdateInfo info) async {
  // Web: show simple dialog
}
