import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_themes.dart';
import '../../data/models/vpn_models.dart';
import '../../services/vpn_service_interface.dart';
import '../../services/update_manager_export.dart';
import '../widgets/power_button.dart';
import '../../core/utils/notifications.dart';

class HomeScreen extends StatefulWidget {
  final VpnService vpnService;
  const HomeScreen({super.key, required this.vpnService});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  VpnConnectionState _state = VpnConnectionState.disconnected;
  VpnConnectionStats _stats = const VpnConnectionStats();
  VpnServer? _selectedServer;
  late AnimationController _bgAnimController;
  late AnimationController _glowController;
  String _serverSearch = '';
  bool _searchEnabled = false;
  bool _isRefreshing = false;
  bool _isPinging = false;
  final Map<String, int> _pingResults = {};

  @override
  void initState() {
    super.initState();
    _state = widget.vpnService.state;
    _selectedServer = widget.vpnService.activeServer;
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _loadSettings();
    widget.vpnService.stateStream.listen((s) {
      if (mounted) {
        setState(() => _state = s);
        if (s == VpnConnectionState.connected &&
            widget.vpnService.activeServer != null) {
          _selectedServer = widget.vpnService.activeServer;
        }
      }
    });
    widget.vpnService.statsStream.listen((s) {
      if (mounted) setState(() => _stats = s);
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _searchEnabled = prefs.getBool('search_enabled') ?? false);
    }
  }

