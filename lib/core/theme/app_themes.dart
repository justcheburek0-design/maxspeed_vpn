import 'package:flutter/material.dart';
import 'package:maxspeed_vpn/data/models/vpn_models.dart';

// ─── INCY-style Material3 Dark Theme ───
// Background: #0A0A0D, Accent: #A8E63D (yellow-green)
// Based on Material3 design tokens from INCY v3.2.1

class AppPalette {
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color onSecondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color surface;
  final Color onSurface;
  final Color surfaceVariant;
  final Color onSurfaceVariant;
  final Color outline;
  final Color outlineVariant;
  final Color error;
  final Color onError;
  final Color errorContainer;
  final Color onErrorContainer;
  final Color scrim;
  final Color shadow;
  final Color bgPrimary;
  final Color bgSecondary;
  final Color success;
  final Color warning;

  const AppPalette({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.surface,
    required this.onSurface,
    required this.surfaceVariant,
    required this.onSurfaceVariant,
    required this.outline,
    required this.outlineVariant,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.scrim,
    required this.shadow,
    required this.bgPrimary,
    required this.bgSecondary,
    required this.success,
    required this.warning,
  });
}

// ─── INCY Dark (default) ───
// Near-black bg #0A0A0D, yellow-green accent #A8E63D
class IncyDark {
  static const palette = AppPalette(
    primary: Color(0xFFA8E63D),
    onPrimary: Color(0xFF1A2E00),
    primaryContainer: Color(0xFF2A4A00),
    onPrimaryContainer: Color(0xFFC8F57D),
    secondary: Color(0xFFBCCBAD),
    onSecondary: Color(0xFF273420),
    secondaryContainer: Color(0xFF3D4A35),
    onSecondaryContainer: Color(0xFFD8E7C8),
    surface: Color(0xFF131410),
    onSurface: Color(0xFFE4E3D9),
    surfaceVariant: Color(0xFF46483D),
    onSurfaceVariant: Color(0xFFC7C7BA),
    outline: Color(0xFF919285),
    outlineVariant: Color(0xFF46483D),
    error: Color(0xFFFF7043),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    scrim: Color(0xFF000000),
    shadow: Color(0x40000000),
    bgPrimary: Color(0xFF0A0A0D),
    bgSecondary: Color(0xFF131410),
    success: Color(0xFFA8E63D),
    warning: Color(0xFFFBBF24),
  );
}

// ─── Additional Dark Themes (Material3 style) ───

class DarkThemes {
  static const forest = AppPalette(
    primary: Color(0xFF81C784),
    onPrimary: Color(0xFF003910),
    primaryContainer: Color(0xFF005319),
    onPrimaryContainer: Color(0xFFA0F4A4),
    secondary: Color(0xFFB9CCB3),
    onSecondary: Color(0xFF253423),
    secondaryContainer: Color(0xFF3B4B38),
    onSecondaryContainer: Color(0xFFD5E8CF),
    surface: Color(0xFF101510),
    onSurface: Color(0xFFE0E4DB),
    surfaceVariant: Color(0xFF414941),
    onSurfaceVariant: Color(0xFFC1C9BF),
    outline: Color(0xFF8B9388),
    outlineVariant: Color(0xFF414941),
    error: Color(0xFFFF7043),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    scrim: Color(0xFF000000),
    shadow: Color(0x40000000),
    bgPrimary: Color(0xFF0A0F0D),
    bgSecondary: Color(0xFF101510),
    success: Color(0xFF81C784),
    warning: Color(0xFFFBBF24),
  );

