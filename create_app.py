#!/usr/bin/env python3
"""Create a clean, working MaxSpeedVPN Flutter app from scratch."""
import os

os.chdir('/root/maxspeed_vpn')

def w(path, content):
    """Write content to file, creating parent dirs as needed."""
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"  ✓ {path}")

# ============================================================
# CORE THEME
# ============================================================
print("Creating theme files...")

w('lib/core/theme/app_colors.dart', r'''import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  static const Color primary = Color(0xFF38BDF8);
  static const Color primaryDark = Color(0xFF0284C7);
  static const Color primaryLight = Color(0xFF7DD3FC);
  static const Color bgPrimary = Color(0xFF0B0D14);
  static const Color bgSecondary = Color(0xFF11131A);
  static const Color bgSurface = Color(0xFF1C2033);
  static const Color bgSurfaceHover = Color(0xFF242840);
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color success = Color(0xFF34D399);
  static const Color error = Color(0xFFF87171);
  static const Color warning = Color(0xFFFBBF24);
  static const Color danger = Color(0xFFEF4444);
  static const Color protocolVless = Color(0xFF38BDF8);
  static const Color protocolVmess = Color(0xFF22D3EE);
  static const Color protocolTrojan = Color(0xFFA78BFA);
  static const Color protocolShadowsocks = Color(0xFF34D399);
  static const Color protocolWireguard = Color(0xFFF472B6);
  static const Color protocolReality = Color(0xFF22D3EE);
  static const Color protocolTUIC = Color(0xFFA78BFA);
  static const Color protocolHysteria = Color(0xFFFBBF24);
  static const Color protocolNaive = Color(0xFF60A5FA);
  static const Color border = Color(0xFF2D3348);
  static const Color borderHover = Color(0xFF3D4460);
  static const Color card = Color(0xFF161B26);
  static const Color overlay = Color(0x80000000);
  static const Color connected = success;
  static const Color connecting = warning;
  static const Color disconnected = Color(0xFF6B7280);
  static const Color security = Color(0xFF22D3EE);
  static const Color none = Colors.transparent;
}
''')

w('lib/core/theme/app_text.dart', r'''import 'package:flutter/material.dart';
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
''')

w('lib/core/theme/app_radii.dart', r'''class AppRadii {
  AppRadii._();
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double full = 999.0;
  static const double rSm = sm;
  static const double rMd = md;
  static const double rLg = lg;
  static const double rXl = xl;
}
''')

w('lib/core/theme/app_spacing.dart', r'''class AppSpacing {
  AppSpacing._();
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;
}
''')

w('lib/core/theme/app_shadows.dart', r'''import 'package:flutter/material.dart';

class AppShadows {
  AppShadows._();
  static const List<BoxShadow> none = [];
  static const List<BoxShadow> sm = [BoxShadow(color: Color(0x1A000000), blurRadius: 4, offset: Offset(0, 1))];
  static const List<BoxShadow> md = [BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2))];
  static const List<BoxShadow> lg = [BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 4))];
  static const List<BoxShadow> xl = [BoxShadow(color: Color(0x1A000000), blurRadius: 24, offset: Offset(0, 8))];
  static const List<BoxShadow> xxl = [BoxShadow(color: Color(0x26000000), blurRadius: 32, offset: Offset(0, 12))];
  static const List<BoxShadow> glow = [BoxShadow(color: Color(0x4038BDF8), blurRadius: 20, offset: Offset(0, 0))];
  static const List<BoxShadow> dark = xxl;
  static const List<BoxShadow> card = md;
  static const List<BoxShadow> glowSuccess = [BoxShadow(color: Color(0x4034D399), blurRadius: 20, offset: Offset(0, 0))];
}
''')

w('lib/core/theme/app_durations.dart', r'''class AppDurations {
  AppDurations._();
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);
  static const Duration pageTransition = Duration(milliseconds: 350);
  static const Duration snackbar = Duration(seconds: 3);
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration subscriptionCheck = Duration(hours: 1);
}
''')

w('lib/core/theme/app_gradients.dart', r'''import 'package:flutter/material.dart';
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
''')

w('lib/core/theme/app_curves.dart', r'''import 'package:flutter/animation.dart';

class AppCurves {
  AppCurves._();
  static const Curve standard = Curves.easeInOut;
  static const Curve accelerate = Curves.easeIn;
  static const Curve decelerate = Curves.easeOut;
  static const Curve sharp = Curves.easeInOutCubic;
  static const Curve bounce = Curves.elasticOut;
  static const Curve spring = Curves.elasticInOut;
  static const Curve fast = Curves.easeInOutQuart;
  static const Curve smooth = Curves.easeInOutCubicEmphasized;
}
''')

# ============================================================
# CORE UTILS
# ============================================================
print("Creating utils...")

