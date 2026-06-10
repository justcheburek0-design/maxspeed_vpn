import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/vpn_models.dart';

class PowerButton extends StatelessWidget {
  final VpnConnectionState state;
  final VoidCallback onPressed;
  const PowerButton({super.key, required this.state, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final connected = state == VpnConnectionState.connected;
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 180, height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: connected
              ? const LinearGradient(colors: [AppColors.success, Color(0xFF059669)], begin: Alignment.topLeft, end: Alignment.bottomRight)
              : const LinearGradient(colors: [AppColors.bgSurface, AppColors.bgSecondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: connected
              ? [BoxShadow(color: AppColors.success.withOpacity(0.4), blurRadius: 30, spreadRadius: 5)]
              : [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Center(child: Icon(Icons.power_settings_new_rounded, size: 72, color: connected ? Colors.white : AppColors.textMuted)),
      ),
    );
  }
}
