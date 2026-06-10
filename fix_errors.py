#!/usr/bin/env python3
"""Fix remaining compilation errors in maxspeed_vpn."""
import os, re, glob

# 1. Fix AppRadii - ensure rMd/rSm/rLg exist
APP_RADII = '''import 'package:flutter/material.dart';

/// Border radius constants.
class AppRadii {
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 24;

  // Legacy aliases
  static const double rXs = 4;
  static const double rSm = 6;
  static const double rMd = 8;
  static const double rLg = 12;
  static const double rXl = 16;
  static const double r2xl = 20;
  static const double r3xl = 24;
  static const double rFull = 9999;
}
'''

# 2. Fix AppDurations - ensure 'fast' exists
APP_DURATIONS = '''import 'package:flutter/material.dart';

/// Duration constants.
class AppDurations {
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration reconnectDelay = Duration(seconds: 5);
  static const Duration subscriptionRefresh = Duration(hours: 1);
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration animationDuration = Duration(milliseconds: 300);

  // Legacy aliases
  static const Duration fastest = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration slowest = Duration(milliseconds: 800);
  static const Duration pageTransition = Duration(milliseconds: 250);
  static const Duration dialogTransition = Duration(milliseconds: 200);
  static const Duration snackbar = Duration(seconds: 3);
  static const Duration toast = Duration(seconds: 2);
  static const Duration tooltip = Duration(milliseconds: 500);
  static const Duration ripple = Duration(milliseconds: 400);
  static const Duration shimmer = Duration(milliseconds: 1500);
  static const Duration pulse = Duration(milliseconds: 1000);
  static const Duration bounce = Duration(milliseconds: 600);
  static const Duration spin = Duration(milliseconds: 1000);
  static const Duration progress = Duration(milliseconds: 300);
  static const Duration connectionAnimation = Duration(milliseconds: 1500);
  static const Duration pingAnimation = Duration(milliseconds: 800);
  static const Duration speedTestAnimation = Duration(seconds: 10);
  static const Duration autoReconnect = Duration(seconds: 3);
  static const Duration healthCheck = Duration(seconds: 30);
  static const Duration sessionTimeout = Duration(minutes: 30);
  static const Duration tokenExpiration = Duration(hours: 24);
  static const Duration cacheExpiration = Duration(hours: 1);
  static const Duration logRetention = Duration(days: 7);
}
'''

# 3. Fix AppShadows - ensure 'none' exists
APP_SHADOWS = '''import 'package:flutter/material.dart';

/// Box shadow constants.
class AppShadows {
  static const BoxShadow sm = BoxShadow(
    color: Color(0x1A000000),
    blurRadius: 2,
    offset: Offset(0, 1),
  );
  static const BoxShadow md = BoxShadow(
    color: Color(0x26000000),
    blurRadius: 4,
    offset: Offset(0, 2),
  );
  static const BoxShadow lg = BoxShadow(
    color: Color(0x33000000),
    blurRadius: 8,
    offset: Offset(0, 4),
  );

  // Legacy aliases
  static const BoxShadow none = BoxShadow(
    color: Color(0x00000000),
    blurRadius: 0,
    offset: Offset(0, 0),
  );
  static const BoxShadow xl = BoxShadow(
    color: Color(0x3D000000),
    blurRadius: 12,
    offset: Offset(0, 6),
  );
  static const BoxShadow xxl = BoxShadow(
    color: Color(0x4D000000),
    blurRadius: 24,
    offset: Offset(0, 12),
  );
}
'''

# 4. Fix AppSpacing
APP_SPACING = '''import 'package:flutter/material.dart';

/// Spacing constants.
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  // Legacy aliases
  static const double xxxl = 32;
  static const double xxxxl = 48;
  static const double xxxxxl = 64;
}
'''

# 5. Fix AppText - ensure headlineSmall/labelSmall/bodyMedium exist
APP_TEXT = '''import 'package:flutter/material.dart';

/// Text style constants.
class AppText {
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );
  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.3,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.normal,
  );
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  // Legacy aliases
  static const TextStyle h1 = heading1;
  static const TextStyle h2 = heading2;
  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );
  static const TextStyle h4 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );
  static const TextStyle bodyMedium = body;
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
  );
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
  );
  static const TextStyle mono = TextStyle(
    fontFamily: 'monospace',
    fontSize: 14,
  );
  static const TextStyle monoSmall = TextStyle(
    fontFamily: 'monospace',
    fontSize: 12,
  );
  static const TextStyle headlineSmall = h3;
}
'''

# 6. Create AppTextStyles alias
APP_TEXT_STYLES = '''import 'package:flutter/material.dart';

/// Text style constants (alias for AppText).
typedef AppTextStyles = AppText;
'''

# 7. Create AppGradients
APP_GRADIENTS = '''import 'package:flutter/material.dart';

/// Gradient constants.
class AppGradients {
  static const LinearGradient primary = LinearGradient(
    colors: [Color(0xFF38BDF8), Color(0xFF60A5FA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient connected = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const LinearGradient card = LinearGradient(
    colors: [Color(0xFF141824), Color(0xFF1C2033)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
'''