w('lib/core/utils/formatters.dart', r'''import 'dart:math';

class Formatters {
  Formatters._();
  static String formatBytes(int bytes, {int decimals = 2}) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i.clamp(0, suffixes.length - 1)]}';
  }
  static String formatSpeed(int bps, {int decimals = 1}) {
    if (bps <= 0) return '0 B/s';
    const s = ['B/s', 'KB/s', 'MB/s', 'GB/s'];
    final i = (log(bps) / log(1024)).floor();
    return '${(bps / pow(1024, i)).toStringAsFixed(decimals)} ${s[i.clamp(0, s.length - 1)]}';
  }
  static String formatDuration(Duration d) {
    if (d.inHours > 0) return '${d.inHours}ч ${d.inMinutes.remainder(60)}м ${d.inSeconds.remainder(60)}с';
    if (d.inMinutes > 0) return '${d.inMinutes}м ${d.inSeconds.remainder(60)}с';
    return '${d.inSeconds}с';
  }
  static String formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  static String formatDateTime(DateTime d) => '${formatDate(d)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  static String formatTime(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  static String formatPing(int ms) => ms < 0 ? '—' : '${ms}ms';
  static String formatPercentage(double v, {int d = 1}) => '${(v * 100).toStringAsFixed(d)}%';
}
''')

w('lib/core/utils/validators.dart', r'''class Validators {
  Validators._();
  static bool isValidUrl(String url) { try { final u = Uri.parse(url); return u.hasScheme && (u.scheme == 'http' || u.scheme == 'https'); } catch (_) { return false; } }
  static bool isValidSubscriptionUrl(String url) { if (url.startsWith('naive+')) return isValidUrl(url.substring(6)); return isValidUrl(url) || url.contains('://'); }
  static bool isValidHost(String h) => h.isNotEmpty && !h.contains(' ');
  static bool isValidPort(int p) => p > 0 && p <= 65535;
  static String? validateRequired(String? v, {String f = 'Поле'}) => (v == null || v.trim().isEmpty) ? '$f обязательно' : null;
  static String? validateUrl(String? v) { if (v == null || v.trim().isEmpty) return 'URL обязателен'; if (!isValidSubscriptionUrl(v)) return 'Некорректный URL'; return null; }
}
''')

w('lib/core/utils/app_toast.dart', r'''import 'package:flutter/material.dart';
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
''')

# ============================================================
# CORE CONSTANTS
# ============================================================
print("Creating constants...")

w('lib/core/constants/app_constants.dart', r'''class AppConstants {
  AppConstants._();
  static const String appName = 'MaxSpeedVPN';
  static const String appVersion = '1.0.0';
  static const String packageName = 'ru.maxspeed.maxspeed_vpn';
  static const String methodChannelName = 'maxspeed.vpn';
  static const String routeHome = '/';
  static const String routeServers = '/servers';
  static const String routeSettings = '/settings';
  static const String routeLogs = '/logs';
  static const String routeOnboarding = '/onboarding';
  static const String keyThemeMode = 'theme_mode';
  static const String keyAutoConnect = 'auto_connect';
  static const String keyKillSwitch = 'kill_switch';
  static const String keyProtocol = 'protocol';
  static const String keyLastServer = 'last_server';
  static const String keySubscriptionUrl = 'subscription_url';
  static const String keyFirstLaunch = 'first_launch';
  static const bool defaultAutoConnect = false;
  static const bool defaultKillSwitch = false;
  static const String defaultProtocol = 'naive';
  static const int maxServers = 1000;
  static const int maxSubscriptions = 10;
  static const int maxLogEntries = 500;
  static const int connectionTimeout = 30;
  static const String supportUrl = 'https://t.me/maxspeedvpn_support';
  static const String privacyPolicyUrl = 'https://maxspeed.vpn/privacy';
  static const String termsUrl = 'https://maxspeed.vpn/terms';
}
''')

# ============================================================
# EXTENSIONS
# ============================================================
print("Creating extensions...")

w('lib/core/extensions/context_extensions.dart', r'''import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

extension ContextExt on BuildContext {
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 1024;
  bool get isDesktop => screenWidth >= 1024;
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(
      content: Text(message, style: AppText.bodyMedium(this)),
      backgroundColor: isError ? AppColors.error : AppColors.bgSurface,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }
}
''')

w('lib/core/extensions/date_extensions.dart', r'''extension DateTimeExt on DateTime {
  String get formatted => '${day.toString().padLeft(2, '0')}.${month.toString().padLeft(2, '0')}.$year';
  String get timeFormatted => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  String get dateTimeFormatted => '$formatted $timeFormatted';
  bool get isToday { final n = DateTime.now(); return year == n.year && month == n.month && day == n.day; }
  bool get isYesterday { final y = DateTime.now().subtract(const Duration(days: 1)); return year == y.year && month == y.month && day == y.day; }
}
''')

