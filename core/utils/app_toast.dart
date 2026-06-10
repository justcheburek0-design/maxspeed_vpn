import 'package:flutter/material.dart';

/// Toast/snackbar utility.
class AppToast {
  static void show(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) => show(context, message);
  static void showError(BuildContext context, String message) => show(context, message, isError: true);
}
