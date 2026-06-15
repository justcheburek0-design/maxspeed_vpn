import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_themes.dart';
import 'core/deeplink/deep_link_handler.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'services/vpn_service_factory.dart';
import 'services/vpn_service_interface.dart';
import 'services/update_manager_export.dart';
import '../core/utils/notifications.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MaxSpeedVpnApp());
}

class MaxSpeedVpnApp extends StatefulWidget {
  const MaxSpeedVpnApp({super.key});
  @override
  State<MaxSpeedVpnApp> createState() => _MaxSpeedVpnAppState();
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
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: appTheme.themeData,
        home: MainScreen(themeId: _themeId, onThemeChanged: _onThemeChanged),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final String themeId;
  final ValueChanged<String> onThemeChanged;
  const MainScreen({
    super.key,
    required this.themeId,
    required this.onThemeChanged,
  });
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late final VpnService _vpnService;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _vpnService = createVpnService();
    if (!kIsWeb) {
      DeepLinkHandler.init();
      DeepLinkHandler.onLink.listen(_handleDeepLink);
      _checkInitialLink();
      UpdateManager.instance.initialize();
    }
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted)
        setState(() => _appVersion = '${info.version}+${info.buildNumber}');
    } catch (_) {}
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
          showAppNotification(context, 'Импорт подписки: $url');
        }
      });
    }
  }

  @override
  void dispose() {
    _vpnService.dispose();
    super.dispose();
  }

  void _switchTab(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.lightImpact();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = GlassTheme.of(context);
    final screens = <Widget>[
      HomeScreen(vpnService: _vpnService),
      SettingsScreen(
        vpnService: _vpnService,
        onThemeChanged: widget.onThemeChanged,
      ),
    ];

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex != 0) {
          _switchTab(0);
        }
      },
      child: Scaffold(
        backgroundColor: theme.bgPrimary,
        body: LayoutBuilder(
          builder: (context, constraints) {
            // Desktop layout: NavigationRail + content
            if (constraints.maxWidth >= 700) {
              return Row(
                children: [
                  _buildSideNav(theme, constraints.maxWidth),
                  Expanded(
                    child: IndexedStack(
                      index: _currentIndex,
                      children: screens,
                    ),
                  ),
                ],
              );
            }
            // Mobile layout: content + BottomNavigationBar
            return Column(
              children: [
                Expanded(
                  child: IndexedStack(index: _currentIndex, children: screens),
                ),
                _buildBottomNav(theme),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSideNav(AppTheme theme, double width) {
    final isExtended = width >= 1000;

    return Container(
      width: isExtended ? 220 : 72,
      decoration: BoxDecoration(
        color: theme.surface.withValues(alpha: 0.7),
        border: Border(
          right: BorderSide(color: theme.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Logo
          if (isExtended)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, color: theme.primary, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    AppConstants.appName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.onSurface,
                    ),
                  ),
                ],
              ),
            )
          else
            Icon(Icons.shield_outlined, color: theme.primary, size: 28),
          const SizedBox(height: 32),
          // Nav items
          _sideNavItem(0, Icons.home_rounded, 'Главная', theme, isExtended),
          const SizedBox(height: 4),
          _sideNavItem(
            1,
            Icons.settings_rounded,
            'Настройки',
            theme,
            isExtended,
          ),
          const Spacer(),
          // Platform badge
          if (isExtended)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _platformLabel,
                style: TextStyle(fontSize: 10, color: theme.outline),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String get _platformLabel => _appVersion.isNotEmpty ? _appVersion : '—';

  Widget _sideNavItem(
    int index,
    IconData icon,
    String label,
    AppTheme theme,
    bool extended,
  ) {
    final isSelected = _currentIndex == index;

    if (!extended) {
      return IconButton(
        onPressed: () => _switchTab(index),
        icon: Icon(
          icon,
          color: isSelected ? theme.primary : theme.onSurfaceVariant,
        ),
        style: IconButton.styleFrom(
          backgroundColor: isSelected
              ? theme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          minimumSize: const Size(48, 48),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _switchTab(index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: theme.primary.withValues(alpha: 0.2))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? theme.primary : theme.onSurfaceVariant,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? theme.primary : theme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(AppTheme theme) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: bottomPad + 6,
        top: 6,
      ),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: theme.surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(34),
          border: Border.all(
            color: theme.outlineVariant.withValues(alpha: 0.5),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 30,
              spreadRadius: 0,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: theme.primary.withValues(alpha: 0.05),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: Row(
            children: [
              _navItem(0, Icons.home_rounded, 'Главная', theme),
              _navItem(1, Icons.settings_rounded, 'Настройки', theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label, AppTheme theme) {
    final isSelected = _currentIndex == index;
    final activeColor = theme.primary;
    final inactiveColor = theme.onSurfaceVariant;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _switchTab(index),
          splashColor: theme.primary.withValues(alpha: 0.1),
          highlightColor: theme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(28),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.all(6),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: const BorderRadius.all(Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected ? activeColor : inactiveColor,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: isSelected ? activeColor : inactiveColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
