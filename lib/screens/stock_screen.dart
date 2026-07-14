import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/big_bag.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

/// Écran Stock : vue temps réel des Big Bags, filtres rapides, recherche
/// et totaux (nombre, poids en stock).
class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  BigBagStatus? _filter = BigBagStatus.stock;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkOnDark : AppColors.ink;
    final mute = isDark ? AppColors.inkMuteDark : AppColors.inkMute;
    final line = isDark ? AppColors.lineDark : AppColors.line;
    final fmt = NumberFormat('#,##0', 'fr_FR');
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');

    final filtered = app.filterBigBags(status: _filter, search: _search);

    const cols = ['ID', 'POIDS BRUT', 'QUALITÉ', 'CRÉÉ', 'STATUT'];
    const flexes = [3, 2, 2, 3, 2];

    Widget cell(String text, {bool bold = false, Color? color}) => Text(
          text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            color: color ?? (bold ? ink : mute),
            fontFamily: bold ? 'monospace' : null,
          ),
          overflow: TextOverflow.ellipsis,
        );

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row + search
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Stock Big Bags',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              color: ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Vue temps réel — synchronisée localement',
                            style: TextStyle(
                              fontSize: 21,
                              color: mute,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 260,
                      child: TextField(
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: 'Chercher BB-...',
                          hintStyle: TextStyle(fontSize: 18, color: mute),
                          prefixIcon: Icon(Icons.search, size: 22, color: mute),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: line),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: line),
                          ),
                        ),
                        onChanged: (v) => setState(() => _search = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Stat tiles ─────────────────────────────────────────
                Row(
                  children: [
                    _StatTile(label: 'EN STOCK', value: '${app.stockCount}', unit: 'BB', fmt: fmt),
                    const SizedBox(width: 12),
                    _StatTile(label: 'POIDS EN STOCK', value: fmt.format(app.stockPoidsTotal), unit: 'kg', fmt: fmt),
                    const SizedBox(width: 12),
                    _StatTile(label: 'CHARGÉS', value: '${app.chargeCount}', unit: 'BB', fmt: fmt),
                    const SizedBox(width: 12),
                    _StatTile(label: 'EXPÉDIÉS', value: '${app.expedieCount}', unit: 'BB', fmt: fmt),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Filter chips ────────────────────────────────────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Tous',
                        count: app.bigBags.length,
                        active: _filter == null,
                        onTap: () => setState(() => _filter = null),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'En stock',
                        count: app.stockCount,
                        active: _filter == BigBagStatus.stock,
                        onTap: () => setState(() => _filter = BigBagStatus.stock),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Chargés',
                        count: app.chargeCount,
                        active: _filter == BigBagStatus.charge,
                        onTap: () => setState(() => _filter = BigBagStatus.charge),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Expédiés',
                        count: app.expedieCount,
                        active: _filter == BigBagStatus.expedie,
                        onTap: () => setState(() => _filter = BigBagStatus.expedie),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Table header (fixed) ────────────────────────────────
                if (filtered.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: line, width: 1.5)),
                    ),
                    child: Row(
                      children: [
                        for (var i = 0; i < cols.length; i++)
                          Expanded(
                            flex: flexes[i],
                            child: Text(
                              cols[i],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: mute,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // ── Table body (scrollable) ───────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'Aucun Big Bag',
                      style: TextStyle(color: mute, fontSize: 20),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final bb = filtered[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: line, width: 0.8),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: flexes[0],
                              child: Text(
                                bb.code,
                                style: AppTextStyles.monoWeight(
                                  20,
                                  FontWeight.w800,
                                  color: ink,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: flexes[1],
                              child: cell('${bb.poidsBrut.toStringAsFixed(0)} kg'),
                            ),
                            Expanded(
                              flex: flexes[2],
                              child: cell(bb.qualite.label),
                            ),
                            Expanded(
                              flex: flexes[3],
                              child: cell(dateFmt.format(bb.createdAt)),
                            ),
                            Expanded(
                              flex: flexes[4],
                              child: _StatusBadge(status: bb.status),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Stat tile ──────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final NumberFormat fmt;

  const _StatTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.cardDark : AppColors.card;
    final line = isDark ? AppColors.lineDark : AppColors.line;
    final mute = isDark ? AppColors.inkMuteDark : AppColors.inkMute;
    final ink = isDark ? AppColors.inkOnDark : AppColors.ink;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: card,
          border: Border.all(color: line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: mute,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: AppTextStyles.monoWeight(36, FontWeight.w800, color: ink),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: mute,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter chip ────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkOnDark : AppColors.ink;
    final card = isDark ? AppColors.cardDark : AppColors.card;
    final line = isDark ? AppColors.lineDark : AppColors.line;
    final mute = isDark ? AppColors.inkMuteDark : AppColors.inkMute;

    return Material(
      color: active ? ink : card,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: active ? ink : line),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            '$label  $count',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: active ? (isDark ? AppColors.bgDark : Colors.white) : mute,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Status badge ───────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final BigBagStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (bg, fg) = switch (status) {
      BigBagStatus.stock => (
          isDark
              ? AppColors.leafOnDark.withValues(alpha: 0.16)
              : AppColors.leafTint,
          isDark ? AppColors.leafOnDark : AppColors.leafDark,
        ),
      BigBagStatus.charge => (
          isDark
              ? AppColors.sunOnDark.withValues(alpha: 0.16)
              : AppColors.sunTint,
          isDark ? AppColors.sunOnDark : AppColors.sun,
        ),
      BigBagStatus.expedie => (
          isDark ? AppColors.cardAltDark : AppColors.cardAlt,
          isDark ? AppColors.inkMuteDark : AppColors.inkMute,
        ),
    };

    final label = switch (status) {
      BigBagStatus.stock => 'EN STOCK',
      BigBagStatus.charge => 'CHARGÉ',
      BigBagStatus.expedie => 'EXPÉDIÉ',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
