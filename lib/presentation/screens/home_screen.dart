import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_themes.dart';
import '../../data/models/vpn_models.dart';
import '../../services/vpn_service.dart';
import '../widgets/power_button.dart';
import '../widgets/glass_container.dart';
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
    return Scaffold(
      backgroundColor: theme.bgPrimary,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.6),
            radius: 1.2,
            colors: [
              theme.primary.withValues(alpha: 0.08),
              theme.bgPrimary,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                _buildHeader(context, theme),
                const SizedBox(height: 28),
                _buildConnectionCard(context, theme),
                const SizedBox(height: 20),
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _stateColor(theme),
                    ),
                  ),
                ),
                if (widget.vpnService.activeServer != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.vpnService.activeServer!.displayName,
                    style: TextStyle(fontSize: 13, color: theme.textSecondary),
                  ),
                ],
                const SizedBox(height: 24),
                _buildStats(context, theme),
                const SizedBox(height: 20),
                _buildSubscriptionCard(context, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext c, AppTheme theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.primary, theme.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MaxSpeedVPN', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textPrimary)),
                Text('v1.0.0', style: TextStyle(fontSize: 11, color: theme.textMuted)),
              ],
            ),
          ],
        ),
        GestureDetector(
          onTap: () => _launchBot(theme),
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [theme.primary, theme.accent]),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: theme.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: const Icon(Icons.telegram, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionCard(BuildContext c, AppTheme theme) {
    final isConnected = _state == VpnConnectionState.connected;
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: isConnected
                  ? [theme.primary.withValues(alpha: 0.15), theme.accent.withValues(alpha: 0.05)]
                  : [theme.bgCard, theme.bgSurface],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: isConnected
                  ? theme.primary.withValues(alpha: 0.3 + 0.2 * _glowController.value)
                  : theme.border,
              width: 1,
            ),
            boxShadow: isConnected
                ? [BoxShadow(color: theme.primary.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 4))]
                : null,
          ),
          child: child,
        );
      },
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _stateColor(theme).withValues(alpha: 0.15),
            ),
            child: Icon(
              isConnected ? Icons.lock : Icons.lock_open,
              color: _stateColor(theme),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConnected ? 'Подключено' : 'Отключено',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  isConnected ? 'Трафик защищён' : 'Нажмите для подключения',
                  style: TextStyle(fontSize: 12, color: theme.textMuted),
                ),
              ],
            ),
          ),
          if (isConnected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.success,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('ON', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.success)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext c, AppTheme theme) {
    return Row(
      children: [
        Expanded(child: _statCard(c, theme, Icons.arrow_upward, _formatSpeed(_stats.uploadSpeed), 'Загрузка', theme.accent)),
        const SizedBox(width: 10),
        Expanded(child: _statCard(c, theme, Icons.arrow_downward, _formatSpeed(_stats.downloadSpeed), 'Скачивание', theme.primary)),
        const SizedBox(width: 10),
        Expanded(child: _statCard(c, theme, Icons.timer_outlined, _formatDuration(_stats.duration), 'Время', theme.warning)),
      ],
    );
  }

  Widget _statCard(BuildContext c, AppTheme theme, IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.bgCard,
        border: Border.all(color: theme.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: theme.textMuted)),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext c, AppTheme theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.bgCard,
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Подписка', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Активна', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: theme.success)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.cloud_done, size: 16, color: theme.textMuted),
              const SizedBox(width: 8),
              Text('∞ GB • Безлимит', style: TextStyle(fontSize: 13, color: theme.textSecondary)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.event, size: 16, color: theme.textMuted),
              const SizedBox(width: 8),
              Text('18 дней осталось', style: TextStyle(fontSize: 13, color: theme.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(c, MaterialPageRoute(builder: (_) => ServersScreen(vpnService: widget.vpnService)));
                  },
                  icon: Icon(Icons.dns_outlined, size: 16, color: theme.primary),
                  label: Text('Серверы', style: TextStyle(color: theme.primary, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.primary.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(c, MaterialPageRoute(builder: (_) => SettingsScreen(vpnService: widget.vpnService)));
                  },
                  icon: Icon(Icons.settings_outlined, size: 16, color: theme.primary),
                  label: Text('Настройки', style: TextStyle(color: theme.primary, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.primary.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(borderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
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
      default: return theme.textSecondary;
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
      Navigator.push(context, MaterialPageRoute(builder: (_) => ServersScreen(vpnService: widget.vpnService)));
    }
  }

  Future<void> _launchBot(AppTheme theme) async {
    final uri = Uri.parse('https://t.me/max_speedbot');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