  static const midnight = AppPalette(
    primary: Color(0xFF90CAF9),
    onPrimary: Color(0xFF003258),
    primaryContainer: Color(0xFF00497D),
    onPrimaryContainer: Color(0xFFD1E4FF),
    secondary: Color(0xFFBBC7DB),
    onSecondary: Color(0xFF263141),
    secondaryContainer: Color(0xFF3C4858),
    onSecondaryContainer: Color(0xFFD7E3F7),
    surface: Color(0xFF111318),
    onSurface: Color(0xFFE2E2E9),
    surfaceVariant: Color(0xFF43474E),
    onSurfaceVariant: Color(0xFFC3C6CF),
    outline: Color(0xFF8D9199),
    outlineVariant: Color(0xFF43474E),
    error: Color(0xFFFF7043),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    scrim: Color(0xFF000000),
    shadow: Color(0x60000000),
    bgPrimary: Color(0xFF0B0D14),
    bgSecondary: Color(0xFF111318),
    success: Color(0xFF81C784),
    warning: Color(0xFFFBBF24),
  );

  static const cyberpunk = AppPalette(
    primary: Color(0xFFF48FB1),
    onPrimary: Color(0xFF5E1233),
    primaryContainer: Color(0xFF782949),
    onPrimaryContainer: Color(0xFFFFD9E2),
    secondary: Color(0xFFE0BCDC),
    onSecondary: Color(0xFF40284C),
    secondaryContainer: Color(0xFF583E63),
    onSecondaryContainer: Color(0xFFFCD7F8),
    surface: Color(0xFF18121E),
    onSurface: Color(0xFFEADFE6),
    surfaceVariant: Color(0xFF4D4353),
    onSurfaceVariant: Color(0xFFD0C2D3),
    outline: Color(0xFF998D9D),
    outlineVariant: Color(0xFF4D4353),
    error: Color(0xFFFF7043),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    scrim: Color(0xFF000000),
    shadow: Color(0x60000000),
    bgPrimary: Color(0xFF0D0A14),
    bgSecondary: Color(0xFF18121E),
    success: Color(0xFF81C784),
    warning: Color(0xFFFBBF24),
  );

  static const arctic = AppPalette(
    primary: Color(0xFF80DEEA),
    onPrimary: Color(0xFF003739),
    primaryContainer: Color(0xFF004F52),
    onPrimaryContainer: Color(0xFFA1F0F7),
    secondary: Color(0xFFB2CCCE),
    onSecondary: Color(0xFF1D3436),
    secondaryContainer: Color(0xFF334B4D),
    onSecondaryContainer: Color(0xFFCEE8EA),
    surface: Color(0xFF0F1419),
    onSurface: Color(0xFFDEE3E7),
    surfaceVariant: Color(0xFF40484C),
    onSurfaceVariant: Color(0xFFC0C8CC),
    outline: Color(0xFF8A9296),
    outlineVariant: Color(0xFF40484C),
    error: Color(0xFFFF7043),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    scrim: Color(0xFF000000),
    shadow: Color(0x40000000),
    bgPrimary: Color(0xFF0A1218),
    bgSecondary: Color(0xFF0F1419),
    success: Color(0xFF81C784),
    warning: Color(0xFFFBBF24),
  );

  static const ember = AppPalette(
    primary: Color(0xFFFFB74D),
    onPrimary: Color(0xFF462B00),
    primaryContainer: Color(0xFF643F00),
    onPrimaryContainer: Color(0xFFFFDDB3),
    secondary: Color(0xFFE0C4A8),
    onSecondary: Color(0xFF3D2E1C),
    secondaryContainer: Color(0xFF554431),
    onSecondaryContainer: Color(0xFFFDDFC5),
    surface: Color(0xFF161310),
    onSurface: Color(0xFFECE0D6),
    surfaceVariant: Color(0xFF4E453D),
    onSurfaceVariant: Color(0xFFD1C4B8),
    outline: Color(0xFF9A8E83),
    outlineVariant: Color(0xFF4E453D),
    error: Color(0xFFFF7043),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    scrim: Color(0xFF000000),
    shadow: Color(0x40000000),
    bgPrimary: Color(0xFF120D0A),
    bgSecondary: Color(0xFF161310),
    success: Color(0xFF81C784),
    warning: Color(0xFFFBBF24),
  );
}

// ─── Light Themes (Material3 style) ───

