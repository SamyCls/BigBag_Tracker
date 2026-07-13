import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/big_bag.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/big_bag_card.dart';

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
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 700;
    final fmt = NumberFormat('#,##0', 'fr_FR');

    final filtered = app.filterBigBags(status: _filter, search: _search);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stock temps réel',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Vue synchronisée · base locale hors-ligne',
              style: TextStyle(fontSize: 13, color: mute),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Chercher BB-…',
                prefixIcon: Icon(Icons.search, size: 18),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final cols = isWide ? 4 : 2;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: cols,
                  childAspectRatio: 1.6,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: [
                    _StatTile(
                      label: 'En stock',
                      value: '${app.stockCount}',
                      unit: 'BB',
                      accent: true,
                    ),
                    _StatTile(
                      label: 'Poids en stock',
                      value: fmt.format(app.stockPoidsTotal),
                      unit: 'kg',
                    ),
                    _StatTile(
                      label: 'Chargés',
                      value: '${app.chargeCount}',
                      valueColor: AppColors.sun,
                    ),
                    _StatTile(
                      label: 'Expédiés',
                      value: '${app.expedieCount}',
                      valueColor: mute,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
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
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'Aucun Big Bag',
                        style: TextStyle(color: mute),
                      ),
                    )
                  : GridView.builder(
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 260,
                        mainAxisExtent: 108,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) => BigBagCard(bb: filtered[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final bool accent;
  final Color? valueColor;
  const _StatTile({
    required this.label,
    required this.value,
    this.unit,
    this.accent = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final leaf = isDark ? AppColors.leafOnDark : AppColors.leaf;
    final leafTint = isDark
        ? AppColors.leafOnDark.withValues(alpha: 0.14)
        : AppColors.leafTint;
    final leafDark = isDark ? AppColors.leafOnDark : AppColors.leafDark;
    final card = isDark ? AppColors.cardDark : AppColors.card;
    final line = isDark ? AppColors.lineDark : AppColors.line;
    final mute = isDark ? AppColors.inkMuteDark : AppColors.inkMute;
    final ink = isDark ? AppColors.inkOnDark : AppColors.ink;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent ? leafTint : card,
        border: accent ? null : Border.all(color: line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: accent ? leafDark : mute,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppTextStyles.monoWeight(
                  24,
                  FontWeight.w800,
                  color: accent ? leaf : (valueColor ?? ink),
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Text(
                  unit!,
                  style: TextStyle(
                    fontSize: 12,
                    color: accent ? leafDark : mute,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

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
    final paper = isDark ? AppColors.paperDark : AppColors.ink;
    final card = isDark ? AppColors.cardDark : AppColors.card;
    final line = isDark ? AppColors.lineDark : AppColors.line;
    final mute = isDark ? AppColors.inkMuteDark : AppColors.inkMute;

    return Material(
      color: active ? ink : card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: active ? ink : line),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active ? paper : mute,
                  ),
                ),
                TextSpan(
                  text: '  $count',
                  style: TextStyle(
                    fontSize: 11,
                    color: active
                        ? paper.withValues(alpha: 0.7)
                        : mute.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
