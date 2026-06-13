import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late AnimationController _glowController;

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
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _updateAnimations();
  }

  void _updateAnimations() {
    if (widget.state == VpnConnectionState.connected) {
      _pulseController.repeat(reverse: true);
      _glowController.repeat(reverse: true);
      _rotationController.stop();
    } else if (widget.state == VpnConnectionState.connecting ||
        widget.state == VpnConnectionState.reconnecting) {
      _pulseController.stop();
      _pulseController.reset();
      _glowController.stop();
      _rotationController.repeat();
    } else {
      _pulseController.stop();
      _pulseController.reset();
      _glowController.stop();
      _glowController.reset();
      _rotationController.stop();
      _rotationController.reset();
    }
  }

  @override
  void didUpdateWidget(PowerButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state != oldWidget.state) _updateAnimations();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _glowController.dispose();
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
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onPressed();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _rotationController, _glowController]),
        builder: (context, child) {
          final glowOpacity = isConnected ? 0.15 + (_glowController.value * 0.15) : 0.0;
          return Transform.scale(
            scale: isConnected ? 1.0 + (_pulseController.value * 0.04) : 1.0,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glow effect
                if (isConnected)
                  Container(
                    width: widget.size + 30,
                    height: widget.size + 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: glowOpacity),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                // Main button
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        color.withValues(alpha: isConnected ? 0.15 : 0.05),
                        color.withValues(alpha: isConnected ? 0.05 : 0.02),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                    border: Border.all(
                      color: isConnected
                          ? color.withValues(alpha: 0.6)
                          : color.withValues(alpha: 0.2),
                      width: isConnected ? 2.5 : 1.5,
                    ),
                  ),
                  child: Center(
                    child: isConnecting
                        ? RotationTransition(
                            turns: _rotationController,
                            child: Icon(
                              Icons.refresh_rounded,
                              size: widget.size * 0.28,
                              color: color,
                            ),
                          )
                        : Icon(
                            Icons.power_settings_new_rounded,
                            size: widget.size * 0.32,
                            color: color,
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
