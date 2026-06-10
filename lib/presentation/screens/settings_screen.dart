import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  final SettingsService settingsService;
  const SettingsScreen({super.key, required this.settingsService});
  @override State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(backgroundColor: AppColors.bgPrimary, title: Text('Настройки', style: AppText.headlineMedium(context)), elevation: 0),
      body: ListView(padding: const EdgeInsets.all(AppSpacing.md), children: [
        _sh('Подключение'),
        _toggle(Icons.auto_awesome, 'Автоподключение', 'Подключаться при запуске', widget.settingsService.autoConnect, (v) => setState(() => widget.settingsService.setAutoConnect(v))),
        _toggle(Icons.shield_outlined, 'Kill Switch', 'Блокировать трафик при отключении', widget.settingsService.killSwitch, (v) => setState(() => widget.settingsService.setKillSwitch(v))),
        const SizedBox(height: AppSpacing.lg),
        _sh('Внешний вид'),
        _toggle(Icons.dark_mode_outlined, 'Тёмная тема', 'Всегда тёмная тема', widget.settingsService.themeMode == ThemeMode.dark, (v) => setState(() => widget.settingsService.setThemeMode(v ? ThemeMode.dark : ThemeMode.light))),
        const SizedBox(height: AppSpacing.lg),
        _sh('О приложении'),
        _info(Icons.info_outlined, 'Версия', '1.0.0'),
        _info(Icons.description_outlined, 'Лицензия', 'GPL-3.0'),
      ]),
    );
  }
  Widget _sh(String t) => Padding(padding: const EdgeInsets.only(left: 16, bottom: 8, top: 8), child: Text(t.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 1.2)));
  Widget _toggle(IconData i, String t, String s, bool v, ValueChanged<bool> cb) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.bgSurface, borderRadius: BorderRadius.circular(12)),
    child: Row(children: [Icon(i, color: AppColors.primary, size: 24), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: AppText.titleMedium(context)), Text(s, style: AppText.bodySmall(context))])), Switch(value: v, onChanged: cb, activeColor: AppColors.primary)]),
  );
  Widget _info(IconData i, String t, String s) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.bgSurface, borderRadius: BorderRadius.circular(12)),
    child: Row(children: [Icon(i, color: AppColors.textSecondary, size: 24), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: AppText.titleMedium(context)), Text(s, style: AppText.bodySmall(context))]))]),
  );
}