  @override
  void dispose() {
    _bgAnimController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  bool get _isConnected => _state == VpnConnectionState.connected;

  List<VpnServer> get _filteredServers {
    final servers = widget.vpnService.servers;
    if (_serverSearch.isEmpty) return servers;
    final q = _serverSearch.toLowerCase();
    return servers
        .where(
          (s) =>
              s.name.toLowerCase().contains(q) ||
              (s.description?.toLowerCase().contains(q) ?? false) ||
              s.address.toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> _refreshSubscription() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await Future.delayed(const Duration(seconds: 1));
      // Subscription refresh is handled by the service layer
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = GlassTheme.of(context);

    if (kIsWeb) {
      return _buildWebLayout(theme);
    }

    return Stack(
      children: [
        _buildBg(theme),
        RefreshIndicator(
          onRefresh: _refreshSubscription,
          color: theme.primary,
          backgroundColor: theme.surface,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSubscriptionCard(context, theme),
                const SizedBox(height: 12),
                _buildUpdateBanner(context, theme),
                const SizedBox(height: 20),
                _buildPowerSection(context, theme),
                const SizedBox(height: 20),
                if (_isConnected) _buildCompactStats(theme),
                if (_isConnected) const SizedBox(height: 20),
                _buildServersSection(context, theme),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWebLayout(AppTheme theme) {
    return Stack(
      children: [
        _buildBg(theme),
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
          child: Column(
            children: [
              _buildSubscriptionCard(context, theme),
              const SizedBox(height: 20),
              _buildWebDownloadSection(context, theme),
              const SizedBox(height: 20),
              _buildServersSection(context, theme),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBg(AppTheme theme) {
    return AnimatedBuilder(
      animation: _bgAnimController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.bgPrimary,
                Color.lerp(
                  theme.bgPrimary,
                  theme.primary.withValues(alpha: 0.05),
                  _bgAnimController.value,
                )!,
                theme.bgPrimary,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubscriptionCard(BuildContext ctx, AppTheme theme) {
    final subName = SubscriptionConstants.defaultName;
    final daysLeft = SubscriptionConstants.defaultDaysLeft;
    final totalGB = SubscriptionConstants.defaultTotalGB;
    final usedGB = SubscriptionConstants.defaultUsedGB;
    final progress = (usedGB / totalGB).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.subscriptions_outlined,
                  color: theme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: theme.onSurface,
                      ),
                    ),
                    Text(
                      'Осталось $daysLeft дн.',
                      style: TextStyle(
                        fontSize: 12,
                        color: daysLeft < 7
                            ? theme.error
                            : theme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isRefreshing)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.primary,
                  ),
                )
              else
                GestureDetector(
                  onTap: _refreshSubscription,
                  child: Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: theme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                SubscriptionConstants.creditLine,
                style: TextStyle(
                  fontSize: 10,
                  color: theme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Трафик',
                style: TextStyle(fontSize: 11, color: theme.onSurfaceVariant),
              ),
              Text(
                '${usedGB.toStringAsFixed(1)} / ${totalGB.toStringAsFixed(0)} GB',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: theme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 0.8 ? theme.error : theme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateBanner(BuildContext ctx, AppTheme theme) {
    return StreamBuilder<UpdateDownloadState>(
      stream: UpdateManager.instance.progressStream,
      initialData: UpdateManager.instance.state,
      builder: (context, snapshot) {
        final state = snapshot.data ?? UpdateManager.instance.state;
        final hasUpdate = UpdateManager.instance.availableUpdate != null;
        final isReady = UpdateManager.instance.isUpdateReady;
        final isDownloading =
            state.status == 'downloading' || state.status == 'paused';
        if (!hasUpdate && !isReady && !isDownloading)
          return const SizedBox.shrink();

        String title;
        String? subtitle;
        IconData icon;
        Color accentColor;
        VoidCallback? onTap;

        if (isDownloading) {
          final pct = state.progress > 0
              ? (state.progress * 100).toStringAsFixed(0)
              : null;
          title = pct != null ? 'Скачивание $pct%' : 'Скачивание...';
          if (state.status == 'paused') {
            subtitle = 'Ожидание подключения...';
          } else if (state.totalBytes > 0) {
            final mb = (state.receivedBytes / 1024 / 1024).toStringAsFixed(1);
            final totalMb = (state.totalBytes / 1024 / 1024).toStringAsFixed(1);
            subtitle = '$mb / $totalMb MB';
          }
          icon = Icons.downloading_rounded;
          accentColor = theme.primary;
          onTap = () => UpdateManager.instance.downloadAndInstall(context);
        } else if (isReady) {
          final v = UpdateManager.instance.availableUpdate?.version ?? '';
          title = 'Обновление готово — v$v';
          subtitle = 'Нажмите для установки';
          icon = Icons.system_update_rounded;
          accentColor = theme.success;
          onTap = () => UpdateManager.instance.downloadAndInstall(context);
        } else {
          final v = UpdateManager.instance.availableUpdate?.version ?? '';
          title = 'Доступна версия $v';
          subtitle = 'Нажмите для обновления';
          icon = Icons.new_releases_outlined;
          accentColor = theme.primary;
          onTap = () => UpdateManager.instance.downloadAndInstall(context);
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accentColor.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: accentColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.onSurface,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (isDownloading && state.progress > 0) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: state.progress,
                              minHeight: 4,
                              backgroundColor: theme.surfaceVariant,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                accentColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.outline,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPowerSection(BuildContext ctx, AppTheme theme) {
    final isConnected = _state == VpnConnectionState.connected;
    final server = widget.vpnService.activeServer;

    return Column(
      children: [
        Center(
          child: PowerButton(state: _state, onPressed: _onToggle, size: 170),
        ),
        const SizedBox(height: 20),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Column(
            key: ValueKey(_state),
            children: [
              Text(
                _state == VpnConnectionState.error
                    ? 'Ошибка — проверьте настройки'
                    : isConnected
                    ? 'Подключено'
                    : _state == VpnConnectionState.connecting
                    ? 'Подключение...'
                    : 'Отключено',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _stateColor(theme),
                ),
              ),
              if (server != null) ...[
                const SizedBox(height: 6),
                Text(
                  '${server.flag ?? "🌐"} ${server.name}  ·  ${server.protocol.displayName}',
                  style: TextStyle(fontSize: 13, color: theme.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                isConnected ? 'Трафик защищён 🔒' : 'Нажмите для подключения',
                style: TextStyle(fontSize: 13, color: theme.outline),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Compact Stats: arrows + time only ───

  Widget _buildCompactStats(AppTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.arrow_upward_rounded, size: 16, color: theme.primary),
          const SizedBox(width: 4),
          Text(
            _formatSpeedCompact(_stats.uploadSpeed),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.onSurface,
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.access_time_rounded,
            size: 14,
            color: theme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            _formatDurationCompact(_stats.duration),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.onSurface,
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.arrow_downward_rounded, size: 16, color: theme.primary),
          const SizedBox(width: 4),
          Text(
            _formatSpeedCompact(_stats.downloadSpeed),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Servers Section ───

  Widget _buildServersSection(BuildContext ctx, AppTheme theme) {
    final servers = _filteredServers;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Text(
                'СЕРВЕРЫ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.onSurfaceVariant,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              _iconBtn(
                ctx,
                theme,
                Icons.network_ping_rounded,
                'Пинг',
                _onPingServers,
              ),
              const SizedBox(width: 6),
              _iconBtn(
                ctx,
                theme,
                Icons.autorenew_rounded,
                'Перезагрузка',
                _onAutoReload,
              ),
            ],
          ),
        ),
        if (_searchEnabled)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              onChanged: (v) => setState(() => _serverSearch = v),
              style: TextStyle(color: theme.onSurface, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Поиск серверов...',
                hintStyle: TextStyle(color: theme.outline, fontSize: 14),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: theme.outline,
                  size: 20,
                ),
                suffixIcon: _serverSearch.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: theme.outline, size: 18),
                        onPressed: () => setState(() => _serverSearch = ''),
                      )
                    : null,
                filled: true,
                fillColor: theme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.primary.withValues(alpha: 0.5),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ),
        if (servers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    size: 48,
                    color: theme.outline,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Нет серверов',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Добавьте подписку в настройках',
                    style: TextStyle(fontSize: 13, color: theme.outline),
                  ),
                ],
              ),
            ),
          )
        else
          ...servers.map((server) => _serverTile(ctx, theme, server)),
      ],
    );
  }

  Widget _iconBtn(
    BuildContext ctx,
    AppTheme theme,
    IconData icon,
    String tooltip,
    VoidCallback onTap,
  ) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Icon(icon, size: 16, color: theme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }

  Future<void> _onPingServers() async {
    if (_isPinging) return;
    setState(() {
      _isPinging = true;
      _pingResults.clear();
    });
    final servers = widget.vpnService.servers;
    if (servers.isEmpty) {
      setState(() => _isPinging = false);
      showAppNotification(context, 'Нет серверов для пинга');
      return;
    }
    if (mounted)
      showAppNotification(
        context,
        'Пинг ${servers.length} серверов...',
        duration: const Duration(seconds: 30),
      );
    try {
      final futures = servers.map((s) => _pingServer(s));
      final results = await Future.wait(futures);
      for (int i = 0; i < servers.length; i++) {
        _pingResults[servers[i].id] = results[i];
      }
      if (mounted) {
        final reachable = _pingResults.values.where((v) => v > 0).toList();
        final avg = reachable.isEmpty
            ? 0
            : (reachable.fold(0, (a, b) => a + b) / reachable.length).round();
        showAppNotification(
          context,
          'Пинг готов! Средний: ${avg}ms (${reachable.length}/${servers.length} доступно)',
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      if (mounted) {
        showAppNotification(context, 'Ошибка пинга: $e', isError: true);
      }
    }
    if (mounted) setState(() => _isPinging = false);
  }

  Future<int> _pingServer(VpnServer server) async {
    final sw = Stopwatch()..start();
    try {
      // HTTP-based ping — works on all platforms including web
      final uri = Uri.parse('http://${server.address}:${server.port}');
      await http.get(uri).timeout(const Duration(seconds: 5));
      sw.stop();
      return sw.elapsedMilliseconds;
    } catch (_) {
      sw.stop();
      return -1;
    }
  }

  void _onCopyConfig(VpnServer server) {
    final link = server.rawLink.isNotEmpty
        ? server.rawLink
        : '${server.protocol.displayName.toLowerCase()}://${server.address}:${server.port}';
    Clipboard.setData(ClipboardData(text: link));
    showAppNotification(
      context,
      'Конфиг "${server.name}" скопирован!',
      duration: const Duration(seconds: 2),
    );
  }

  void _onWebExportConfig(VpnServer server) {
    final link = server.rawLink.isNotEmpty
        ? server.rawLink
        : '${server.protocol.displayName.toLowerCase()}://${server.address}:${server.port}';
    Clipboard.setData(ClipboardData(text: link));
    showAppNotification(
      context,
      'Конфиг "${server.name}" скопирован!',
      duration: const Duration(seconds: 2),
    );
  }

  void _onAutoReload() {
    showAppNotification(
      context,
      'Авто-перезагрузка',
      duration: const Duration(seconds: 2),
    );
  }

  Widget _serverTile(BuildContext c, AppTheme theme, VpnServer server) {
    final isActive = _selectedServer?.id == server.id;
    final isConnected =
        widget.vpnService.activeServer?.id == server.id &&
        _state == VpnConnectionState.connected;
    final pingResult = _pingResults[server.id];
    final displayPing = pingResult ?? server.ping;
    final pingColor = _pingColor(displayPing ?? 999);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _connect(server),
          onLongPress: () => _showServerContextMenu(c, server),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isActive
                  ? theme.primary.withValues(alpha: 0.08)
                  : theme.surface,
              border: Border.all(
                color: isActive
                    ? theme.primary.withValues(alpha: 0.4)
                    : theme.outlineVariant,
                width: isActive ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: theme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      server.flag ?? '🌐',
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        server.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.onSurface,
                        ),
                      ),
                      if (server.description != null &&
                          server.description!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          server.description!,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: [
                          _badge(
                            theme,
                            server.protocol.displayName,
                            theme.primary,
                          ),
                          if (server.security != VpnSecurity.none)
                            _badge(
                              theme,
                              server.security.displayName,
                              theme.protocolColor(server.security),
                            ),
                          if (server.isXhttp)
                            _badge(theme, 'XHTTP', theme.protocolXhttp),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (displayPing != null) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: pingColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${displayPing}ms',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: pingColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                    if (isActive)
                      Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: theme.success,
                      )
                    else
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: theme.outline,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showServerContextMenu(BuildContext context, VpnServer server) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = GlassTheme.of(ctx);
        return Container(
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: theme.outlineVariant),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  server.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Icon(Icons.copy_rounded, color: theme.primary),
                title: const Text('Копировать конфиг'),
                onTap: () {
                  Navigator.pop(ctx);
                  _onCopyConfig(server);
                },
              ),
              if (kIsWeb)
                ListTile(
                  leading: Icon(Icons.code_rounded, color: theme.primary),
                  title: const Text('Копировать Singbox JSON'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _onWebExportConfig(server);
                  },
                ),
              ListTile(
                leading: Icon(Icons.share_rounded, color: theme.primary),
                title: const Text('Поделиться'),
                onTap: () {
                  Navigator.pop(ctx);
                  _shareConfig(server);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _shareConfig(VpnServer server) {
    final link = server.rawLink.isNotEmpty
        ? server.rawLink
        : '${server.protocol.displayName.toLowerCase()}://${server.address}:${server.port}';
    // On native, use share_plus alternative; for now just copy
    Clipboard.setData(ClipboardData(text: link));
    showAppNotification(
      context,
      'Ссылка "${server.name}" скопирована для шаринга',
      duration: const Duration(seconds: 2),
    );
  }

  Widget _badge(AppTheme theme, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _pingColor(int ping) {
    if (ping < 100) return const Color(0xFFA8E63D);
    if (ping < 300) return const Color(0xFFFBBF24);
    return const Color(0xFFFF7043);
  }

  Future<void> _connect(VpnServer server) async {
    setState(() => _selectedServer = server);
    // Apply per-app proxy settings before connecting
    await _applyPerAppProxy();
    widget.vpnService.connect(server).then((success) {
      if (!success && mounted) {
        showAppNotification(
          context,
          'Не удалось подключиться. Проверьте настройки.',
          isError: true,
          duration: const Duration(seconds: 3),
        );
      }
    });
  }

  Future<void> _applyPerAppProxy() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final excludedStr = prefs.getString('excluded_apps') ?? '';
      final excludedApps = excludedStr.isEmpty
          ? <String>[]
          : excludedStr.split(',');
      final proxyModeBypass = prefs.getBool('proxy_mode_bypass') ?? true;
      await widget.vpnService.setPerAppProxyMode(
        proxyModeBypass ? 'bypass' : 'tunnel',
      );
      await widget.vpnService.setPerAppProxyList(excludedApps);
    } catch (e) {
      debugPrint('Failed to apply per-app proxy: $e');
    }
  }

  Color _stateColor(AppTheme theme) {
    switch (_state) {
      case VpnConnectionState.connected:
        return theme.success;
      case VpnConnectionState.connecting:
      case VpnConnectionState.reconnecting:
        return theme.warning;
      case VpnConnectionState.error:
        return theme.error;
      default:
        return theme.onSurfaceVariant;
    }
  }

  String _formatSpeedCompact(int bytesPerSec) {
    if (bytesPerSec <= 0) return '? B/s';
    if (bytesPerSec < 1024) return '$bytesPerSec B/s';
    if (bytesPerSec < 1024 * 1024)
      return '${(bytesPerSec / 1024).toStringAsFixed(1)} KB/s';
    return '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  String _formatDurationCompact(Duration d) {
    final totalSeconds = d.inSeconds;
    if (totalSeconds < 60)
      return '00:${totalSeconds.toString().padLeft(2, '0')}';
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = totalSeconds % 60;
    if (hours == 0)
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _onToggle() {
    if (_state == VpnConnectionState.connecting ||
        _state == VpnConnectionState.disconnecting) {
      // Do nothing while transitioning
      return;
    }
    if (_state == VpnConnectionState.connected) {
      widget.vpnService.disconnect();
      return;
    }
    if (_state == VpnConnectionState.error) {
      // Allow retry after error, but require explicit server selection
      final server = _selectedServer ?? widget.vpnService.activeServer;
      if (server != null) {
        _connect(server);
      } else {
        final servers = widget.vpnService.servers;
        if (servers.isNotEmpty) {
          _connect(servers.first);
        }
      }
      return;
    }
    // disconnected state
    final server = widget.vpnService.activeServer ?? _selectedServer;
    if (server != null) {
      _connect(server);
    } else {
      final servers = widget.vpnService.servers;
      if (servers.isNotEmpty) {
        _connect(servers.first);
      } else {
        showAppNotification(
          context,
          'Нет серверов — добавьте подписку в настройках',
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  Future<void> _launchBot() async {
    final uri = Uri.parse('https://t.me/max_speedbot');
    if (await canLaunchUrl(uri))
      await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _buildWebDownloadSection(BuildContext ctx, AppTheme theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_download_outlined, size: 48, color: theme.primary),
          const SizedBox(height: 12),
          Text(
            'Скачайте нативный клиент',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: theme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'VPN в браузере невозможен. Установите приложение для полной защиты.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: theme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _downloadBtn(
                ctx,
                theme,
                'Android',
                Icons.android,
                'https://github.com/justcheburek0-design/maxspeed_vpn/releases',
              ),
              _downloadBtn(
                ctx,
                theme,
                'Windows',
                Icons.desktop_windows,
                'https://github.com/justcheburek0-design/maxspeed_vpn/releases',
              ),
              _downloadBtn(
                ctx,
                theme,
                'macOS',
                Icons.laptop_mac,
                'https://github.com/justcheburek0-design/maxspeed_vpn/releases',
              ),
              _downloadBtn(
                ctx,
                theme,
                'Linux',
                Icons.computer,
                'https://github.com/justcheburek0-design/maxspeed_vpn/releases',
              ),
              _downloadBtn(
                ctx,
                theme,
                'iOS',
                Icons.phone_iphone,
                'https://apps.apple.com',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Или используйте конфиги из раздела серверов с любым совместимым клиентом',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: theme.outline),
          ),
        ],
      ),
    );
  }

  Widget _downloadBtn(
    BuildContext ctx,
    AppTheme theme,
    String label,
    IconData icon,
    String url,
  ) {
    return OutlinedButton.icon(
      onPressed: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri))
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.primary,
        side: BorderSide(color: theme.outlineVariant),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }
}
