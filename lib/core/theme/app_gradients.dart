import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppGradients {
  AppGradients._();
  static const LinearGradient primary = LinearGradient(colors: [AppColors.primary, AppColors.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const LinearGradient success = LinearGradient(colors: [AppColors.success, Color(0xFF059669)], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const LinearGradient danger = LinearGradient(colors: [AppColors.error, Color(0xFFDC2626)], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const LinearGradient warning = LinearGradient(colors: [AppColors.warning, Color(0xFFD97706)], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const LinearGradient card = LinearGradient(colors: [AppColors.bgSurface, AppColors.bgSecondary], begin: Alignment.topCenter, end: Alignment.bottomCenter);
  static const LinearGradient dark = card;
  static const LinearGradient connected = LinearGradient(colors: [AppColors.success, Color(0xFF10B981)], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const LinearGradient connecting = LinearGradient(colors: [AppColors.warning, Color(0xFFF59E0B)], begin: Alignment.topLeft, end: Alignment.bottomRight);
}
