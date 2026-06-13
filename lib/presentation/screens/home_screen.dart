import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_themes.dart';
import '../../data/models/vpn_models.dart';
import '../../services/vpn_service_interface.dart';
import '../../services/update_checker_native.dart';
import '../widgets/power_button.dart';

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
    widget.vpnService.stateStream.listen((s) {
      if (mounted) {
        setState(() => _state = s);
        // Sync selectedServer with activeServer on state change
        if (s == VpnConnectionState.connected && widget.vpnService.activeServer != null) {
          _selectedServer = widget.vpnService.activeServer;
        }
      }
    });
    widget.vpnService.statsStream.listen((s) {
      if (mounted) setState(() => _stats = s);
    });
    widget.vpnService.serversStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _bgAnimController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  List<VpnServer> get _filteredServers {
    final servers = widget.vpnService.servers;
    if (_serverSearch.isEmpty) return servers;
    return servers.where((s) =>
      s.name.toLowerCase().contains(_serverSearch.toLowerCase()) ||
      (s.country?.toLowerCase().contains(_serverSearch.toLowerCase()) ?? false)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = GlassTheme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: _bgAnimController,
        builder: (context, child) {
          final t = _bgAnimController.value;
          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.3 + t * 0.4, -0.6 + t * 0.2),
                radius: 1.2,
                colors: [
                  Color.lerp(theme.bgPrimary, theme.primary.withValues(alpha: 0.06), t)!,
                  Color.lerp(theme.bgPrimary, theme.primary.withValues(alpha: 0.02), 1 - t)!,
                  theme.bgPrimary,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              children: [
                _buildHeader(context, theme),
                const SizedBox(height: 24),
                _buildSubscriptionCard(context, theme),
                const SizedBox(height: 24),
                _buildUpdateBanner(context, theme),
                const SizedBox(height: 24),
                if (kIsWeb) _buildWebDownloadSection(context, theme),
                if (!kIsWeb) _buildPowerSection(context, theme),
                const SizedBox(height: 24),
                _buildServersSection(context, theme),
                if (!kIsWeb) ...[
                  const SizedBox(height: 24),
                  _buildStatsSection(context, theme),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext ctx, AppTheme theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: theme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            _buildStatusLine(theme),
          ],
        ),
        IconButton.filledTonal(
          onPressed: _launchBot,
          icon: const Icon(Icons.telegram, size: 20),
          style: IconButton.styleFrom(
            backgroundColor: theme.primaryContainer,
            foregroundColor: theme.onPrimaryContainer,
            minimumSize: const Size(44, 44),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusLine(AppTheme theme) {
    final server = widget.vpnService.activeServer;
    final isConnected = _state == VpnConnectionState.connected;
    final isConnecting = _state == VpnConnectionState.connecting ||
        _state == VpnConnectionState.reconnecting;

    String text;
    Color color;
    if (isConnected && server != null) {
      text = '${server.flag ?? "🌐"} ${server.name}';
      color = theme.success;
    } else if (isConnecting) {
      text = _state.displayName;
      color = theme.warning;
    } else if (_state == VpnConnectionState.error) {
      text = 'Ошибка подключения';
      color = theme.error;
    } else {
      text = 'Отключено';
      color = theme.onSurfaceVariant;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: isConnected
                ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)]
                : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
        ),
      ],
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
                child: Icon(Icons.subscriptions_outlined, color: theme.primary, size: 18),
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
                        color: daysLeft < 7 ? theme.error : theme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
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
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.onSurface),
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
        final isDownloading = state.status == 'downloading' || state.status == 'paused';

        if (!hasUpdate && !isReady && !isDownloading) return const SizedBox.shrink();

        String title;
        String? subtitle;
        IconData icon;
        Color accentColor;
        VoidCallback? onTap;

        if (isDownloading) {
          final pct = state.progress > 0 ? (state.progress * 100).toStringAsFixed(0) : null;
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
          // Has update but not downloading yet
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
                        Text(title,
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600, color: theme.onSurface)),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(subtitle,
                              style: TextStyle(fontSize: 12, color: theme.onSurfaceVariant)),
                        ],
                        if (isDownloading && state.progress > 0) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: state.progress,
                              minHeight: 4,
                              backgroundColor: theme.surfaceVariant,
                              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: theme.outline, size: 20),
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
          child: PowerButton(
            state: _state,
            onPressed: _onToggle,
            size: 170,
          ),
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

  Widget _buildStatsSection(BuildContext ctx, AppTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'СТАТИСТИКА',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.onSurfaceVariant,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _statCard(
                theme,
                Icons.arrow_upward_rounded,
                _formatSpeed(_stats.uploadSpeed),
                'Загрузка',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                theme,
                Icons.arrow_downward_rounded,
                _formatSpeed(_stats.downloadSpeed),
                'Скачивание',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                theme,
                Icons.timer_outlined,
                _formatDuration(_stats.duration),
                'Время',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildDataUsage(theme),
      ],
    );
  }

  Widget _buildDataUsage(AppTheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.outlineVariant, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.data_usage_outlined, size: 20, color: theme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Трафик',
                  style: TextStyle(fontSize: 11, color: theme.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatBytes(_stats.downloadTotal)} ↓  ${_formatBytes(_stats.uploadTotal)} ↑',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.onSurface,
                  ),
                ),
              ],
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
          child: Text(
            'СЕРВЕРЫ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.onSurfaceVariant,
              letterSpacing: 0.8,
            ),
          ),
        ),
        // Search bar
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            onChanged: (v) => setState(() => _serverSearch = v),
            style: TextStyle(color: theme.onSurface, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Поиск серверов...',
              hintStyle: TextStyle(color: theme.outline, fontSize: 14),
              prefixIcon: Icon(Icons.search_rounded, color: theme.outline, size: 20),
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
                borderSide: BorderSide(color: theme.primary.withValues(alpha: 0.5)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        // Server list
        if (servers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off_outlined, size: 48, color: theme.outline),
                  const SizedBox(height: 12),
                  Text(
                    'Нет серверов',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.onSurfaceVariant),
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

  Widget _serverTile(BuildContext c, AppTheme theme, VpnServer server) {
    final isActive = _selectedServer?.id == server.id;
    final isConnected = widget.vpnService.activeServer?.id == server.id && 
        _state == VpnConnectionState.connected;
    final pingColor = _pingColor(server.ping ?? 999);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _connect(server),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isActive ? theme.primary.withValues(alpha: 0.08) : theme.surface,
              border: Border.all(
                color: isActive ? theme.primary.withValues(alpha: 0.4) : theme.outlineVariant,
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
                    child: Text(server.flag ?? '🌐', style: const TextStyle(fontSize: 22)),
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
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: [
                          _badge(theme, server.protocol.displayName, theme.primary),
                          if (server.security != VpnSecurity.none)
                            _badge(theme, server.security.displayName, theme.protocolColor(server.security)),
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
                    if (server.ping != null) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: pingColor),
                          ),
                          const SizedBox(width: 4),
                          Text('${server.ping}ms', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: pingColor)),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                    if (isActive)
                      Icon(Icons.check_circle_rounded, size: 18, color: theme.success)
                    else
                      Icon(Icons.chevron_right_rounded, size: 20, color: theme.outline),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Color _pingColor(int ping) {
    if (ping < 100) return const Color(0xFFA8E63D);
    if (ping < 300) return const Color(0xFFFBBF24);
    return const Color(0xFFFF7043);
  }

  void _connect(VpnServer server) {
    setState(() => _selectedServer = server);
    widget.vpnService.connect(server).then((success) {
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось подключиться. Проверьте настройки.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  // ─── Common ───

  Widget _statCard(AppTheme theme, IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.outlineVariant, width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: theme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: theme.onSurfaceVariant),
          ),
        ],
      ),
    );
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

  String _formatSpeed(int bytesPerSec) {
    if (bytesPerSec < 1024) return '$bytesPerSec B/s';
    if (bytesPerSec < 1024 * 1024) {
      return '${(bytesPerSec / 1024).toStringAsFixed(1)} KB/s';
    }
    return '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _onToggle() {
    if (_state == VpnConnectionState.connected ||
        _state == VpnConnectionState.connecting) {
      widget.vpnService.disconnect();
    } else {
      final server = widget.vpnService.activeServer ?? _selectedServer;
      if (server != null) {
        widget.vpnService.connect(server).then((success) {
          if (!success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Не удалось подключиться'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        });
      } else {
        // No server selected — pick first available
        final servers = widget.vpnService.servers;
        if (servers.isNotEmpty) {
          _connect(servers.first);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Нет серверов — добавьте подписку в настройках'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _launchBot() async {
    final uri = Uri.parse('https://t.me/max_speedbot');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ─── Web download section ───

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
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
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
