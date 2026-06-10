import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../data/models/vpn_models.dart';
import '../../services/log_service.dart';

class LogsScreen extends StatelessWidget {
  final LogService logService;
  const LogsScreen({super.key, required this.logService});

  @override Widget build(BuildContext context) {
    final logs = logService.logs;
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(backgroundColor: AppColors.bgPrimary, title: Text('Логи', style: AppText.headlineMedium(context)), elevation: 0, actions: [IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.textSecondary), onPressed: () => logService.clear())]),
      body: logs.isEmpty ? Center(child: Text('Нет логов', style: AppText.bodyLarge(context))) : ListView.builder(padding: const EdgeInsets.all(AppSpacing.sm), itemCount: logs.length, itemBuilder: (c, i) => _item(c, logs[logs.length - 1 - i])),
    );
  }

  Widget _item(BuildContext c, VpnLogEntry log) {
    final lc = log.level == VpnLogLevel.error ? AppColors.error : log.level == VpnLogLevel.warning ? AppColors.warning : log.level == VpnLogLevel.info ? AppColors.primary : AppColors.textMuted;
    return Container(margin: const EdgeInsets.symmetric(vertical: 2), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.bgSurface, borderRadius: BorderRadius.circular(8)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 4, height: 40, decoration: BoxDecoration(color: lc, borderRadius: BorderRadius.circular(2))), const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(log.message, style: AppText.bodyMedium(c)), if (log.details != null) Text(log.details!, style: AppText.bodySmall(c))])),
      Text('${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}', style: AppText.bodySmall(c)),
    ]));
  }
}
