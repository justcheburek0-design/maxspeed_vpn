import 'package:flutter/material.dart';
import 'update_info.dart';

/// Stub for web — no-op update checker.
class UpdateChecker {
  static Future<UpdateInfo?> checkForUpdate() async => null; // web: always null
  static Future<void> downloadAndInstall(BuildContext context, UpdateInfo info) async {}
}

Future<void> showUpdateDialog(BuildContext context, UpdateInfo info) async {
  // Web: show simple dialog
}