# ============================================================
# DATA MODELS
# ============================================================
print("Creating models...")

w('lib/data/models/vpn_models.dart', r'''import 'package:flutter/foundation.dart';

enum VpnProtocol { naive, vless, vmess, trojan, shadowsocks, wireguard, reality, tuic, hysteria }

extension VpnProtocolExt on VpnProtocol {
  String get displayName {
    switch (this) {
      case VpnProtocol.naive: return 'Naive';
      case VpnProtocol.vless: return 'VLESS';
      case VpnProtocol.vmess: return 'VMess';
      case VpnProtocol.trojan: return 'Trojan';
      case VpnProtocol.shadowsocks: return 'Shadowsocks';
      case VpnProtocol.wireguard: return 'WireGuard';
      case VpnProtocol.reality: return 'REALITY';
      case VpnProtocol.tuic: return 'TUIC';
      case VpnProtocol.hysteria: return 'Hysteria';
    }
  }
  String get shortName => displayName;
  String get label => displayName;
}

enum VpnConnectionState { disconnected, connecting, connected, disconnecting, error, reconnecting }

extension VpnConnectionStateExt on VpnConnectionState {
  String get displayName {
    switch (this) {
      case VpnConnectionState.disconnected: return 'Отключено';
      case VpnConnectionState.connecting: return 'Подключение...';
      case VpnConnectionState.connected: return 'Подключено';
      case VpnConnectionState.disconnecting: return 'Отключение...';
      case VpnConnectionState.error: return 'Ошибка';
      case VpnConnectionState.reconnecting: return 'Переподключение...';
    }
  }
  bool get isConnected => this == VpnConnectionState.connected;
  bool get isConnecting => this == VpnConnectionState.connecting || this == VpnConnectionState.reconnecting;
  bool get isDisconnected => this == VpnConnectionState.disconnected;
}

class VpnServer {
  final String id;
  final String name;
  final String address;
  final int port;
  final VpnProtocol protocol;
  final String? username;
  final String? password;
  final Map<String, dynamic> rawConfig;
  final bool isFavorite;
  final int? ping;
  final String? country;
  final String? flag;

  const VpnServer({required this.id, required this.name, required this.address, required this.port, required this.protocol, this.username, this.password, this.rawConfig = const {}, this.isFavorite = false, this.ping, this.country, this.flag});

  VpnServer copyWith({String? id, String? name, String? address, int? port, VpnProtocol? protocol, String? username, String? password, Map<String, dynamic>? rawConfig, bool? isFavorite, int? ping, String? country, String? flag}) => VpnServer(id: id ?? this.id, name: name ?? this.name, address: address ?? this.address, port: port ?? this.port, protocol: protocol ?? this.protocol, username: username ?? this.username, password: <REDACTED> ?? this.password, rawConfig: rawConfig ?? this.rawConfig, isFavorite: isFavorite ?? this.isFavorite, ping: ping ?? this.ping, country: country ?? this.country, flag: flag ?? this.flag);

  String get displayName => name.isNotEmpty ? name : '$address:$port';
  String get protocolTag => protocol.displayName;
  String get pingText => ping != null ? '${ping}ms' : '—';
  @override bool operator ==(Object o) => identical(this, o) || o is VpnServer && o.id == id;
  @override int get hashCode => id.hashCode;
}

class VpnSubscription {
  final String id;
  final String name;
  final String url;
  final List<VpnServer> servers;
  final DateTime? expiresAt;
  final bool isActive;
  final int uploadBytes;
  final int downloadBytes;
  final int totalBytes;

  const VpnSubscription({required this.id, required this.name, required this.url, this.servers = const [], this.expiresAt, this.isActive = true, this.uploadBytes = 0, this.downloadBytes = 0, this.totalBytes = 0});

  int get daysRemaining => expiresAt == null ? -1 : expiresAt!.difference(DateTime.now()).inDays;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  double get dataUsedGB => (uploadBytes + downloadBytes) / (1024 * 1024 * 1024);
  bool get isUnlimited => totalBytes <= 0;
  double get dataProgress => (isUnlimited || totalBytes <= 0) ? 0 : (uploadBytes + downloadBytes) / totalBytes;
}

class VpnConnectionStats {
  final int bytesSent;
  final int bytesReceived;
  final int uploadSpeed;
  final int downloadSpeed;
  final Duration duration;
  final int? pingMs;
  final String? serverName;

  const VpnConnectionStats({this.bytesSent = 0, this.bytesReceived = 0, this.uploadSpeed = 0, this.downloadSpeed = 0, this.duration = Duration.zero, this.pingMs, this.serverName});

  VpnConnectionStats copyWith({int? bytesSent, int? bytesReceived, int? uploadSpeed, int? downloadSpeed, Duration? duration, int? pingMs, String? serverName}) => VpnConnectionStats(bytesSent: bytesSent ?? this.bytesSent, bytesReceived: bytesReceived ?? this.bytesReceived, uploadSpeed: uploadSpeed ?? this.uploadSpeed, downloadSpeed: downloadSpeed ?? this.downloadSpeed, duration: duration ?? this.duration, pingMs: pingMs ?? this.pingMs, serverName: serverName ?? this.serverName);
}

enum VpnLogLevel { debug, info, warning, error }

class VpnLogEntry {
  final String id;
  final DateTime timestamp;
  final VpnLogLevel level;
  final String message;
  final String? details;

  const VpnLogEntry({required this.id, required this.timestamp, required this.level, required this.message, this.details});
}
''')

