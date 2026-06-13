import 'package:flutter/material.dart';
import 'update_checker_native.dart';

/// Native implementation — checks GitHub releases
Future<void> checkAndPrompt(BuildContext context) async {
  final update = await UpdateChecker.checkForUpdate();
  if (update != null && context.mounted) {
    await showUpdateDialog(context, update);
  }
}
