import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../data/models/vpn_models.dart';
import '../../services/vpn_service.dart';
import '../widgets/power_button.dart';

class HomeScreen extends StatefulWidget {
  final VpnService vpnService;
  const HomeScreen({super.key, required this.vpnService});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  VpnConnectionState _state = VpnConnectionState.disconnected;
  @override void initState() { super.initState(); _state = widget.vpnService.state; widget.vpnService.stateStream.listen((s) { if (mounted) setState(() => _state = s); }); }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(AppSpacing.md), child: Column(children: [
        _buildHeader(context),
        const SizedBox(height: AppSpacing.xl),
        PowerButton(state: _state, onPressed: _onToggle),
        const SizedBox(height: AppSpacing.md),
        Text(_state.displayName, style: AppText.headlineMedium(context)),
        const SizedBox(height: AppSpacing.xs),
        if (widget.vpnService.activeServer != null) Text(widget.vpnService.activeServer!.displayName, style: AppText.bodyMedium(context)),
        const SizedBox(height: AppSpacing.xl),
        _buildStats(context),
      ]))),
    );
  }

  Widget _buildHeader(BuildContext c) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('MaxSpeedVPN', style: AppText.headlineLarge(c)), Text('Быстрый и надёжный', style: AppText.bodySmall(c))]),
    IconButton(icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary), onPressed: () {}),
  ]);

  Widget _buildStats(BuildContext c) => Row(children: [
    Expanded(child: _statCard(c, '↑', '0 B/s', 'Загрузка')),
    const SizedBox(width: AppSpacing.sm),
    Expanded(child: _statCard(c, '↓', '0 B/s', 'Скачивание')),
    const SizedBox(width: AppSpacing.sm),
    Expanded(child: _statCard(c, '⏱', '0с', 'Время')),
  ]);

  Widget _statCard(BuildContext c, String icon, String value, String label) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(color: AppColors.bgSurface, borderRadius: BorderRadius.circular(AppRadii.md)),
    child: Column(children: [Text(icon, style: const TextStyle(fontSize: 20)), const SizedBox(height: AppSpacing.xs), Text(value, style: AppText.titleMedium(c)), Text(label, style: AppText.bodySmall(c))]),
  );

  void _onToggle() {
    if (_state == VpnConnectionState.connected) { widget.vpnService.disconnect(); }
    else { widget.vpnService.connect(VpnServer(id: 'demo', name: 'Demo Server', address: '1.2.3.4', port: 443, protocol: VpnProtocol.naive, username: 'user', rawConfig: {})); }
  }
}