# ============================================================
# VPN PARSERS
# ============================================================
print("Creating VPN parsers...")

w('lib/vpn/naive_parser.dart', r'''class NaiveLink {
  final String username;
  final String password;
  final String host;
  final int port;
  final String raw;
  const NaiveLink({required this.username, required this.password, required this.host, required this.port, required this.raw});
  String get address => '$host:$port';
  @override String toString() => 'NaiveLink($username@$host:$port)';
}

class NaiveParser {
  static NaiveLink parse(String link) {
    try {
      final uri = Uri.parse(link);
      final parts = uri.userInfo.split(':');
      return NaiveLink(username: parts.first, password: <REDACTED> == 2 ? parts[1] : '', host: uri.host, port: uri.port > 0 ? uri.port : 443, raw: link);
    } catch (e) { throw FormatException('Invalid naive link: $e'); }
  }
  static bool isValid(String link) { try { parse(link); return true; } catch (_) { return false; } }
}
''')

w('lib/vpn/vless_parser.dart', r'''import '../data/models/vpn_models.dart';

class VlessParser {
  static VpnServer parse(String link, {String? name}) {
    try {
      final uri = Uri.parse(link);
      return VpnServer(id: uri.userInfo, name: name ?? Uri.decodeComponent(uri.fragment.isNotEmpty ? uri.fragment : '${uri.host}:${uri.port}'), address: uri.host, port: uri.port > 0 ? uri.port : 443, protocol: VpnProtocol.vless, username: uri.userInfo, rawConfig: {'uuid': uri.userInfo, 'host': uri.host, 'port': uri.port, 'security': uri.queryParameters['security'] ?? '', 'sni': uri.queryParameters['sni'] ?? uri.queryParameters['peer'] ?? '', 'path': uri.queryParameters['path'] ?? ''});
    } catch (e) { throw FormatException('Invalid VLESS link: $e'); }
  }
  static bool isValid(String link) { try { parse(link); return true; } catch (_) { return false; } }
}
''')

w('lib/vpn/protocol_parsers.dart', r'''import '../data/models/vpn_models.dart';
import 'naive_parser.dart';
import 'vless_parser.dart';

class ProtocolParsers {
  ProtocolParsers._();
  static VpnServer parseLink(String link, {String? name}) {
    final t = link.trim();
    if (t.startsWith('naive+')) {
      final nl = NaiveParser.parse(t);
      return VpnServer(id: '${nl.host}:${nl.port}', name: name ?? nl.address, address: nl.host, port: nl.port, protocol: VpnProtocol.naive, username: nl.username, password: <REDACTED> rawConfig: {'raw': nl.raw});
    }
    if (t.startsWith('vless://')) return VlessParser.parse(t, name: name);
    throw FormatException('Unsupported protocol: ${t.split(':').first}');
  }
  static List<VpnServer> parseSubscription(String content) {
    final servers = <VpnServer>[];
    for (final line in content.split(RegExp(r'[\r\n]+'))) {
      final t = line.trim();
      if (t.isEmpty || t.startsWith('#')) continue;
      try { servers.add(parseLink(t)); } catch (_) {}
    }
    return servers;
  }
}
''')

w('lib/vpn/singbox_config_generator.dart', r'''import 'dart:convert';
import '../data/models/vpn_models.dart';
import 'naive_parser.dart';

class SingboxConfigGenerator {
  SingboxConfigGenerator._();
  static String generate(VpnServer server) {
    return const JsonEncoder.withIndent('  ').convert({
      'outbounds': [_buildOutbound(server)],
      'route': {'final': 'proxy', 'rules': [{'outbound': 'proxy'}]},
      'dns': {'servers': [{'tag': 'google', 'address': 'tls://8.8.8.8'}]},
    });
  }
  static Map<String, dynamic> _buildOutbound(VpnServer server) {
    switch (server.protocol) {
      case VpnProtocol.naive: return _buildNaive(server);
      case VpnProtocol.vless: return _buildVless(server);
      default: return _buildNaive(server);
    }
  }
  static Map<String, dynamic> _buildNaive(VpnServer s) {
    String? u, p; String h = s.address; int pt = s.port;
    final raw = s.rawConfig['raw'] as String?;
    if (raw != null && raw.startsWith('naive+')) {
      final nl = NaiveParser.parse(raw); u = nl.username; p = <REDACTED> h = nl.host; pt = nl.port;
    } else { u = s.username; p = <REDACTED>
    return {'type': 'naive', 'tag': 'proxy', 'server': h, 'port': pt, 'username': u, 'password': p, 'tls': {'enabled': true, 'server_name': h}, 'network': 'tcp'};
  }
  static Map<String, dynamic> _buildVless(VpnServer s) => {'type': 'vless', 'tag': 'proxy', 'server': s.address, 'port': s.port, 'uuid': s.username ?? s.id, 'tls': {'enabled': true, 'server_name': s.rawConfig['sni'] ?? s.address}, 'network': 'tcp'};
}
''')

