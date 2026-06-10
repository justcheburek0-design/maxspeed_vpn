import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/vpn_models.dart';

class ServerListItem extends StatelessWidget {
  final VpnServer server;
  final bool isSelected;
  final VoidCallback onTap;
  const ServerListItem({super.key, required this.server, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 1.5 : 1),
        ),
        child: Row(children: [
          Text(server.flag ?? '🏳️', style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(server.displayName, style: AppText.titleMedium(context)),
            const SizedBox(height: 2),
            Text('${server.protocol.displayName} · ${server.address}:${server.port}', style: AppText.bodySmall(context)),
          ])),
          if (server.ping != null) Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: _pingColor(server.ping!).withOpacity(0.1), borderRadius: BorderRadius.circular(AppRadii.sm)),
            child: Text(Formatters.formatPing(server.ping!), style: AppText.labelSmall(context).copyWith(color: _pingColor(server.ping!))),
          ),
          if (server.isFavorite) const Icon(Icons.star, color: AppColors.warning, size: 20),
        ]),
      ),
    );
  }
  Color _pingColor(int ms) => ms < 100 ? AppColors.success : ms < 200 ? AppColors.warning : AppColors.error;
}