class LightThemes {
  static const mint = AppPalette(
    primary: Color(0xFF006D3B),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF89F8B5),
    onPrimaryContainer: Color(0xFF00210E),
    secondary: Color(0xFF4F6354),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFD1E8D5),
    onSecondaryContainer: Color(0xFF0C1F13),
    surface: Color(0xFFF6FBF3),
    onSurface: Color(0xFF181D18),
    surfaceVariant: Color(0xFFDDE5DA),
    onSurfaceVariant: Color(0xFF414941),
    outline: Color(0xFF717970),
    outlineVariant: Color(0xFFC1C9BF),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    scrim: Color(0xFF000000),
    shadow: Color(0x1A000000),
    bgPrimary: Color(0xFFF6FBF3),
    bgSecondary: Color(0xFFECF5E9),
    success: Color(0xFF006D3B),
    warning: Color(0xFFD97706),
  );

  static const sky = AppPalette(
    primary: Color(0xFF0061A4),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD1E4FF),
    onPrimaryContainer: Color(0xFF001D36),
    secondary: Color(0xFF535F70),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFD7E3F7),
    onSecondaryContainer: Color(0xFF101C2B),
    surface: Color(0xFFF8F9FF),
    onSurface: Color(0xFF191C20),
    surfaceVariant: Color(0xFFDFE2EB),
    onSurfaceVariant: Color(0xFF43474E),
    outline: Color(0xFF73777F),
    outlineVariant: Color(0xFFC3C6CF),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    scrim: Color(0xFF000000),
    shadow: Color(0x1A000000),
    bgPrimary: Color(0xFFF8F9FF),
    bgSecondary: Color(0xFFECF1F8),
    success: Color(0xFF006D3B),
    warning: Color(0xFFD97706),
  );

  static const rose = AppPalette(
    primary: Color(0xFFB91C56),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFFFD9E2),
    onPrimaryContainer: Color(0xFF400014),
    secondary: Color(0xFF74565F),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFFFD9E2),
    onSecondaryContainer: Color(0xFF2B151C),
    surface: Color(0xFFFFF8F8),
    onSurface: Color(0xFF201A1B),
    surfaceVariant: Color(0xFFF2DDE2),
    onSurfaceVariant: Color(0xFF514347),
    outline: Color(0xFF837377),
    outlineVariant: Color(0xFFD5C2C6),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    scrim: Color(0xFF000000),
    shadow: Color(0x1A000000),
    bgPrimary: Color(0xFFFFF8F8),
    bgSecondary: Color(0xFFF8ECED),
    success: Color(0xFF006D3B),
    warning: Color(0xFFD97706),
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

  const AppTheme({
    required this.id,
    required this.name,
    required this.color,
    required this.palette,
    required this.isDark,
  });

  // Convenience getters
  Color get primary => palette.primary;
  Color get onPrimary => palette.onPrimary;
  Color get primaryContainer => palette.primaryContainer;
  Color get onPrimaryContainer => palette.onPrimaryContainer;
  Color get secondary => palette.secondary;
  Color get onSecondary => palette.onSecondary;
  Color get secondaryContainer => palette.secondaryContainer;
  Color get onSecondaryContainer => palette.onSecondaryContainer;
  Color get surface => palette.surface;
  Color get onSurface => palette.onSurface;
  Color get surfaceVariant => palette.surfaceVariant;
  Color get onSurfaceVariant => palette.onSurfaceVariant;
  Color get outline => palette.outline;
  Color get outlineVariant => palette.outlineVariant;
  Color get error => palette.error;
  Color get onError => palette.onError;
  Color get errorContainer => palette.errorContainer;
  Color get onErrorContainer => palette.onErrorContainer;
  Color get bgPrimary => palette.bgPrimary;
  Color get bgSecondary => palette.bgSecondary;
  Color get success => palette.success;
  Color get warning => palette.warning;
  Color get scrim => palette.scrim;
  Color get shadow => palette.shadow;

  // Protocol colors
  Color get protocolReality => const Color(0xFF22D3EE);
  Color get protocolTls => const Color(0xFF34D399);
  Color get protocolTcp => const Color(0xFFFBBF24);
  Color get protocolXhttp => const Color(0xFFA78BFA);

  Color protocolColor(VpnSecurity? security) {
    switch (security) {
      case VpnSecurity.reality:
        return protocolReality;
      case VpnSecurity.tls:
        return protocolTls;
      default:
        return primary;
    }
  }

  // Material3 ThemeData
  ThemeData get themeData {
    final scheme = isDark
        ? ColorScheme.dark(
            primary: primary,
            onPrimary: onPrimary,
            primaryContainer: primaryContainer,
            onPrimaryContainer: onPrimaryContainer,
            secondary: secondary,
            onSecondary: onSecondary,
            secondaryContainer: secondaryContainer,
            onSecondaryContainer: onSecondaryContainer,
            surface: surface,
            onSurface: onSurface,
            surfaceContainerHighest: surfaceVariant,
            onSurfaceVariant: onSurfaceVariant,
            outline: outline,
            outlineVariant: outlineVariant,
            error: error,
            onError: onError,
            errorContainer: errorContainer,
            onErrorContainer: onErrorContainer,
            scrim: scrim,
          )
        : ColorScheme.light(
            primary: primary,
            onPrimary: onPrimary,
            primaryContainer: primaryContainer,
            onPrimaryContainer: onPrimaryContainer,
            secondary: secondary,
            onSecondary: onSecondary,
            secondaryContainer: secondaryContainer,
            onSecondaryContainer: onSecondaryContainer,
            surface: surface,
            onSurface: onSurface,
            surfaceContainerHighest: surfaceVariant,
            onSurfaceVariant: onSurfaceVariant,
            outline: outline,
            outlineVariant: outlineVariant,
            error: error,
            onError: onError,
            errorContainer: errorContainer,
            onErrorContainer: onErrorContainer,
            scrim: scrim,
          );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bgPrimary,
      dividerColor: outlineVariant,
    );
  }
}

