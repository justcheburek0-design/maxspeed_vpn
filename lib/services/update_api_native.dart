import 'package:flutter/material.dart';
import 'update_checker_native.dart';

/// Native implementation — delegates to UpdateManager
Future<void> checkAndPrompt(BuildContext context) async {
  await UpdateManager.instance.checkForUpdate();
  final update = UpdateManager.instance.availableUpdate;
  if (update != null && context.mounted) {
    await UpdateManager.instance.downloadAndInstall(context);
  }
}
