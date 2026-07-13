import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../models/big_bag.dart';
import '../theme/app_theme.dart';
import 'status_pill.dart';

/// Carte "ticket" représentant un Big Bag (ID, poids, qualité, statut).
class BigBagCard extends StatelessWidget {
  final BigBag bb;
  const BigBagCard({super.key, required this.bb});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final line = isDark ? AppColors.lineDark : AppColors.line;
    final card = isDark ? AppColors.cardDark : AppColors.card;
    final ink = isDark ? AppColors.inkOnDark : AppColors.ink;
    final mute = isDark ? AppColors.inkMuteDark : AppColors.inkMute;
    final dim = isDark ? AppColors.inkDimDark : AppColors.inkDim;

    final stripe = switch (bb.status) {
      BigBagStatus.stock => isDark ? AppColors.leafOnDark : AppColors.leaf,
      BigBagStatus.charge => isDark ? AppColors.sunOnDark : AppColors.sun,
      BigBagStatus.expedie => dim,
    };

    final fmt = NumberFormat('#,##0', 'fr_FR');
    final dtFmt = DateFormat('dd MMM HH:mm', 'fr_FR');

    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: line),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(color: stripe),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        bb.code,
                        style: AppTextStyles.monoWeight(
                          19,
                          FontWeight.w800,
                          color: ink,
                        ),
                      ),
                    ),
                    StatusPill(status: bb.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${fmt.format(bb.poidsBrut)} kg · ${bb.qualite.label}',
                  style: AppTextStyles.monoWeight(
                    14,
                    FontWeight.w600,
                    color: mute,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  dtFmt.format(bb.createdAt),
                  style: TextStyle(fontSize: 11, color: dim),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
