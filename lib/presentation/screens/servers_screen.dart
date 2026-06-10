import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../services/subscription_service.dart';
import '../widgets/server_list_item.dart';

class ServersScreen extends StatefulWidget {
  final SubscriptionService subscriptionService;
  const ServersScreen({super.key, required this.subscriptionService});
  @override State<ServersScreen> createState() => _ServersScreenState();
}

class _ServersScreenState extends State<ServersScreen> {
  String? _selectedId;
  @override Widget build(BuildContext context) {
    final servers = widget.subscriptionService.allServers;
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(backgroundColor: AppColors.bgPrimary, title: Text('Серверы', style: AppText.headlineMedium(context)), elevation: 0),
      body: servers.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.dns_outlined, size: 64, color: AppColors.textMuted),
              const SizedBox(height: AppSpacing.md),
              Text('Нет серверов', style: AppText.titleLarge(context)),
              const SizedBox(height: AppSpacing.xs),
              Text('Добавьте подписку в настройках', style: AppText.bodyMedium(context)),
            ]))
          : ListView.builder(padding: const EdgeInsets.all(AppSpacing.sm), itemCount: servers.length, itemBuilder: (c, i) => ServerListItem(server: servers[i], isSelected: _selectedId == servers[i].id, onTap: () => setState(() => _selectedId = servers[i].id))),
    );
  }
}
