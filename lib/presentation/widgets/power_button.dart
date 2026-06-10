import 'package:flutter/material.dart';
import '../../core/theme/app_themes.dart';
import '../../data/models/vpn_models.dart';

class PowerButton extends StatefulWidget {
  final VpnConnectionState state;
  final VoidCallback onPressed;
  final double size;
  const PowerButton({super.key, required this.state, required this.onPressed, this.size = 140});
  @override State<PowerButton> createState() => _PowerButtonState();
}

class _PowerButtonState extends State<PowerButton> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _rotateController = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    if (widget.state.isConnecting) {
      _pulseController.repeat(reverse: true);
      _rotateController.repeat();
    }
  }

  @override
  void didUpdateWidget(PowerButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.isConnecting) {
      _pulseController.repeat(reverse: true);
      _rotateController.repeat();
    } else {
      _pulseController.stop();
      _pulseController.reset();
      _rotateController.stop();
      _rotateController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = GlassTheme.of(context);
    final color = _color(theme);
    return GestureDetector(
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnim, _rotateController]),
        builder: (context, child) {
          return Transform.scale(
            scale: widget.state.isConnecting ? _pulseAnim.value : 1.0,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withValues(alpha: 0.3),
                    color.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 30, spreadRadius: 5),
                  BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 60, spreadRadius: 10),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [theme.bgSurface, theme.bgSecondary],
                  ),
                  border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
                ),
                child: Center(
                  child: Icon(
                    widget.state == VpnConnectionState.connected
                      ? Icons.power_settings_new
                      : Icons.power_settings_new_outlined,
                    size: widget.size * 0.35,
                    color: color,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _color(AppTheme theme) {
    switch (widget.state) {
      case VpnConnectionState.connected: return theme.success;
      case VpnConnectionState.connecting: return theme.warning;
      case VpnConnectionState.error: return theme.error;
      default: return theme.primary;
    }
  }
}
