import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_themes.dart';

/// Lightweight glass-style container — Material3 tonal surface
/// Replaces heavy BackdropFilter with simple surface tint (INCY style)
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 12,
    this.color,
    this.borderColor,
    this.borderWidth = 1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = GlassTheme.of(context);
    final bg = color ?? theme.surface;
    final border = borderColor ?? theme.outlineVariant;

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: bg,
        border: Border.all(color: border, width: borderWidth),
      ),
      child: child,
    );
  }
}
