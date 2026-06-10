import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppText {
  AppText._();
  static const String fontFamily = 'Inter';

  static TextStyle displayLarge(BuildContext c) => TextStyle(fontFamily: fontFamily, fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.5, height: 1.2);
  static TextStyle displayMedium(BuildContext c) => TextStyle(fontFamily: fontFamily, fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: -0.3, height: 1.3);
  static TextStyle headlineLarge(BuildContext c) => TextStyle(fontFamily: fontFamily, fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: -0.2, height: 1.3);
  static TextStyle headlineMedium(BuildContext c) => TextStyle(fontFamily: fontFamily, fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.4);
  static TextStyle titleLarge(BuildContext c) => TextStyle(fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.4);
  static TextStyle titleMedium(BuildContext c) => TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary, height: 1.5);
  static TextStyle bodyLarge(BuildContext c) => TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.6);
  static TextStyle bodyMedium(BuildContext c) => TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.5);
  static TextStyle bodySmall(BuildContext c) => TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textMuted, height: 1.5);
  static TextStyle labelLarge(BuildContext c) => TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: 0.5);
  static TextStyle labelMedium(BuildContext c) => TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5);
  static TextStyle labelSmall(BuildContext c) => TextStyle(fontFamily: fontFamily, fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.8);
  static TextStyle button(BuildContext c) => TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: 0.3);
  static TextStyle caption(BuildContext c) => TextStyle(fontFamily: fontFamily, fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textMuted, height: 1.4);
  static TextStyle mono(BuildContext c) => TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.5);
}
