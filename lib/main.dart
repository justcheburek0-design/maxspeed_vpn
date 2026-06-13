import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_themes.dart';
import 'core/deeplink/deep_link_handler.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'services/vpn_service_factory.dart';
import 'services/vpn_service_interface.dart';
import 'services/update_manager_export.dart';

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
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final VpnService _vpnService;
  late final PageController _pageController;
  late AnimationController _capsuleAnimController;
  late Animation<double> _capsuleAnimation;

  @override
  void initState() {
    super.initState();
    _vpnService = createVpnService();
    _pageController = PageController(initialPage: 0);
    _capsuleAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _capsuleAnimation = CurvedAnimation(
      parent: _capsuleAnimController,
      curve: Curves.easeInOutCubic,
    );
    _capsuleAnimController.forward(); // start at position 0 (left)

    if (!kIsWeb) {
      DeepLinkHandler.init();
      DeepLinkHandler.onLink.listen(_handleDeepLink);
      _checkInitialLink();
      UpdateManager.instance.initialize();
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
    _pageController.dispose();
    _capsuleAnimController.dispose();
    super.dispose();
  }

  void _switchTab(int index) {
    if (index == _currentIndex) return;
    // Haptic feedback
    HapticFeedback.lightImpact();
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
    // Animate capsule
    if (index == 1) {
      _capsuleAnimController.forward();
    } else {
      _capsuleAnimController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = GlassTheme.of(context);

    return Scaffold(
      backgroundColor: theme.bgPrimary,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Desktop layout: NavigationRail + content
          if (constraints.maxWidth >= 700) {
            return Row(
              children: [
                _buildSideNav(theme, constraints.maxWidth),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      HomeScreen(vpnService: _vpnService),
                      SettingsScreen(vpnService: _vpnService, onThemeChanged: widget.onThemeChanged),
                    ],
                  ),
                ),
              ],
            );
          }
          // Mobile layout: PageView + animated bottom nav
          return Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                    if (index == 1) {
                      _capsuleAnimController.forward();
                    } else {
                      _capsuleAnimController.reverse();
                    }
                  },
                  children: [
                    HomeScreen(vpnService: _vpnService),
                    SettingsScreen(vpnService: _vpnService, onThemeChanged: widget.onThemeChanged),
                  ],
                ),
              ),
              _buildBottomNav(theme),
            ],
          );
        },
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
          _sideNavItem(1, Icons.settings_rounded, 'Настройки', theme, isExtended),
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

  String get _platformLabel {
    if (Theme.of(context).platform == TargetPlatform.linux) return 'Linux';
    if (Theme.of(context).platform == TargetPlatform.macOS) return 'macOS';
    if (Theme.of(context).platform == TargetPlatform.windows) return 'Windows';
    if (Theme.of(context).platform == TargetPlatform.iOS) return 'iOS';
    return 'Android';
  }

  Widget _sideNavItem(int index, IconData icon, String label, AppTheme theme, bool extended) {
    final isSelected = _currentIndex == index;

    if (!extended) {
      return IconButton(
        onPressed: () => _switchTab(index),
        icon: Icon(
          icon,
          color: isSelected ? theme.primary : theme.onSurfaceVariant,
        ),
        style: IconButton.styleFrom(
          backgroundColor: isSelected ? theme.primary.withValues(alpha: 0.1) : Colors.transparent,
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
              color: isSelected ? theme.primary.withValues(alpha: 0.1) : Colors.transparent,
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
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: theme.surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: theme.outlineVariant.withValues(alpha: 0.5), width: 0.5),
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
          child: Stack(
            children: [
              // Animated capsule background
              AnimatedBuilder(
                animation: _capsuleAnimation,
                builder: (context, child) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final capsuleWidth = constraints.maxWidth / 2;
                      final offset = _capsuleAnimation.value * capsuleWidth;
                      return Positioned(
                        left: offset,
                        top: 6,
                        bottom: 6,
                        width: capsuleWidth,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: theme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: theme.primary.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              // Nav items on top
              Row(
                children: [
                  _navItem(0, Icons.home_rounded, 'Главная', theme),
                  _navItem(1, Icons.settings_rounded, 'Настройки', theme),
                ],
              ),
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
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
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
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
