import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_themes.dart';
import '../../data/models/vpn_models.dart';
import '../../services/vpn_service.dart';

class SettingsScreen extends StatefulWidget {
  final VpnService vpnService;
  final ValueChanged<String>? onThemeChanged;
  const SettingsScreen({super.key, required this.vpnService, this.onThemeChanged});
  @override State<SettingsScreen> createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> with TickerProviderStateMixin {
  String _selectedTheme = 'forest';
  List<InstalledApp> _apps = [];
  Set<String> _excludedApps = {};
  bool _loadingApps = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPrefs();
    _loadApps();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _selectedTheme = prefs.getString('theme') ?? 'forest');
  }

  Future<void> _loadApps() async {
    setState(() => _loadingApps = true);
    try {
      const channel = MethodChannel('maxspeed.vpn');
      final List<dynamic>? result = await channel.invokeMethod('getInstalledApps');
      final apps = <InstalledApp>[];
      if (result != null) {
        for (final item in result) {
          final map = item as Map;
          final pkg = map['package'] as String? ?? '';
          final name = map['name'] as String? ?? pkg.split('.').last;
          if (pkg.isNotEmpty) apps.add(InstalledApp(packageName: pkg, appName: name));
        }
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
    return Scaffold(
      backgroundColor: theme.bgPrimary,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.8),
            radius: 1.0,
            colors: [
              theme.primary.withValues(alpha: 0.04),
              theme.bgPrimary,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    Text('Настройки', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textPrimary)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: theme.bgCard,
                    border: Border.all(color: theme.border),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: theme.primary,
                    unselectedLabelColor: theme.textMuted,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: theme.primary.withValues(alpha: 0.12),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    unselectedLabelStyle: const TextStyle(fontSize: 12),
                    tabs: const [
                      Tab(text: 'Общие'),
                      Tab(text: 'Прокси'),
                      Tab(text: 'Логи'),
                      Tab(text: 'Тема'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildGeneralTab(theme),
                    _buildProxyTab(theme),
                    _buildLogsTab(theme),
                    _buildThemeTab(theme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralTab(AppTheme theme) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionTitle(theme, 'Подписки'),
        _card(theme, [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.link, color: theme.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('URL подписки', style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w500))),
              IconButton(
                icon: Icon(Icons.add_circle_outline, color: theme.primary),
                onPressed: _showAddSubscriptionDialog,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Text('Вставьте ссылку или используйте mxspd://', style: TextStyle(fontSize: 12, color: theme.textMuted)),
          ),
        ]),
        const SizedBox(height: 20),
        _sectionTitle(theme, 'Подключение'),
        _card(theme, [
          _switchRow(theme, 'Автоподключение', false, (v) {}),
          Divider(color: theme.border, height: 1),
          _switchRow(theme, 'Reconnect при обрыве', true, (v) {}),
          Divider(color: theme.border, height: 1),
          _switchRow(theme, 'Уведомления', true, (v) {}),
        ]),
        const SizedBox(height: 20),
        _sectionTitle(theme, 'О приложении'),
        _card(theme, [
          _infoRow(theme, 'Версия', '1.0.0'),
          Divider(color: theme.border, height: 1),
          _infoRow(theme, 'Протокол', 'VLESS / REALITY'),
          Divider(color: theme.border, height: 1),
          _infoRow(theme, 'Engine', 'sing-box v1.13'),
        ]),
      ],
    );
  }

  Widget _buildProxyTab(AppTheme theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: _card(theme, [
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: theme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.apps_outlined, color: theme.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Прокси по приложениям', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.textPrimary)),
                      Text('Исключить из прокси', style: TextStyle(fontSize: 11, color: theme.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: theme.bgCard,
              border: Border.all(color: theme.border),
            ),
            child: TextField(
              style: TextStyle(color: theme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Поиск приложений...',
                hintStyle: TextStyle(color: theme.textMuted, fontSize: 13),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                prefixIcon: Icon(Icons.search, color: theme.textMuted, size: 18),
              ),
              onChanged: (v) {},
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _loadingApps
              ? Center(child: CircularProgressIndicator(color: theme.primary))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _apps.length,
                  itemBuilder: (c, i) {
                    final app = _apps[i];
                    final excluded = _excludedApps.contains(app.packageName);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: theme.bgCard,
                          border: Border.all(color: theme.border),
                        ),
                        child: CheckboxListTile(
                          value: excluded,
                          onChanged: (v) {
                            setState(() {
                              if (v == true) _excludedApps.add(app.packageName);
                              else _excludedApps.remove(app.packageName);
                            });
                          },
                          title: Text(app.appName, style: TextStyle(color: theme.textPrimary, fontSize: 14)),
                          subtitle: Text(app.packageName, style: TextStyle(fontSize: 11, color: theme.textMuted)),
                          activeColor: theme.primary,
                          checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
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
              Text('Логи', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.textPrimary)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${widget.vpnService.logs.length}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.primary)),
              ),
              const Spacer(),
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
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.description_outlined, size: 48, color: theme.textMuted),
                      const SizedBox(height: 12),
                      Text('Логи пусты', style: TextStyle(color: theme.textMuted)),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: logs.length,
                itemBuilder: (c, i) {
                  final log = logs[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: theme.bgCard,
                        border: Border.all(color: theme.border),
                      ),
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
                                Text(_formatTime(log.timestamp), style: TextStyle(fontSize: 10, color: theme.textMuted)),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectTheme(t.id),
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isSelected ? t.primary.withValues(alpha: 0.1) : currentTheme.bgCard,
              border: Border.all(
                color: isSelected ? t.primary.withValues(alpha: 0.5) : currentTheme.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [t.primary, t.accent]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(t.name, style: TextStyle(color: currentTheme.textPrimary, fontWeight: FontWeight.w500)),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: t.primary, size: 20)
                else
                  Icon(Icons.circle_outlined, color: currentTheme.textMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(AppTheme theme, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: theme.bgCard,
        border: Border.all(color: theme.border),
      ),
      child: Column(children: children),
    );
  }

  Widget _sectionTitle(AppTheme theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.textSecondary, letterSpacing: 0.3)),
    );
  }

  Widget _switchRow(AppTheme theme, String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: theme.textPrimary, fontSize: 14)),
        Switch(value: value, onChanged: onChanged, activeColor: theme.primary),
      ],
    );
  }

  Widget _infoRow(AppTheme theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: theme.textSecondary, fontSize: 14)),
          Text(value, style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w500, fontSize: 14)),
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
    widget.onThemeChanged?.call(id);
  }

  void _showAddSubscriptionDialog() {
    final controller = TextEditingController();
    final theme = GlassTheme.of(context);
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: theme.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Добавить подписку', style: TextStyle(color: theme.textPrimary)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: theme.textPrimary),
          decoration: InputDecoration(
            hintText: 'https://... или mxspd://...',
            hintStyle: TextStyle(color: theme.textMuted),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text('Отмена', style: TextStyle(color: theme.textMuted))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(c);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Добавить'),
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
