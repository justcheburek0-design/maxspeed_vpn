import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_themes.dart';
import 'core/deeplink/deep_link_handler.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/servers_screen.dart';
import 'presentation/screens/settings_screen.dart';
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
  String _themeId = 'forest';

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _themeId = prefs.getString('theme') ?? 'forest');
  }

  void _onThemeChanged(String id) async {
    setState(() => _themeId = id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeRegistry.get(_themeId);
    return GlassTheme(
      theme: theme,
      child: MaterialApp(
        title: 'MaxSpeedVPN',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: theme.bgPrimary,
          colorScheme: ColorScheme.dark(
            primary: theme.primary,
            secondary: theme.accent,
            surface: theme.bgSurface,
            error: theme.error,
          ),
          useMaterial3: true,
        ),
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
  }

  Future<void> _checkInitialLink() async {
    final link = await DeepLinkHandler.getInitialLink();
    if (link != null) _handleDeepLink(link);
  }

  void _handleDeepLink(String link) {
    if (link.startsWith('mxspd://')) {
      final url = link.substring(8);
      // TODO: Import subscription from URL
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Импорт подписки: $url')),
      );
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
      SettingsScreen(vpnService: _vpnService),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.bgSecondary,
          border: Border(top: BorderSide(color: theme.border, width: 0.5)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _nav(0, Icons.home_rounded, 'Главная', theme),
                _nav(1, Icons.dns_rounded, 'Серверы', theme),
                _nav(2, Icons.settings_rounded, 'Настройки', theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _nav(int i, IconData icon, String label, AppTheme theme) {
    final sel = _currentIndex == i;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = i),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? theme.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: sel ? theme.primary : theme.textMuted, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: sel ? theme.primary : theme.textMuted)),
          ],
        ),
      ),
    );
  }
}
