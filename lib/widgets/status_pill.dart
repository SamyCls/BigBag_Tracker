import 'package:flutter/material.dart';
import '../models/big_bag.dart';
import '../theme/app_theme.dart';

/// Petite pilule de statut colorée (EN STOCK / CHARGÉ / EXPÉDIÉ).
class StatusPill extends StatelessWidget {
  final BigBagStatus status;
  const StatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (bg, fg, dot) = switch (status) {
      BigBagStatus.stock => (
        isDark
            ? AppColors.leafOnDark.withValues(alpha: 0.16)
            : AppColors.leafTint,
        isDark ? AppColors.leafOnDark : AppColors.leafDark,
        isDark ? AppColors.leafOnDark : AppColors.leaf,
      ),
      BigBagStatus.charge => (
        isDark
            ? AppColors.sunOnDark.withValues(alpha: 0.16)
            : AppColors.sunTint,
        isDark ? AppColors.sunOnDark : AppColors.sun,
        isDark ? AppColors.sunOnDark : AppColors.sun,
      ),
      BigBagStatus.expedie => (
        isDark ? AppColors.cardAltDark : AppColors.cardAlt,
        isDark ? AppColors.inkMuteDark : AppColors.inkMute,
        isDark ? AppColors.inkDimDark : AppColors.inkDim,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
