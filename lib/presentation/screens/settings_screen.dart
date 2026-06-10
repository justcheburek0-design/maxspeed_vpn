import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_themes.dart';
import '../../data/models/vpn_models.dart';
import '../../services/vpn_service.dart';
import '../widgets/glass_container.dart';

class SettingsScreen extends StatefulWidget {
  final VpnService vpnService;
  const SettingsScreen({super.key, required this.vpnService});
  @override State<SettingsScreen> createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  String _selectedTheme = 'forest';
  List<InstalledApp> _apps = [];
  Set<String> _excludedApps = {};
  bool _loadingApps = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _loadApps();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _selectedTheme = prefs.getString('theme') ?? 'forest');
  }

  Future<void> _loadApps() async {
    setState(() => _loadingApps = true);
    try {
      final result = await Process.run('pm', ['list', 'packages', '-3', '--user', '0']);
      final lines = result.stdout.toString().split('\\n');
      final apps = <InstalledApp>[];
      for (final line in lines) {
        final pkg = line.replaceFirst('package:', '').trim();
        if (pkg.isNotEmpty) apps.add(InstalledApp(packageName: pkg, appName: pkg.split('.').last));
      }
      apps.sort((a, b) => a.appName.compareTo(b.appName));
      setState(() => _apps = apps);
    } catch (e) {
      debugPrint('Failed to load apps: $e');
    }
    setState(() => _loadingApps = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = GlassTheme.of(context);
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: theme.bgPrimary,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Настройки', style: TextStyle(color: theme.textPrimary)),
          iconTheme: IconThemeData(color: theme.textPrimary),
          bottom: TabBar(
            labelColor: theme.primary,
            unselectedLabelColor: theme.textMuted,
            indicatorColor: theme.primary,
            tabs: const [
              Tab(text: 'Общие'),
              Tab(text: 'Прокси'),
              Tab(text: 'Логи'),
              Tab(text: 'Тема'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildGeneralTab(theme),
            _buildProxyTab(theme),
            _buildLogsTab(theme),
            _buildThemeTab(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralTab(AppTheme theme) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionTitle(theme, 'Подписки'),
        GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.link, color: theme.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text('URL подписки', style: TextStyle(color: theme.textSecondary))),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline, color: theme.primary),
                    onPressed: _showAddSubscriptionDialog,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Вставьте ссылку или используйте mxspd://',
                style: TextStyle(fontSize: 12, color: theme.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _sectionTitle(theme, 'Подключение'),
        GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _switchRow(theme, 'Автоподключение', false, (v) {}),
              _switchRow(theme, 'Reconnect при обрыве', true, (v) {}),
              _switchRow(theme, 'Notifications', true, (v) {}),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _sectionTitle(theme, 'О приложении'),
        GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _infoRow(theme, 'Версия', '3.2.1'),
              _infoRow(theme, 'Протокол', 'VLESS / Trojan / SS'),
              _infoRow(theme, 'Engine', 'sing-box v1.13'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProxyTab(AppTheme theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.apps_outlined, color: theme.primary, size: 20),
                    const SizedBox(width: 12),
                    Text('Прокси по приложениям', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.textPrimary)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Выберите приложения, которые НЕ будут проксироваться',
                  style: TextStyle(fontSize: 12, color: theme.textMuted),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              style: TextStyle(color: theme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Поиск приложений...',
                hintStyle: TextStyle(color: theme.textMuted),
                border: InputBorder.none,
                icon: Icon(Icons.search, color: theme.textMuted),
              ),
              onChanged: (v) {},
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _loadingApps
            ? Center(child: CircularProgressIndicator(color: theme.primary))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _apps.length,
                itemBuilder: (c, i) {
                  final app = _apps[i];
                  final excluded = _excludedApps.contains(app.packageName);
                  return GlassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: CheckboxListTile(
                      value: excluded,
                      onChanged: (v) {
                        setState(() {
                          if (v == true) _excludedApps.add(app.packageName);
                          else _excludedApps.remove(app.packageName);
                        });
                      },
                      title: Text(app.appName, style: TextStyle(color: theme.textPrimary)),
                      subtitle: Text(app.packageName, style: TextStyle(fontSize: 11, color: theme.textMuted)),
                      activeColor: theme.primary,
                      checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }

  Widget _buildLogsTab(AppTheme theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Логи (${widget.vpnService.logs.length})',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.textPrimary),
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: theme.error, size: 20),
                onPressed: () { widget.vpnService.clearLogs(); setState(() {}); },
                tooltip: 'Очистить',
              ),
              IconButton(
                icon: Icon(Icons.share_outlined, color: theme.primary, size: 20),
                onPressed: () {},
                tooltip: 'Экспорт',
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<VpnLogEntry>(
            stream: widget.vpnService.logStream,
            builder: (c, snap) {
              final logs = widget.vpnService.logs.reversed.toList();
              if (logs.isEmpty) {
                return Center(child: Text('Логи пусты', style: TextStyle(color: theme.textMuted)));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: logs.length,
                itemBuilder: (c, i) {
                  final log = logs[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassContainer(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _logIcon(theme, log.level),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(log.message, style: TextStyle(fontSize: 13, color: theme.textPrimary)),
                                const SizedBox(height: 2),
                                Text(
                                  _formatTime(log.timestamp),
                                  style: TextStyle(fontSize: 11, color: theme.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildThemeTab(AppTheme theme) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionTitle(theme, 'Тёмные темы'),
        ...ThemeRegistry.dark.map((t) => _themeOption(t, theme)),
        const SizedBox(height: 16),
        _sectionTitle(theme, 'Светлые темы'),
        ...ThemeRegistry.light.map((t) => _themeOption(t, theme)),
      ],
    );
  }

  Widget _themeOption(AppTheme t, AppTheme currentTheme) {
    final isSelected = _selectedTheme == t.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        borderColor: isSelected ? t.primary.withValues(alpha: 0.5) : null,
        tint: isSelected ? t.primary.withValues(alpha: 0.05) : null,
        child: InkWell(
          onTap: () => _selectTheme(t.id),
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [t.primary, t.accent]),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(t.name, style: TextStyle(color: currentTheme.textPrimary))),
              if (isSelected) Icon(Icons.check_circle, color: currentTheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(AppTheme theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textSecondary, letterSpacing: 0.5)),
    );
  }

  Widget _switchRow(AppTheme theme, String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: theme.textPrimary)),
        Switch(value: value, onChanged: onChanged, activeColor: theme.primary),
      ],
    );
  }

  Widget _infoRow(AppTheme theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: theme.textSecondary)),
          Text(value, style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _logIcon(AppTheme theme, VpnLogLevel level) {
    switch (level) {
      case VpnLogLevel.error: return Icon(Icons.error_outline, color: theme.error, size: 16);
      case VpnLogLevel.warning: return Icon(Icons.warning_amber_outlined, color: theme.warning, size: 16);
      case VpnLogLevel.debug: return Icon(Icons.bug_report_outlined, color: theme.textMuted, size: 16);
      default: return Icon(Icons.info_outline, color: theme.primary, size: 16);
    }
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  void _selectTheme(String id) async {
    setState(() => _selectedTheme = id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', id);
    // TODO: Notify parent to rebuild with new theme
  }

  void _showAddSubscriptionDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: GlassTheme.of(context).bgSurface,
        title: Text('Добавить подписку', style: TextStyle(color: GlassTheme.of(context).textPrimary)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: GlassTheme.of(context).textPrimary),
          decoration: InputDecoration(
            hintText: 'https://... или mxspd://...',
            hintStyle: TextStyle(color: GlassTheme.of(context).textMuted),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(c);
              // TODO: Import subscription
            },
            child: Text('Добавить'),
          ),
        ],
      ),
    );
  }
}

class InstalledApp {
  final String packageName;
  final String appName;
  const InstalledApp({required this.packageName, required this.appName});
}