# 8. Create AppCurves
APP_CURVES = '''import 'package:flutter/material.dart';

/// Animation curve constants.
class AppCurves {
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn;
  static const Curve bounceIn = Curves.bounceIn;
  static const Curve bounceOut = Curves.bounceOut;
  static const Curve elasticIn = Curves.elasticIn;
  static const Curve elasticOut = Curves.elasticOut;
}
'''

files = {
    'lib/core/theme/app_radii.dart': APP_RADII,
    'lib/core/theme/app_durations.dart': APP_DURATIONS,
    'lib/core/theme/app_shadows.dart': APP_SHADOWS,
    'lib/core/theme/app_spacing.dart': APP_SPACING,
    'lib/presentation/theme/app_text.dart': APP_TEXT,
    'lib/presentation/theme/app_text_styles.dart': APP_TEXT_STYLES,
    'lib/core/theme/app_gradients.dart': APP_GRADIENTS,
    'lib/core/theme/app_curves.dart': APP_CURVES,
}

for path, content in files.items():
    full_path = os.path.join('/root/maxspeed_vpn', path)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, 'w') as f:
        f.write(content)
    print(f"  WROTE: {path}")

# 9. Fix VpnConnectionStatus - add missing getters
# Find vpn_models.dart and check what's there
vpn_models_path = '/root/maxspeed_vpn/lib/data/models/vpn_models.dart'
with open(vpn_models_path, 'r') as f:
    vm = f.read()

# Add isConnected, activeServer getters if missing
if 'isConnected' not in vm:
    # Find the VpnConnectionState enum and add extension
    vm = vm + '''

/// Extension for VpnConnectionState convenience getters.
extension VpnConnectionStateExt on VpnConnectionState {
  bool get isConnected => this == VpnConnectionState.connected;
  bool get isConnecting => this == VpnConnectionState.connecting || this == VpnConnectionState.reconnecting;
  bool get isDisconnected => this == VpnConnectionState.disconnected;
  VpnServer? get activeServer => null; // Placeholder - actual server tracked by service
}
'''
    with open(vpn_models_path, 'w') as f:
        f.write(vm)
    print("  WROTE: vpn_models.dart (added extension)")

# 10. Create missing utility files
UTILS = {
    'core/utils/app_toast.dart': '''import 'package:flutter/material.dart';

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
''',
    'core/utils/formatters.dart': '''/// Data formatting utilities.
class Formatters {
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static String formatDuration(Duration d) {
    if (d.inDays > 0) return '${d.inDays}д ${d.inHours % 24}ч';
    if (d.inHours > 0) return '${d.inHours}ч ${d.inMinutes % 60}м';
    if (d.inMinutes > 0) return '${d.inMinutes}м ${d.inSeconds % 60}с';
    return '${d.inSeconds}с';
  }

  static String formatSpeed(int bytesPerSecond) => '${formatBytes(bytesPerSecond)}/s';
  static String formatPing(int ms) => '$ms ms';
  static String formatDate(DateTime dt) => '${dt.day}.${dt.month}.${dt.year}';
  static String formatTime(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  static String formatDateTime(DateTime dt) => '${formatDate(dt)} ${formatTime(dt)}';
}
''',
    'core/utils/validators.dart': '''/// Input validation utilities.
class Validators {
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https' || uri.scheme == 'naive');
    } catch (_) {
      return false;
    }
  }

  static bool isValidEmail(String email) {
    return RegExp(r'^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$').hasMatch(email);
  }

  static bool isValidPort(String port) {
    final n = int.tryParse(port);
    return n != null && n > 0 && n <= 65535;
  }

  static bool isValidServerName(String name) => name.isNotEmpty && name.length <= 64;
  static bool isValidPassword(String pw) => pw.length >= 8 && pw.length <= 128;
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName обязательно';
    return null;
  }
}
''',
    'core/utils/permission_status.dart': '''/// Permission status enum.
enum PermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  limited,
  unknown;

  bool get isGranted => this == granted;
  bool get isDenied => this == denied || this == permanentlyDenied;
}
''',
    'core/utils/share_utils.dart': '''import 'package:flutter/services.dart';

/// Share utility functions.
class ShareUtils {
  static Future<void> shareText(String text) async {
    // Fallback - copy to clipboard
    await Clipboard.setData(ClipboardData(text: text));
  }

  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  static Future<String?> getClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text;
  }
}
''',
    'core/utils/layout_constants.dart': '''/// Layout constants used across the app.
class LayoutConstants {
  static const double maxContentWidth = 600;
  static const double sidebarWidth = 280;
  static const double bottomNavHeight = 64;
  static const double topBarHeight = 56;
  static const double fabSize = 56;
  static const double drawerWidth = 300;
  static const double dialogMaxWidth = 480;
  static const double listItemHeight = 72;
  static const double cardMinHeight = 120;
}
''',
}

for path, content in UTILS.items():
    full_path = os.path.join('/root/maxspeed_vpn', path)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, 'w') as f:
        f.write(content)
    print(f"  WROTE: {path}")

print("\nDone! All files written.")
