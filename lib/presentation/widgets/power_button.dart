import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_themes.dart';
import '../../data/models/vpn_models.dart';

class PowerButton extends StatefulWidget {
  final VpnConnectionState state;
  final VoidCallback onPressed;
  final double size;

  const PowerButton({
    super.key,
    required this.state,
    required this.onPressed,
    this.size = 150,
  });

  @override
  State<PowerButton> createState() => _PowerButtonState();
}

class _PowerButtonState extends State<PowerButton> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.state == VpnConnectionState.connected) {
      _pulseController.repeat(reverse: true);
    }
    if (widget.state == VpnConnectionState.connecting) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(PowerButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state != oldWidget.state) {
      if (widget.state == VpnConnectionState.connected) {
        _pulseController.repeat(reverse: true);
        _rotationController.stop();
      } else if (widget.state == VpnConnectionState.connecting) {
        _pulseController.stop();
        _rotationController.repeat();
      } else {
        _pulseController.stop();
        _pulseController.reset();
        _rotationController.stop();
        _rotationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Color _getColor(AppTheme theme) {
    switch (widget.state) {
      case VpnConnectionState.connected:
        return theme.success;
      case VpnConnectionState.connecting:
      case VpnConnectionState.reconnecting:
        return theme.warning;
      case VpnConnectionState.error:
        return theme.error;
      default:
        return theme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = GlassTheme.of(context);
    final color = _getColor(theme);
    final isConnecting = widget.state == VpnConnectionState.connecting ||
        widget.state == VpnConnectionState.reconnecting;

    return GestureDetector(
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _rotationController]),
        builder: (context, child) {
          return Transform.scale(
            scale: widget.state == VpnConnectionState.connected
                ? _pulseAnimation.value
                : 1.0,
            child: child,
          );
        },
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow ring
              if (widget.state == VpnConnectionState.connected)
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
              // Main circle
              Container(
                width: widget.size - 10,
                height: widget.size - 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      color.withValues(alpha: 0.2),
                      color.withValues(alpha: 0.05),
                    ],
                  ),
                  border: Border.all(
                    color: color.withValues(alpha: 0.5),
                    width: 2.5,
                  ),
                ),
                child: Center(
                  child: isConnecting
                      ? AnimatedBuilder(
                          animation: _rotationController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _rotationController.value * 2 * math.pi,
                              child: child,
                            );
                          },
                          child: Icon(
                            Icons.refresh,
                            size: widget.size * 0.3,
                            color: color,
                          ),
                        )
                      : Icon(
                          Icons.power_settings_new,
                          size: widget.size * 0.35,
                          color: color,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