w('lib/vpn/vpn_config.dart', r'''class VpnConfig {
  VpnConfig._();
  static const String configFileName = 'singbox_config.json';
  static const String singboxBinaryName = 'sing-box';
  static const int defaultPort = 443;
  static const String defaultProtocol = 'naive';
}
''')

# ============================================================
# SERVICES
# ============================================================
print("Creating services...")

w('lib/services/vpn_service.dart', r'''import 'dart:async';
import 'package:flutter/services.dart';
import '../core/constants/app_constants.dart';
import '../data/models/vpn_models.dart';

class VpnService {
  static const _channel = MethodChannel(AppConstants.methodChannelName);
  VpnConnectionState _state = VpnConnectionState.disconnected;
  VpnConnectionState get state => _state;
  VpnServer? _activeServer;
  VpnServer? get activeServer => _activeServer;
  final _stateController = StreamController<VpnConnectionState>.broadcast();
  Stream<VpnConnectionState> get stateStream => _stateController.stream;

  Future<void> connect(VpnServer server) async {
    _activeServer = server;
    _setState(VpnConnectionState.connecting);
    try {
      await _channel.invokeMethod('connect', {'server': server.address, 'port': server.port, 'protocol': server.protocol.name, 'username': server.username ?? '', 'password': server.password ?? ''});
      _setState(VpnConnectionState.connected);
    } catch (e) { _setState(VpnConnectionState.error); rethrow; }
  }
  Future<void> disconnect() async {
    _setState(VpnConnectionState.disconnecting);
    try { await _channel.invokeMethod('disconnect'); _setState(VpnConnectionState.disconnected); } catch (e) { _setState(VpnConnectionState.error); rethrow; }
  }
  Future<void> toggle(VpnServer server) async { if (_state == VpnConnectionState.connected) { await disconnect(); } else { await connect(server); } }
  void _setState(VpnConnectionState s) { _state = s; _stateController.add(s); }
  void dispose() { _stateController.close(); }
}
''')

w('lib/services/subscription_service.dart', r'''import '../data/models/vpn_models.dart';
import '../vpn/protocol_parsers.dart';

class SubscriptionService {
  final List<VpnSubscription> _subs = [];
  List<VpnSubscription> get subscriptions => List.unmodifiable(_subs);
  Future<void> addSubscription(String url, {String? name}) async {
    try {
      final server = ProtocolParsers.parseLink(url);
      _subs.add(VpnSubscription(id: DateTime.now().millisecondsSinceEpoch.toString(), name: name ?? 'Subscription', url: url, servers: [server]));
    } catch (e) { throw FormatException('Failed to parse: $e'); }
  }
  void removeSubscription(String id) => _subs.removeWhere((s) => s.id == id);
  List<VpnServer> get allServers { final s = <VpnServer>[]; for (final sub in _subs) s.addAll(sub.servers); return s; }
}
''')

w('lib/services/settings_service.dart', r'''import 'package:flutter/material.dart';

class SettingsService {
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;
  bool _autoConnect = false;
  bool get autoConnect => _autoConnect;
  bool _killSwitch = false;
  bool get killSwitch => _killSwitch;
  String _protocol = 'naive';
  String get protocol => _protocol;
  Future<void> setThemeMode(ThemeMode m) async => _themeMode = m;
  Future<void> setAutoConnect(bool v) async => _autoConnect = v;
  Future<void> setKillSwitch(bool v) async => _killSwitch = v;
  Future<void> setProtocol(String v) async => _protocol = v;
}
''')

w('lib/services/log_service.dart', r'''import '../data/models/vpn_models.dart';

class LogService {
  final List<VpnLogEntry> _logs = [];
  List<VpnLogEntry> get logs => List.unmodifiable(_logs);
  void addLog(VpnLogLevel level, String message, {String? details}) {
    _logs.add(VpnLogEntry(id: DateTime.now().millisecondsSinceEpoch.toString(), timestamp: DateTime.now(), level: level, message: message, details: details));
    if (_logs.length > 500) _logs.removeAt(0);
  }
  void debug(String m) => addLog(VpnLogLevel.debug, m);
  void info(String m) => addLog(VpnLogLevel.info, m);
  void warning(String m) => addLog(VpnLogLevel.warning, m);
  void error(String m, {String? d}) => addLog(VpnLogLevel.error, m, details: d);
  void clear() => _logs.clear();
}
''')

