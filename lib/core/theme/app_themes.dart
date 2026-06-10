import 'dart:ui';
import 'package:flutter/material.dart';
import '../../data/models/vpn_models.dart';

// ─── Color Palettes ───

class AppPalette {
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color accent;
  final Color bgPrimary;
  final Color bgSecondary;
  final Color bgSurface;
  final Color bgCard;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color success;
  final Color error;
  final Color warning;
  final Color border;
  final Color glassTint;
  final Color shadow;

  const AppPalette({
    required this.primary, required this.primaryLight, required this.primaryDark,
    required this.accent, required this.bgPrimary, required this.bgSecondary,
    required this.bgSurface, required this.bgCard, required this.textPrimary,
    required this.textSecondary, required this.textMuted, required this.success,
    required this.error, required this.warning, required this.border,
    required this.glassTint, required this.shadow,
  });
}

// ─── Dark Themes (5) ───

class DarkThemes {
  static const forest = AppPalette(
    primary: Color(0xFF4ADE80), primaryLight: Color(0xFF86EFAC), primaryDark: Color(0xFF22C55E),
    accent: Color(0xFF34D399), bgPrimary: Color(0xFF0A0F0D), bgSecondary: Color(0xFF111A15),
    bgSurface: Color(0xFF1A2420), bgCard: Color(0xFF1E2B26),
    textPrimary: Color(0xFFF0FDF4), textSecondary: Color(0xFFA7D9B8), textMuted: Color(0xFF4A6B58),
    success: Color(0xFF34D399), error: Color(0xFFF87171), warning: Color(0xFFFBBF24),
    border: Color(0xFF2A3B33), glassTint: Color(0x1A4ADE80), shadow: Color(0x40000000),
  );

  static const midnight = AppPalette(
    primary: Color(0xFF60A5FA), primaryLight: Color(0xFF93C5FD), primaryDark: Color(0xFF3B82F6),
    accent: Color(0xFF818CF8), bgPrimary: Color(0xFF0B0D14), bgSecondary: Color(0xFF11141F),
    bgSurface: Color(0xFF1A1E2E), bgCard: Color(0xFF1C2235),
    textPrimary: Color(0xFFF1F5F9), textSecondary: Color(0xFF94A3B8), textMuted: Color(0xFF475569),
    success: Color(0xFF34D399), error: Color(0xFFF87171), warning: Color(0xFFFBBF24),
    border: Color(0xFF2A3350), glassTint: Color(0x1A60A5FA), shadow: Color(0x60000000),
  );

  static const cyberpunk = AppPalette(
    primary: Color(0xFFF472B6), primaryLight: Color(0xFFF9A8D4), primaryDark: Color(0xFFEC4899),
    accent: Color(0xFFA78BFA), bgPrimary: Color(0xFF0D0A14), bgSecondary: Color(0xFF15101F),
    bgSurface: Color(0xFF1E1730), bgCard: Color(0xFF251D3A),
    textPrimary: Color(0xFFFAF5FF), textSecondary: Color(0xFFC4B5FD), textMuted: Color(0xFF6B5B8A),
    success: Color(0xFF34D399), error: Color(0xFFF87171), warning: Color(0xFFFBBF24),
    border: Color(0xFF3A2D55), glassTint: Color(0x1AF472B6), shadow: Color(0x60000000),
  );

  static const arctic = AppPalette(
    primary: Color(0xFF22D3EE), primaryLight: Color(0xFF67E8F9), primaryDark: Color(0xFF06B6D4),
    accent: Color(0xFF38BDF8), bgPrimary: Color(0xFF0A1218), bgSecondary: Color(0xFF0F1C26),
    bgSurface: Color(0xFF172836), bgCard: Color(0xFF1B3040),
    textPrimary: Color(0xFFECFEFF), textSecondary: Color(0xFF93C5FD), textMuted: Color(0xFF4A6B8A),
    success: Color(0xFF34D399), error: Color(0xFFF87171), warning: Color(0xFFFBBF24),
    border: Color(0xFF2A4055), glassTint: Color(0x1A22D3EE), shadow: Color(0x40000000),
  );

  static const ember = AppPalette(
    primary: Color(0xFFFB923C), primaryLight: Color(0xFFFDBA74), primaryDark: Color(0xFFF97316),
    accent: Color(0xFFFBBF24), bgPrimary: Color(0xFF120D0A), bgSecondary: Color(0xFF1F1611),
    bgSurface: Color(0xFF2E221A), bgCard: Color(0xFF3A2A1F),
    textPrimary: Color(0xFFFFF7ED), textSecondary: Color(0xFFFDBA74), textMuted: Color(0xFF8A6B4A),
    success: Color(0xFF34D399), error: Color(0xFFF87171), warning: Color(0xFFFBBF24),
    border: Color(0xFF553A2A), glassTint: Color(0x1AFB923C), shadow: Color(0x40000000),
  );
}

// ─── Light Themes (3) ───

