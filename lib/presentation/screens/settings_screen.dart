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
  String _selectedTheme = 'incy';
  List<InstalledApp> _apps = [];
  Set<String> _excludedApps = {};
  bool _loadingApps = false;
  String _appSearchQuery = '';
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
    setState(() => _selectedTheme = prefs.getString('theme') ?? 'incy');
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

  List<InstalledApp> get _filteredApps {
    if (_appSearchQuery.isEmpty) return _apps;
    return _apps.where((a) =>
      a.appName.toLowerCase().contains(_appSearchQuery.toLowerCase()) ||
      a.packageName.toLowerCase().contains(_appSearchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = GlassTheme.of(context);
    return Scaffold(
      backgroundColor: theme.bgPrimary,
      appBar: AppBar(
        backgroundColor: theme.bgPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Настройки',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: theme.onSurface,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.primary,
          unselectedLabelColor: theme.onSurfaceVariant,
      indicatorColor: theme.primary,
      dividerColor: theme.outlineVariant,
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontSize: 13),
      tabAlignment: TabAlignment.fill,
      tabs: const [
        Tab(text: 'Общие'),
        Tab(text: 'Прокси'),
        Tab(text: 'Логи'),
        Tab(text: 'Тема'),
      ],
    ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGeneralTab(theme),
          _buildProxyTab(theme),
          _buildLogsTab(theme),
          _buildThemeTab(theme),
        ],
      ),
    );
  }

  // ─── General Tab ───

  Widget _buildGeneralTab(AppTheme theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle(theme, 'ПОДПИСКИ'),
        Card(
          elevation: 0,
          color: theme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.outlineVariant),
          ),
          child: Column(children: [
            ListTile(
              leading: Icon(Icons.link, color: theme.primary),
              title: const Text('URL подписки'),
              subtitle: Text(
                'Вставьте ссылку или используйте mxspd://',
                style: TextStyle(fontSize: 12, color: theme.onSurfaceVariant),
              ),
              trailing: IconButton(
                icon: Icon(Icons.add_circle_outline, color: theme.primary),
                onPressed: _showAddSubscriptionDialog,
              ),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        _sectionTitle(theme, 'ПОДКЛЮЧЕНИЕ'),
        Card(
          elevation: 0,
          color: theme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.outlineVariant),
          ),
          child: Column(children: [
            _switchTile(theme, 'Автоподключение', false, (v) {}),
            Divider(color: theme.outlineVariant, height: 1, indent: 16, endIndent: 16),
            _switchTile(theme, 'Reconnect при обрыве', true, (v) {}),
            Divider(color: theme.outlineVariant, height: 1, indent: 16, endIndent: 16),
            _switchTile(theme, 'Уведомления', true, (v) {}),
          ]),
        ),
        const SizedBox(height: 20),
        _sectionTitle(theme, 'О ПРИЛОЖЕНИИ'),
        Card(
          elevation: 0,
          color: theme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.outlineVariant),
          ),
          child: Column(children: [
            _infoTile(theme, 'Версия', '1.0.0'),
            Divider(color: theme.outlineVariant, height: 1, indent: 16, endIndent: 16),
            _infoTile(theme, 'Протокол', 'VLESS / REALITY'),
            Divider(color: theme.outlineVariant, height: 1, indent: 16, endIndent: 16),
            _infoTile(theme, 'Engine', 'sing-box v1.13'),
          ]),
        ),
      ],
    );
  }

  // ─── Proxy Tab ───

  Widget _buildProxyTab(AppTheme theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 0,
            color: theme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.outlineVariant),
            ),
            child: ListTile(
              leading: Icon(Icons.apps_outlined, color: theme.primary),
              title: const Text('Прокси по приложениям'),
              subtitle: Text(
                'Исключить из прокси',
                style: TextStyle(fontSize: 12, color: theme.onSurfaceVariant),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SearchBar(
            hintText: 'Поиск приложений...',
            leading: Icon(Icons.search, color: theme.onSurfaceVariant),
            backgroundColor: WidgetStatePropertyAll(theme.surface),
            surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
            elevation: WidgetStatePropertyAll(0),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.outlineVariant),
              ),
            ),
            hintStyle: WidgetStatePropertyAll(
              TextStyle(color: theme.onSurfaceVariant),
            ),
            onChanged: (v) => setState(() => _appSearchQuery = v),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loadingApps
              ? Center(child: CircularProgressIndicator(color: theme.primary))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredApps.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (c, i) {
                    final app = _filteredApps[i];
                    final excluded = _excludedApps.contains(app.packageName);
                    return Card(
                      elevation: 0,
                      color: theme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: theme.outlineVariant),
                      ),
                      child: CheckboxListTile(
                        value: excluded,
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _excludedApps.add(app.packageName);
                            } else {
                              _excludedApps.remove(app.packageName);
                            }
                          });
                        },
                        title: Text(
                          app.appName,
                          style: TextStyle(color: theme.onSurface, fontSize: 14),
                        ),
                        subtitle: Text(
                          app.packageName,
                          style: TextStyle(fontSize: 11, color: theme.onSurfaceVariant),
                        ),
                        activeColor: theme.primary,
                        checkboxShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ─── Logs Tab ───

  Widget _buildLogsTab(AppTheme theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Логи',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${widget.vpnService.logs.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.onPrimaryContainer,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.delete_outline, color: theme.error, size: 20),
                onPressed: () {
                  widget.vpnService.clearLogs();
                  setState(() {});
                },
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
                      Icon(Icons.description_outlined, size: 48, color: theme.outline),
                      const SizedBox(height: 12),
                      Text('Логи пусты', style: TextStyle(color: theme.onSurfaceVariant)),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: logs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (c, i) {
                  final log = logs[i];
                  return Card(
                    elevation: 0,
                    color: theme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.outlineVariant),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: _logIcon(theme, log.level),
                      title: Text(
                        log.message,
                        style: TextStyle(fontSize: 13, color: theme.onSurface),
                      ),
                      subtitle: Text(
                        _formatTime(log.timestamp),
                        style: TextStyle(fontSize: 10, color: theme.onSurfaceVariant),
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

  // ─── Theme Tab ───

  Widget _buildThemeTab(AppTheme theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle(theme, 'ТЁМНЫЕ ТЕМЫ'),
        ...ThemeRegistry.dark.map((t) => _themeOption(t, theme)),
        const SizedBox(height: 16),
        _sectionTitle(theme, 'СВЕТЛЫЕ ТЕМЫ'),
        ...ThemeRegistry.light.map((t) => _themeOption(t, theme)),
      ],
    );
  }

  Widget _themeOption(AppTheme t, AppTheme currentTheme) {
    final isSelected = _selectedTheme == t.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Card(
        elevation: 0,
        color: isSelected ? t.primary.withValues(alpha: 0.08) : currentTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? t.primary.withValues(alpha: 0.5) : currentTheme.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: ListTile(
          onTap: () => _selectTheme(t.id),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [t.primary, t.secondary]),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          title: Text(
            t.name,
            style: TextStyle(color: currentTheme.onSurface, fontWeight: FontWeight.w500),
          ),
          trailing: isSelected
              ? Icon(Icons.check_circle, color: t.primary, size: 20)
              : Icon(Icons.circle_outlined, color: currentTheme.outline, size: 20),
        ),
      ),
    );
  }

  // ─── Helpers ───

  Widget _sectionTitle(AppTheme theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: theme.onSurfaceVariant,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _switchTile(AppTheme theme, String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(label, style: TextStyle(color: theme.onSurface, fontSize: 14)),
      activeColor: theme.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _infoTile(AppTheme theme, String label, String value) {
    return ListTile(
      title: Text(label, style: TextStyle(color: theme.onSurfaceVariant, fontSize: 14)),
      trailing: Text(
        value,
        style: TextStyle(color: theme.onSurface, fontWeight: FontWeight.w500, fontSize: 14),
      ),
    );
  }

  Widget _logIcon(AppTheme theme, VpnLogLevel level) {
    switch (level) {
      case VpnLogLevel.error:
        return Icon(Icons.error_outline, color: theme.error, size: 16);
      case VpnLogLevel.warning:
        return Icon(Icons.warning_amber_outlined, color: theme.warning, size: 16);
      case VpnLogLevel.debug:
        return Icon(Icons.bug_report_outlined, color: theme.outline, size: 16);
      default:
        return Icon(Icons.info_outline, color: theme.primary, size: 16);
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
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surface,
        surfaceTintColor: Colors.transparent,
        title: Text('Добавить подписку', style: TextStyle(color: theme.onSurface)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: theme.onSurface),
          decoration: InputDecoration(
            hintText: 'Вставьте ссылку подписки...',
            hintStyle: TextStyle(color: theme.onSurfaceVariant),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.primary),
            ),
          ),
          maxLines: 3,
          minLines: 1,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Отмена', style: TextStyle(color: theme.onSurfaceVariant)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(
              backgroundColor: theme.primary,
              foregroundColor: theme.onPrimary,
            ),
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }
}