# ============================================================
# WIDGETS
# ============================================================
print("Creating widgets...")

w('lib/presentation/widgets/power_button.dart', r'''import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/vpn_models.dart';

class PowerButton extends StatelessWidget {
  final VpnConnectionState state;
  final VoidCallback onPressed;
  const PowerButton({super.key, required this.state, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final connected = state == VpnConnectionState.connected;
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 180, height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: connected
              ? const LinearGradient(colors: [AppColors.success, Color(0xFF059669)], begin: Alignment.topLeft, end: Alignment.bottomRight)
              : const LinearGradient(colors: [AppColors.bgSurface, AppColors.bgSecondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: connected
              ? [BoxShadow(color: AppColors.success.withOpacity(0.4), blurRadius: 30, spreadRadius: 5)]
              : [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Center(child: Icon(Icons.power_settings_new_rounded, size: 72, color: connected ? Colors.white : AppColors.textMuted)),
      ),
    );
  }
}
''')

w('lib/presentation/widgets/server_list_item.dart', r'''import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/vpn_models.dart';

class ServerListItem extends StatelessWidget {
  final VpnServer server;
  final bool isSelected;
  final VoidCallback onTap;
  const ServerListItem({super.key, required this.server, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 1.5 : 1),
        ),
        child: Row(children: [
          Text(server.flag ?? '🏳️', style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(server.displayName, style: AppText.titleMedium(context)),
            const SizedBox(height: 2),
            Text('${server.protocol.displayName} · ${server.address}:${server.port}', style: AppText.bodySmall(context)),
          ])),
          if (server.ping != null) Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: _pingColor(server.ping!).withOpacity(0.1), borderRadius: BorderRadius.circular(AppRadii.sm)),
            child: Text(Formatters.formatPing(server.ping!), style: AppText.labelSmall(context).copyWith(color: _pingColor(server.ping!))),
          ),
          if (server.isFavorite) const Icon(Icons.star, color: AppColors.warning, size: 20),
        ]),
      ),
    );
  }
  Color _pingColor(int ms) => ms < 100 ? AppColors.success : ms < 200 ? AppColors.warning : AppColors.error;
}
''')

# ============================================================
# SCREENS
# ============================================================
print("Creating screens...")

w('lib/presentation/screens/home_screen.dart', r'''import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../data/models/vpn_models.dart';
import '../../services/vpn_service.dart';
import '../widgets/power_button.dart';

class HomeScreen extends StatefulWidget {
  final VpnService vpnService;
  const HomeScreen({super.key, required this.vpnService});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  VpnConnectionState _state = VpnConnectionState.disconnected;
  @override void initState() { super.initState(); _state = widget.vpnService.state; widget.vpnService.stateStream.listen((s) { if (mounted) setState(() => _state = s); }); }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(AppSpacing.md), child: Column(children: [
        _buildHeader(context),
        const SizedBox(height: AppSpacing.xl),
        PowerButton(state: _state, onPressed: _onToggle),
        const SizedBox(height: AppSpacing.md),
        Text(_state.displayName, style: AppText.headlineMedium(context)),
        const SizedBox(height: AppSpacing.xs),
        if (widget.vpnService.activeServer != null) Text(widget.vpnService.activeServer!.displayName, style: AppText.bodyMedium(context)),
        const SizedBox(height: AppSpacing.xl),
        _buildStats(context),
      ]))),
    );
  }

  Widget _buildHeader(BuildContext c) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('MaxSpeedVPN', style: AppText.headlineLarge(c)), Text('Быстрый и надёжный', style: AppText.bodySmall(c))]),
    IconButton(icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary), onPressed: () {}),
  ]);

  Widget _buildStats(BuildContext c) => Row(children: [
    Expanded(child: _statCard(c, '↑', '0 B/s', 'Загрузка')),
    const SizedBox(width: AppSpacing.sm),
    Expanded(child: _statCard(c, '↓', '0 B/s', 'Скачивание')),
    const SizedBox(width: AppSpacing.sm),
    Expanded(child: _statCard(c, '⏱', '0с', 'Время')),
  ]);

  Widget _statCard(BuildContext c, String icon, String value, String label) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(color: AppColors.bgSurface, borderRadius: BorderRadius.circular(AppRadii.md)),
    child: Column(children: [Text(icon, style: const TextStyle(fontSize: 20)), const SizedBox(height: AppSpacing.xs), Text(value, style: AppText.titleMedium(c)), Text(label, style: AppText.bodySmall(c))]),
  );

  void _onToggle() {
    if (_state == VpnConnectionState.connected) { widget.vpnService.disconnect(); }
    else { widget.vpnService.connect(VpnServer(id: 'demo', name: 'Demo Server', address: '1.2.3.4', port: 443, protocol: VpnProtocol.naive, username: 'user', password: '<REDACTED>)); }
  }
}
''')

