import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

class AppToast {
  static void show(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: AppText.bodyMedium(context).copyWith(color: AppColors.textPrimary)),
      backgroundColor: isError ? AppColors.error : AppColors.bgSurface,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }
  static void success(BuildContext c, String m) => show(c, m);
  static void error(BuildContext c, String m) => show(c, m, isError: true);
}