class LightThemes {
  static const mint = AppPalette(
    primary: Color(0xFF059669), primaryLight: Color(0xFF34D399), primaryDark: Color(0xFF047857),
    accent: Color(0xFF10B981), bgPrimary: Color(0xFFF0FDF4), bgSecondary: Color(0xFFECFDF5),
    bgSurface: Color(0xFFD1FAE5), bgCard: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF064E3B), textSecondary: Color(0xFF065F46), textMuted: Color(0xFF6B7280),
    success: Color(0xFF059669), error: Color(0xFFDC2626), warning: Color(0xFFD97706),
    border: Color(0xFFA7F3D0), glassTint: Color(0x0A059669), shadow: Color(0x1A000000),
  );

  static const sky = AppPalette(
    primary: Color(0xFF2563EB), primaryLight: Color(0xFF60A5FA), primaryDark: Color(0xFF1D4ED8),
    accent: Color(0xFF3B82F6), bgPrimary: Color(0xFFF0F9FF), bgSecondary: Color(0xFFE0F2FE),
    bgSurface: Color(0xFFBAE6FD), bgCard: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF0C4A6E), textSecondary: Color(0xFF075985), textMuted: Color(0xFF6B7280),
    success: Color(0xFF059669), error: Color(0xFFDC2626), warning: Color(0xFFD97706),
    border: Color(0xFF93C5FD), glassTint: Color(0x0A2563EB), shadow: Color(0x1A000000),
  );

  static const rose = AppPalette(
    primary: Color(0xFFDB2777), primaryLight: Color(0xFFF472B6), primaryDark: Color(0xFFBE185D),
    accent: Color(0xFFEC4899), bgPrimary: Color(0xFFFFF1F2), bgSecondary: Color(0xFFFFE4E6),
    bgSurface: Color(0xFFFECDD3), bgCard: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF881337), textSecondary: Color(0xFF9F1239), textMuted: Color(0xFF6B7280),
    success: Color(0xFF059669), error: Color(0xFFDC2626), warning: Color(0xFFD97706),
    border: Color(0xFFF9A8D4), glassTint: Color(0x0ADB2777), shadow: Color(0x1A000000),
  );
}

// ─── App Theme ───

enum AppThemeColor { green, blue, purple, orange, pink, cyan, red, amber }

class AppTheme {
  final String id;
  final String name;
  final AppThemeColor color;
  final AppPalette palette;
  final bool isDark;
  final double glassOpacity;
  final double glassBlur;

  const AppTheme({
    required this.id, required this.name, required this.color,
    required this.palette, required this.isDark,
    this.glassOpacity = 0.6, this.glassBlur = 20,
  });

  Color get primary => palette.primary;
  Color get bgPrimary => palette.bgPrimary;
  Color get bgSecondary => palette.bgSecondary;
  Color get bgSurface => palette.bgSurface;
  Color get bgCard => palette.bgCard;
  Color get textPrimary => palette.textPrimary;
  Color get textSecondary => palette.textSecondary;
  Color get textMuted => palette.textMuted;
  Color get success => palette.success;
  Color get error => palette.error;
  Color get warning => palette.warning;
  Color get border => palette.border;
  Color get glassTint => palette.glassTint;
  Color get shadow => palette.shadow;
  Color get accent => palette.accent;

  Color get protocolReality => const Color(0xFF22D3EE);
  Color get protocolTls => const Color(0xFF34D399);
  Color get protocolTcp => const Color(0xFFFBBF24);
  Color get protocolXhttp => const Color(0xFFA78BFA);

  Color protocolColor(VpnSecurity? security) {
    switch (security) {
      case VpnSecurity.reality: return protocolReality;
      case VpnSecurity.tls: return protocolTls;
      default: return primary;
    }
  }
}

// ─── Theme Registry ───

class ThemeRegistry {
  static const List<AppTheme> dark = [
    AppTheme(id: 'forest', name: 'Лесной', color: AppThemeColor.green, palette: DarkThemes.forest, isDark: true),
    AppTheme(id: 'midnight', name: 'Полночь', color: AppThemeColor.blue, palette: DarkThemes.midnight, isDark: true),
    AppTheme(id: 'cyberpunk', name: 'Киберпанк', color: AppThemeColor.purple, palette: DarkThemes.cyberpunk, isDark: true),
    AppTheme(id: 'arctic', name: 'Арктика', color: AppThemeColor.cyan, palette: DarkThemes.arctic, isDark: true),
    AppTheme(id: 'ember', name: 'Угли', color: AppThemeColor.orange, palette: DarkThemes.ember, isDark: true),
  ];

  static const List<AppTheme> light = [
    AppTheme(id: 'mint', name: 'Мятный', color: AppThemeColor.green, palette: LightThemes.mint, isDark: false),
    AppTheme(id: 'sky', name: 'Небо', color: AppThemeColor.blue, palette: LightThemes.sky, isDark: false),
    AppTheme(id: 'rose', name: 'Роза', color: AppThemeColor.pink, palette: LightThemes.rose, isDark: false),
  ];

  static AppTheme get(String id) {
    for (final t in [...dark, ...light]) {
      if (t.id == id) return t;
    }
    return dark.first;
  }
}

// ─── Glass Theme InheritedWidget ───

class GlassTheme extends InheritedWidget {
  final AppTheme theme;

  const GlassTheme({super.key, required this.theme, required super.child});

  static AppTheme of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<GlassTheme>();
    return widget?.theme ?? ThemeRegistry.dark.first;
  }

  @override
  bool updateShouldNotify(GlassTheme oldWidget) => theme.id != oldWidget.theme.id;
}