w('lib/presentation/screens/servers_screen.dart', r'''import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../services/subscription_service.dart';
import '../widgets/server_list_item.dart';

class ServersScreen extends StatefulWidget {
  final SubscriptionService subscriptionService;
  const ServersScreen({super.key, required this.subscriptionService});
  @override State<ServersScreen> createState() => _ServersScreenState();
}

class _ServersScreenState extends State<ServersScreen> {
  String? _selectedId;
  @override Widget build(BuildContext context) {
    final servers = widget.subscriptionService.allServers;
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(backgroundColor: AppColors.bgPrimary, title: Text('Серверы', style: AppText.headlineMedium(context)), elevation: 0),
      body: servers.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.dns_outlined, size: 64, color: AppColors.textMuted),
              const SizedBox(height: AppSpacing.md),
              Text('Нет серверов', style: AppText.titleLarge(context)),
              const SizedBox(height: AppSpacing.xs),
              Text('Добавьте подписку в настройках', style: AppText.bodyMedium(context)),
            ]))
          : ListView.builder(padding: const EdgeInsets.all(AppSpacing.sm), itemCount: servers.length, itemBuilder: (c, i) => ServerListItem(server: servers[i], isSelected: _selectedId == servers[i].id, onTap: () => setState(() => _selectedId = servers[i].id))),
    );
  }
}
''')

w('lib/presentation/screens/settings_screen.dart', r'''import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  final SettingsService settingsService;
  const SettingsScreen({super.key, required this.settingsService});
  @override State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(backgroundColor: AppColors.bgPrimary, title: Text('Настройки', style: AppText.headlineMedium(context)), elevation: 0),
      body: ListView(padding: const EdgeInsets.all(AppSpacing.md), children: [
        _sh('Подключение'),
        _toggle(Icons.auto_awesome, 'Автоподключение', 'Подключаться при запуске', widget.settingsService.autoConnect, (v) => setState(() => widget.settingsService.setAutoConnect(v))),
        _toggle(Icons.shield_outlined, 'Kill Switch', 'Блокировать трафик при отключении', widget.settingsService.killSwitch, (v) => setState(() => widget.settingsService.setKillSwitch(v))),
        const SizedBox(height: AppSpacing.lg),
        _sh('Внешний вид'),
        _toggle(Icons.dark_mode_outlined, 'Тёмная тема', 'Всегда тёмная тема', widget.settingsService.themeMode == ThemeMode.dark, (v) => setState(() => widget.settingsService.setThemeMode(v ? ThemeMode.dark : ThemeMode.light))),
        const SizedBox(height: AppSpacing.lg),
        _sh('О приложении'),
        _info(Icons.info_outlined, 'Версия', '1.0.0'),
        _info(Icons.description_outlined, 'Лицензия', 'GPL-3.0'),
      ]),
    );
  }
  Widget _sh(String t) => Padding(padding: const EdgeInsets.only(left: 16, bottom: 8, top: 8), child: Text(t.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 1.2)));
  Widget _toggle(IconData i, String t, String s, bool v, ValueChanged<bool> cb) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.bgSurface, borderRadius: BorderRadius.circular(12)),
    child: Row(children: [Icon(i, color: AppColors.primary, size: 24), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: AppText.titleMedium(context)), Text(s, style: AppText.bodySmall(context))])), Switch(value: v, onChanged: cb, activeColor: AppColors.primary)]),
  );
  Widget _info(IconData i, String t, String s) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.bgSurface, borderRadius: BorderRadius.circular(12)),
    child: Row(children: [Icon(i, color: AppColors.textSecondary, size: 24), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: AppText.titleMedium(context)), Text(s, style: AppText.bodySmall(context))]))]),
  );
}
''')

