import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_themes.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? opacity;
  final double? blur;
  final BorderRadius? borderRadius;
  final Color? tint;
  final Color? borderColor;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const GlassContainer({
    super.key, required this.child, this.opacity, this.blur,
    this.borderRadius, this.tint, this.borderColor,
    this.padding, this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = GlassTheme.of(context);
    final effectiveOpacity = opacity ?? theme.glassOpacity;
    final effectiveBlur = blur ?? theme.glassBlur;
    final effectiveTint = tint ?? theme.primary.withValues(alpha: 0.05);
    final effectiveBorder = borderColor ?? theme.primary.withValues(alpha: 0.1);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: Border.all(color: effectiveBorder.withValues(alpha: effectiveOpacity)),
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: effectiveBlur, sigmaY: effectiveBlur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: borderRadius ?? BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  effectiveTint.withValues(alpha: effectiveOpacity),
                  effectiveTint.withValues(alpha: effectiveOpacity * 0.3),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
