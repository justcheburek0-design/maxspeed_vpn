import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_themes.dart';
import '../../data/models/vpn_models.dart';
import '../../services/vpn_service.dart';
import '../widgets/power_button.dart';
import 'servers_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final VpnService vpnService;
  const HomeScreen({super.key, required this.vpnService});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  VpnConnectionState _state = VpnConnectionState.disconnected;
  VpnConnectionStats _stats = const VpnConnectionStats();
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _state = widget.vpnService.state;
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    widget.vpnService.stateStream.listen((s) {
      if (mounted) setState(() => _state = s);
    });
    widget.vpnService.statsStream.listen((s) {
      if (mounted) setState(() => _stats = s);
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = GlassTheme.of(context);
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: theme.bgPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, theme, cs),
              const SizedBox(height: 24),
              _buildSubscriptionSection(context, theme, cs),
              const SizedBox(height: 24),
              _buildPowerSection(context, theme, cs),
              const SizedBox(height: 20),
              _buildStatsRow(context, theme, cs),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext ctx, AppTheme theme, ColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'MaxSpeedVPN',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: theme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        IconButton.filledTonal(
          onPressed: () => _launchBot(),
          icon: const Icon(Icons.telegram, size: 20),
          style: IconButton.styleFrom(
            backgroundColor: theme.primaryContainer,
            foregroundColor: theme.onPrimaryContainer,
            minimumSize: const Size(40, 40),
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionSection(BuildContext ctx, AppTheme theme, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'ТЕКУЩАЯ ПОДПИСКА',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.onSurfaceVariant,
              letterSpacing: 0.8,
            ),
          ),
        ),
        // Subscription card — Material3 Card style
        Card(
          elevation: 0,
          color: theme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.outlineVariant, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MaxSpeedVPN',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: theme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '3 ч',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '09.06.26, 11:43',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Server count badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '11',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Support badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 6, color: theme.success),
                          const SizedBox(width: 4),
                          Text(
                            'Поддержка',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.refresh, size: 18, color: theme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Icon(Icons.link, size: 18, color: theme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Icon(Icons.more_horiz, size: 18, color: theme.onSurfaceVariant),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    Icon(Icons.event_outlined, size: 14, color: theme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      'Осталось 18 д',
                      style: TextStyle(fontSize: 13, color: theme.onSurfaceVariant),
                    ),
                    const Spacer(),
                    Text(
                      'by envywook',
                      style: TextStyle(fontSize: 12, color: theme.outline),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.data_usage_outlined, size: 14, color: theme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      '256.51 GB / ∞',
                      style: TextStyle(fontSize: 13, color: theme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPowerSection(BuildContext ctx, AppTheme theme, ColorScheme cs) {
    final isConnected = _state == VpnConnectionState.connected;
    return Column(
      children: [
        PowerButton(
          state: _state,
          onPressed: _onToggle,
          size: 150,
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _state.displayName,
            key: ValueKey(_state),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _stateColor(theme),
            ),
          ),
        ),
        if (widget.vpnService.activeServer != null) ...[
          const SizedBox(height: 2),
          Text(
            widget.vpnService.activeServer!.displayName,
            style: TextStyle(fontSize: 12, color: theme.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          isConnected ? 'Трафик защищён' : 'Нажмите для подключения',
          style: TextStyle(fontSize: 13, color: theme.outline),
        ),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext ctx, AppTheme theme, ColorScheme cs) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            theme,
            Icons.arrow_upward,
            _formatSpeed(_stats.uploadSpeed),
            'Загрузка',
            theme.secondaryContainer,
            theme.onSecondaryContainer,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            theme,
            Icons.arrow_downward,
            _formatSpeed(_stats.downloadSpeed),
            'Скачивание',
            theme.primaryContainer,
            theme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            theme,
            Icons.timer_outlined,
            _formatDuration(_stats.duration),
            'Время',
            theme.surfaceVariant,
            theme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    AppTheme theme,
    IconData icon,
    String value,
    String label,
    Color bg,
    Color fg,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: fg.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Color _stateColor(AppTheme theme) {
    switch (_state) {
      case VpnConnectionState.connected: return theme.success;
      case VpnConnectionState.connecting: return theme.warning;
      case VpnConnectionState.error: return theme.error;
      default: return theme.onSurfaceVariant;
    }
  }

  String _formatSpeed(int bytesPerSec) {
    if (bytesPerSec < 1024) return '$bytesPerSec B/s';
    if (bytesPerSec < 1024 * 1024) return '${(bytesPerSec / 1024).toStringAsFixed(1)} KB/s';
    return '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _onToggle() {
    if (_state == VpnConnectionState.connected) {
      widget.vpnService.disconnect();
    } else {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ServersScreen(vpnService: widget.vpnService),
      ));
    }
  }

  Future<void> _launchBot() async {
    final uri = Uri.parse('https://t.me/max_speedbot');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
