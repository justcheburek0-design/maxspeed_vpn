import 'package:flutter/material.dart';
import '../core/theme/app_themes.dart';

/// Показывает уведомление сверху экрана, тёмное, не на всю ширину.
void showAppNotification(BuildContext context, String message,
    {bool isError = false, Duration duration = const Duration(seconds: 2)}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, -20 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: child,
        ),
      ),
    ),
  );
  final content = Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: isError
          ? const Color(0xFF3D1A1A)
          : const Color(0xFF0A0A0D),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isError
            ? const Color(0xFFFF7043).withOpacity(0.3)
            : const Color(0xFF2A4A00).withOpacity(0.5),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.4),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
          color: isError
              ? const Color(0xFFFF7043)
              : const Color(0xFFA8E63D),
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              color: isError
                  ? const Color(0xFFFFDAD6)
                  : const Color(0xFFE4E3D9),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );

  // Re-create with the content
  entry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, -20 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: content,
        ),
      ),
    ),
  );
  overlay.insert(entry);

  Future.delayed(duration, () {
    entry.remove();
  });
}