// ─── Theme Registry ───

class ThemeRegistry {
  static const List<AppTheme> dark = [
    AppTheme(
      id: 'incy',
      name: 'INCY',
      color: AppThemeColor.green,
      palette: IncyDark.palette,
      isDark: true,
    ),
    AppTheme(
      id: 'forest',
      name: 'Лесной',
      color: AppThemeColor.green,
      palette: DarkThemes.forest,
      isDark: true,
    ),
    AppTheme(
      id: 'midnight',
      name: 'Полночь',
      color: AppThemeColor.blue,
      palette: DarkThemes.midnight,
      isDark: true,
    ),
    AppTheme(
      id: 'cyberpunk',
      name: 'Киберпанк',
      color: AppThemeColor.purple,
      palette: DarkThemes.cyberpunk,
      isDark: true,
    ),
    AppTheme(
      id: 'arctic',
      name: 'Арктика',
      color: AppThemeColor.cyan,
      palette: DarkThemes.arctic,
      isDark: true,
    ),
    AppTheme(
      id: 'ember',
      name: 'Угли',
      color: AppThemeColor.orange,
      palette: DarkThemes.ember,
      isDark: true,
    ),
  ];

  static const List<AppTheme> light = [
    AppTheme(
      id: 'mint',
      name: 'Мятный',
      color: AppThemeColor.green,
      palette: LightThemes.mint,
      isDark: false,
    ),
    AppTheme(
      id: 'sky',
      name: 'Небо',
      color: AppThemeColor.blue,
      palette: LightThemes.sky,
      isDark: false,
    ),
    AppTheme(
      id: 'rose',
      name: 'Роза',
      color: AppThemeColor.pink,
      palette: LightThemes.rose,
      isDark: false,
    ),
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
  bool updateShouldNotify(GlassTheme oldWidget) =>
      theme.id != oldWidget.theme.id;
}
