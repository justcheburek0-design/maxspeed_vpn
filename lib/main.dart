import 'package:flutter/material.dart';
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