w('lib/presentation/screens/logs_screen.dart', r'''import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../data/models/vpn_models.dart';
import '../../services/log_service.dart';

class LogsScreen extends StatelessWidget {
  final LogService logService;
  const LogsScreen({super.key, required this.logService});

  @override Widget build(BuildContext context) {
    final logs = logService.logs;
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(backgroundColor: AppColors.bgPrimary, title: Text('Логи', style: AppText.headlineMedium(context)), elevation: 0, actions: [IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.textSecondary), onPressed: () => logService.clear())]),
      body: logs.isEmpty ? Center(child: Text('Нет логов', style: AppText.bodyLarge(context))) : ListView.builder(padding: const EdgeInsets.all(AppSpacing.sm), itemCount: logs.length, itemBuilder: (c, i) => _item(c, logs[logs.length - 1 - i])),
    );
  }

  Widget _item(BuildContext c, VpnLogEntry log) {
    final lc = log.level == VpnLogLevel.error ? AppColors.error : log.level == VpnLogLevel.warning ? AppColors.warning : log.level == VpnLogLevel.info ? AppColors.primary : AppColors.textMuted;
    return Container(margin: const EdgeInsets.symmetric(vertical: 2), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.bgSurface, borderRadius: BorderRadius.circular(8)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 4, height: 40, decoration: BoxDecoration(color: lc, borderRadius: BorderRadius.circular(2))), const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(log.message, style: AppText.bodyMedium(c)), if (log.details != null) Text(log.details!, style: AppText.bodySmall(c))])),
      Text('${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}', style: AppText.bodySmall(c)),
    ]));
  }
}
''')

# ============================================================
# MAIN APP
# ============================================================
print("Creating main.dart...")

w('lib/main.dart', r'''import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_colors.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/servers_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/screens/logs_screen.dart';
import 'services/vpn_service.dart';
import 'services/subscription_service.dart';
import 'services/settings_service.dart';
import 'services/log_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.light));
  runApp(const MaxSpeedVpnApp());
}

class MaxSpeedVpnApp extends StatelessWidget {
  const MaxSpeedVpnApp({super.key});
  @override Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MaxSpeedVPN', debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: AppColors.bgPrimary, colorScheme: ColorScheme.dark(primary: AppColors.primary, secondary: AppColors.primaryDark, surface: AppColors.bgSurface, error: AppColors.error), useMaterial3: true),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final _vpnService = VpnService();
  final _subscriptionService = SubscriptionService();
  final _settingsService = SettingsService();
  final _logService = LogService();

  @override void initState() { super.initState(); _logService.info('App started'); }
  @override void dispose() { _vpnService.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final screens = [HomeScreen(vpnService: _vpnService), ServersScreen(subscriptionService: _subscriptionService), LogsScreen(logService: _logService), SettingsScreen(settingsService: _settingsService)];
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: AppColors.bgSecondary, border: Border(top: BorderSide(color: AppColors.border, width: 0.5))),
        child: SafeArea(child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _nav(0, Icons.home_rounded, 'Главная'), _nav(1, Icons.dns_rounded, 'Серверы'), _nav(2, Icons.article_outlined, 'Логи'), _nav(3, Icons.settings_rounded, 'Настройки'),
        ]))),
      ),
    );
  }

  Widget _nav(int i, IconData icon, String label) {
    final sel = _currentIndex == i;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = i),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: sel ? AppColors.primary.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: sel ? AppColors.primary : AppColors.textMuted, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: sel ? AppColors.primary : AppColors.textMuted)),
        ]),
      ),
    );
  }
}
''')

# ============================================================
# BARREL EXPORTS
# ============================================================
print("Creating barrel exports...")

w('lib/core/core.dart', r'''export 'theme/app_colors.dart';
export 'theme/app_text.dart';
export 'theme/app_radii.dart';
export 'theme/app_spacing.dart';
export 'theme/app_shadows.dart';
export 'theme/app_durations.dart';
export 'theme/app_gradients.dart';
export 'theme/app_curves.dart';
export 'constants/app_constants.dart';
export 'utils/formatters.dart';
export 'utils/validators.dart';
export 'utils/app_toast.dart';
export 'extensions/context_extensions.dart';
export 'extensions/date_extensions.dart';
''')

w('lib/data/data.dart', r'''export 'models/vpn_models.dart';
''')

w('lib/services/services.dart', r'''export 'vpn_service.dart';
export 'subscription_service.dart';
export 'settings_service.dart';
export 'log_service.dart';
''')

w('lib/vpn/vpn.dart', r'''export 'naive_parser.dart';
export 'vless_parser.dart';
export 'protocol_parsers.dart';
export 'singbox_config_generator.dart';
export 'vpn_config.dart';
''')

w('lib/presentation/presentation.dart', r'''export 'screens/home_screen.dart';
export 'screens/servers_screen.dart';
export 'screens/settings_screen.dart';
export 'screens/logs_screen.dart';
export 'widgets/power_button.dart';
export 'widgets/server_list_item.dart';
''')

# ============================================================
# COUNT LINES
# ============================================================
total = 0
for root, dirs, files in os.walk('lib'):
    for f in files:
        if f.endswith('.dart'):
            path = os.path.join(root, f)
            with open(path) as fh:
                lines = len(fh.readlines())
            total += lines
            print(f"  {lines:>6} lines  {path}")

print(f"\n{'='*50}")
print(f"Total: {total} lines in lib/")
print(f"Files: {sum(1 for _, _, fs in os.walk('lib') for f in fs if f.endswith('.dart'))}")
