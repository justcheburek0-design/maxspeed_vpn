import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_themes.dart';
import 'core/deeplink/deep_link_handler.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/servers_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'services/update_checker.dart';
import 'services/vpn_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.light),
  );
  runApp(const MaxSpeedVpnApp());
}

class MaxSpeedVpnApp extends StatefulWidget {
  const MaxSpeedVpnApp({super.key});
  @override State<MaxSpeedVpnApp> createState() => _MaxSpeedVpnAppState();
}

class _MaxSpeedVpnAppState extends State<MaxSpeedVpnApp> {
  String _themeId = 'incy';

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _themeId = prefs.getString('theme') ?? 'incy');
  }

  void _onThemeChanged(String id) async {
    setState(() => _themeId = id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', id);
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = ThemeRegistry.get(_themeId);
    return GlassTheme(
      theme: appTheme,
      child: MaterialApp(
        title: 'MaxSpeedVPN',
        debugShowCheckedModeBanner: false,
        theme: appTheme.themeData,
        home: MainScreen(
          themeId: _themeId,
          onThemeChanged: _onThemeChanged,
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final String themeId;
  final ValueChanged<String> onThemeChanged;
  const MainScreen({super.key, required this.themeId, required this.onThemeChanged});
  @override State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late final VpnService _vpnService;

  @override
  void initState() {
    super.initState();
    _vpnService = VpnService();
    DeepLinkHandler.init();
    DeepLinkHandler.onLink.listen(_handleDeepLink);
    _checkInitialLink();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final update = await UpdateChecker.checkForUpdate();
    if (update != null && mounted) {
      showUpdateDialog(context, update);
    }
  }

  Future<void> _checkInitialLink() async {
    final link = await DeepLinkHandler.getInitialLink();
    if (link != null) _handleDeepLink(link);
  }

  void _handleDeepLink(String link) {
    if (link.startsWith('mxspd://')) {
      final url = link.substring(8);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Импорт подписки: $url')),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _vpnService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = GlassTheme.of(context);
    final screens = [
      HomeScreen(vpnService: _vpnService),
      ServersScreen(vpnService: _vpnService),
      SettingsScreen(vpnService: _vpnService, onThemeChanged: widget.onThemeChanged),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        backgroundColor: theme.bgSecondary,
        surfaceTintColor: Colors.transparent,
        indicatorColor: theme.primary.withValues(alpha: 0.12),
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: theme.onSurfaceVariant),
            selectedIcon: Icon(Icons.home_rounded, color: theme.primary),
            label: 'Главная',
          ),
          NavigationDestination(
            icon: Icon(Icons.dns_outlined, color: theme.onSurfaceVariant),
            selectedIcon: Icon(Icons.dns_rounded, color: theme.primary),
            label: 'Серверы',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, color: theme.onSurfaceVariant),
            selectedIcon: Icon(Icons.settings_rounded, color: theme.primary),
            label: 'Настройки',
          ),
        ],
      ),
    );
  }
}
