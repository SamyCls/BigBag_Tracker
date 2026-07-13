import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Affiche un toast en haut de l'écran (succès par défaut, erreur en option) —
/// reprend le comportement des toasts du design original.
void showAppToast(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  final overlay = Overlay.of(context);
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final bg = isError
      ? (isDark ? AppColors.clayOnDark : AppColors.clay)
      : (isDark ? AppColors.leafOnDark : AppColors.leaf);
  final fg = isError ? Colors.white : Colors.white;

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => Positioned(
      top: 24,
      left: 0,
      right: 0,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isError ? Icons.warning_amber_rounded : Icons.check_circle,
                  color: fg,
                  size: 18,
                ),
                const SizedBox(width: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Text(
                    message,
                    style: TextStyle(color: fg, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);
  Future.delayed(const Duration(milliseconds: 2200), () {
    entry.remove();
  });
}
