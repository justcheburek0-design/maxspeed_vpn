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

class _HomeScreenState extends State<HomeScreen> {
  VpnConnectionState _state = VpnConnectionState.disconnected;
  VpnConnectionStats _stats = const VpnConnectionStats();

  @override
  void initState() {
    super.initState();
    _state = widget.vpnService.state;
    widget.vpnService.stateStream.listen((s) {
      if (mounted) setState(() => _state = s);
    });
    widget.vpnService.statsStream.listen((s) {
      if (mounted) setState(() => _stats = s);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = GlassTheme.of(context);
    return Scaffold(
      backgroundColor: theme.bgPrimary,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.bgPrimary, theme.bgSecondary],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                _buildHeader(context, theme),
                const SizedBox(height: 32),
                PowerButton(
                  state: _state,
                  onPressed: _onToggle,
                  size: 160,
                ),
                const SizedBox(height: 16),
                Text(
                  _state.displayName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _stateColor(theme),
                  ),
                ),
                if (widget.vpnService.activeServer != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.vpnService.activeServer!.displayName,
                    style: TextStyle(fontSize: 14, color: theme.textSecondary),
                  ),
                ],
                const SizedBox(height: 32),
                _buildStats(context, theme),
                const SizedBox(height: 24),
                _buildQuickActions(context, theme),
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MaxSpeedVPN', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textPrimary)),
            Text('Быстрый и надёжный', style: TextStyle(fontSize: 13, color: theme.textMuted)),
          ],
        ),
        GestureDetector(
          onTap: () => _launchBot(theme),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [theme.primary, theme.accent]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: theme.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.telegram, color: Colors.white, size: 22),
          ),
        ),
      ],
    );
  }

  Widget _buildStats(BuildContext c, AppTheme theme) {
    return Row(
      children: [
        Expanded(child: _statCard(c, theme, '↑', _formatSpeed(_stats.uploadSpeed), 'Загрузка')),
        const SizedBox(width: 12),
        Expanded(child: _statCard(c, theme, '↓', _formatSpeed(_stats.downloadSpeed), 'Скачивание')),
        const SizedBox(width: 12),
        Expanded(child: _statCard(c, theme, '⏱', _formatDuration(_stats.duration), 'Время')),
      ],
    );
  }

  Widget _statCard(BuildContext c, AppTheme theme, String icon, String value, String label) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(icon, style: TextStyle(fontSize: 20, color: theme.primary)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.textPrimary)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: theme.textMuted)),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext c, AppTheme theme) {
    return Row(
      children: [
        Expanded(
          child: _actionButton(c, theme, Icons.dns_outlined, 'Серверы', () {
            Navigator.push(c, MaterialPageRoute(builder: (_) => ServersScreen(vpnService: widget.vpnService)));
          }),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionButton(c, theme, Icons.settings_outlined, 'Настройки', () {
            Navigator.push(c, MaterialPageRoute(builder: (_) => SettingsScreen(vpnService: widget.vpnService)));
          }),
        ),
      ],
    );
  }

  Widget _actionButton(BuildContext c, AppTheme theme, IconData icon, String label, VoidCallback onTap) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Icon(icon, size: 28, color: theme.primary),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: theme.textPrimary)),
          ],
        ),
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
      // Show server picker or use last server
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
