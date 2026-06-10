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
        _pulseController.reset();
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
        return theme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = GlassTheme.of(context);
    final color = _getColor(theme);
    final isConnected = widget.state == VpnConnectionState.connected;
    final isConnecting = widget.state == VpnConnectionState.connecting ||
        widget.state == VpnConnectionState.reconnecting;

    return GestureDetector(
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _rotationController]),
        builder: (context, child) {
          return Transform.scale(
            scale: isConnected ? 1.0 + (_pulseController.value * 0.06) : 1.0,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isConnected
                      ? color.withValues(alpha: 0.5)
                      : color.withValues(alpha: 0.2),
                  width: isConnected ? 2.5 : 1.5,
                ),
              ),
              child: Center(
                child: isConnecting
                    ? RotationTransition(
                        turns: _rotationController,
                        child: Icon(
                          Icons.refresh,
                          size: widget.size * 0.28,
                          color: color,
                        ),
                      )
                    : Icon(
                        Icons.power_settings_new,
                        size: widget.size * 0.32,
                        color: color,
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
