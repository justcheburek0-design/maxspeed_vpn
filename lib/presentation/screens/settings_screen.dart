import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_themes.dart';
import '../../data/models/vpn_models.dart';
import '../../services/vpn_service_interface.dart';
import '../../services/update_manager_export.dart';
import '../../vpn/subscription_parser.dart';

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
      final result = await widget.vpnService.getInstalledApps();
      final apps = <InstalledApp>[];
      for (final item in result) {
        final map = item as Map;
        final pkg = map['packageName'] as String? ?? '';
        final name = map['appName'] as String? ?? pkg.split('.').last;
        if (pkg.isNotEmpty) apps.add(InstalledApp(packageName: pkg, appName: name));
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
            _buildVersionTile(theme),
            Divider(color: theme.outlineVariant, height: 1, indent: 16, endIndent: 16),
            _infoTile(theme, 'Протокол', SettingsConstants.protocolDisplay),
            Divider(color: theme.outlineVariant, height: 1, indent: 16, endIndent: 16),
            _infoTile(theme, 'Engine', SettingsConstants.engineDisplay),
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

  Widget _buildVersionTile(AppTheme theme) {
    return FutureBuilder<String>(
      future: PackageInfo.fromPlatform().then((p) => p.version),
      builder: (ctx, snap) {
        final version = snap.data ?? '—';
        return StreamBuilder<UpdateDownloadState>(
          stream: UpdateManager.instance.progressStream,
          initialData: UpdateManager.instance.state,
          builder: (context, updateSnap) {
            final state = updateSnap.data ?? UpdateManager.instance.state;
            final hasUpdate = UpdateManager.instance.availableUpdate != null;
            final isReady = UpdateManager.instance.isUpdateReady;
            final isDownloading = state.status == 'downloading' || state.status == 'paused';

            String trailing = version;
            Widget? trailingWidget;
            VoidCallback? onTap;

            if (isDownloading) {
              final pct = state.progress > 0 ? (state.progress * 100).toStringAsFixed(0) : null;
              trailingWidget = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                      value: state.progress > 0 ? state.progress : null,
                      strokeWidth: 2,
                      color: theme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(pct != null ? '$pct%' : 'Скачивание...',
                      style: TextStyle(color: theme.primary, fontSize: 13)),
                ],
              );
              onTap = () {
                // Show download dialog
                UpdateManager.instance.downloadAndInstall(context);
              };
            } else if (isReady) {
              trailingWidget = Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.system_update, size: 14, color: theme.primary),
                    const SizedBox(width: 4),
                    Text('Установить', style: TextStyle(color: theme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              );
              onTap = () async {
                final apk = await UpdateManager.instance.getDownloadedApk(
                    UpdateManager.instance.availableUpdate!.version);
                if (apk != null && context.mounted) {
                  UpdateManager.instance.downloadAndInstall(context);
                }
              };
            } else if (hasUpdate) {
              trailingWidget = Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('v${UpdateManager.instance.availableUpdate!.version} →',
                    style: TextStyle(color: theme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
              );
              onTap = () {
                UpdateManager.instance.downloadAndInstall(context);
              };
            }

            return ListTile(
              onTap: onTap,
              title: Text('Версия', style: TextStyle(color: theme.onSurfaceVariant, fontSize: 14)),
              trailing: trailingWidget ?? Text(
                trailing,
                style: TextStyle(color: theme.onSurface, fontWeight: FontWeight.w500, fontSize: 14),
              ),
            );
          },
        );
      },
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
            onPressed: () async {
              final input = controller.text.trim();
              if (input.isEmpty) { Navigator.pop(ctx); return; }

              // Show loading
              Navigator.pop(ctx);

              try {
                String content;
                if (input.startsWith('http://') || input.startsWith('https://')) {
                  // Load subscription content from URL
                  final response = await http.get(Uri.parse(input)).timeout(
                    const Duration(seconds: 30),
                  );
                  if (response.statusCode == 200) {
                    content = response.body;
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Ошибка загрузки: HTTP ${response.statusCode}')),
                      );
                    }
                    return;
                  }
                } else {
                  // Treat as raw subscription content or mxspd:// link
                  content = input;
                }

                // Parse servers
                final servers = SubscriptionParser.parse(content);

                if (servers.isEmpty) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Не удалось распарсить подписку. Проверьте формат.')),
                    );
                  }
                  return;
                }

                // Save to service
                await widget.vpnService.updateServers(servers);

                // Save URL for reference
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('subscription_url', input);
                await prefs.setString('subscription_name', SubscriptionConstants.defaultName);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Подписка добавлена: ${servers.length} серверов')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка: $e')),
                  );
                }
              }
            },
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
