import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/big_bag.dart';
import '../providers/app_provider.dart';
import '../providers/language_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/numeric_keypad.dart';
import '../utils/toast.dart';

/// Écran Production : création d'un nouveau Big Bag en 3 étapes max —
/// saisie du poids brut, choix qualité (optionnel), validation.
/// Aucun autre champ. L'ID est généré automatiquement.
class ProductionScreen extends StatefulWidget {
  const ProductionScreen({super.key});

  @override
  State<ProductionScreen> createState() => _ProductionScreenState();
}

class _ProductionScreenState extends State<ProductionScreen> {
  bool _entering = false;
  String _weight = '';
  DateTime _historyDate = DateTime.now();

  void _submit(AppProvider app) async {
    final cleanWeight = _weight.replaceAll(',', '.');
    final w = double.tryParse(cleanWeight);
    if (w == null || w < 50) return;
    final bb = await app.createBigBag(poidsBrut: w, qualite: Quality.clair);
    if (!mounted) return;
    showAppToast(
      context,
      '${bb.code} ${context.tr('prod_created')} · ${context.tr('prod_ecrire_sac')}',
    );
    setState(() {
      _weight = '';
      _entering = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkOnDark : AppColors.ink;
    final mute = isDark ? AppColors.inkMuteDark : AppColors.inkMute;
    final leaf = isDark ? AppColors.leafOnDark : AppColors.leaf;
    final leafDark = isDark ? AppColors.leafOnDark : AppColors.leafDark;
    final leafTint = isDark
        ? AppColors.leafOnDark.withValues(alpha: 0.14)
        : AppColors.leafTint;

    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 700;

    if (_entering) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _buildEntryForm(
            context,
            app,
            isWide,
            ink,
            mute,
            leaf,
            leafDark,
            leafTint,
          ),
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _buildHome(context, app, isWide, ink, mute, leaf),
      ),
    );
  }

  Widget _buildHome(
    BuildContext context,
    AppProvider app,
    bool isWide,
    Color ink,
    Color mute,
    Color leaf,
  ) {
    final now = DateTime.now();
    final selectedDate = _historyDate;
    final isToday =
        selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    final dateFmt = DateFormat('d MMMM yyyy', 'fr_FR');

    final recent = app.bigBags.where((b) {
      return b.createdAt.year == selectedDate.year &&
          b.createdAt.month == selectedDate.month &&
          b.createdAt.day == selectedDate.day;
    }).toList();

    final heading = isToday
        ? context.tr('prod_today')
        : '${context.tr('prod_from')} ${dateFmt.format(selectedDate)}';
    final emptyMsg = isToday
        ? context.tr('prod_empty_today')
        : context.tr('prod_empty_day');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            context.tr('prod_title'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              color: ink,
            ),
          ),
        ),
        if (isToday) ...[
          const SizedBox(height: 6),
          Center(
            child: Text(
              context.tr('prod_subtitle'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                color: mute,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        if (isToday)
          _TicketCta(onTap: () => setState(() => _entering = true), leaf: leaf)
        else
          _PastDayBanner(mute: mute),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  heading,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isToday
                        ? Colors.transparent
                        : leaf.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isToday ? mute.withValues(alpha: 0.35) : leaf,
                      width: isToday ? 1 : 1.5,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _historyDate,
                          firstDate: DateTime(2025),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => _historyDate = picked);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_month_rounded,
                              size: 20,
                              color: isToday ? mute : leaf,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isToday
                                  ? context.tr('prod_changer_date')
                                  : context.tr('prod_changer'),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isToday ? mute : leaf,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Text(
              '${recent.length} ${context.tr('prod_sacs')}',
              style: TextStyle(
                fontSize: 20,
                color: mute,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (recent.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                emptyMsg,
                style: TextStyle(color: mute, fontSize: 20),
              ),
            ),
          )
        else
          _RecentTable(bags: recent, ink: ink, mute: mute),
      ],
    );
  }

  Widget _buildEntryForm(
    BuildContext context,
    AppProvider app,
    bool isWide,
    Color ink,
    Color mute,
    Color leaf,
    Color leafDark,
    Color leafTint,
  ) {
    final cleanWeight = _weight.replaceAll(',', '.');
    final parsedWeight = double.tryParse(cleanWeight);
    final canSubmit = parsedWeight != null && parsedWeight >= 50;

    // ── shared header ─────────────────────────────────────────────────────
    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('prod_new'),
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${context.tr('prod_id_prevu')} : ${app.nextBBCode} · ${context.tr('prod_ecrire_sac')}',
                style: TextStyle(
                  fontSize: 19,
                  color: mute,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => setState(() {
            _entering = false;
            _weight = '';
          }),
          icon: const Icon(Icons.arrow_back, size: 22),
          label: Text(
            context.tr('back'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );

    // ── weight pad ────────────────────────────────────────────────────────
    Widget buildWeightPad({bool expandKeypad = true}) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WeightDisplay(weight: _weight, ink: ink, mute: mute),
        const SizedBox(height: 12),
        if (expandKeypad)
          Expanded(
            child: NumericKeypad(
              expand: true,
              onDigit: (d) => setState(() {
                if (d == ',') {
                  if (_weight.isEmpty) {
                    _weight = '0,';
                  } else if (!_weight.contains(',')) {
                    _weight += ',';
                  }
                } else {
                  if (_weight.contains(',')) {
                    final parts = _weight.split(',');
                    final after = parts.length > 1 ? parts[1] : '';
                    if (after.isEmpty) {
                      _weight += d;
                    }
                  } else {
                    if (_weight.length < 3) {
                      _weight += d;
                    }
                  }
                }
              }),
              onClear: () => setState(() => _weight = ''),
              onBackspace: () => setState(() {
                if (_weight.isNotEmpty) {
                  _weight = _weight.substring(0, _weight.length - 1);
                }
              }),
            ),
          )
        else
          SizedBox(
            height: 320,
            child: NumericKeypad(
              expand: true,
              onDigit: (d) => setState(() {
                if (d == ',') {
                  if (_weight.isEmpty) {
                    _weight = '0,';
                  } else if (!_weight.contains(',')) {
                    _weight += ',';
                  }
                } else {
                  if (_weight.contains(',')) {
                    final parts = _weight.split(',');
                    final after = parts.length > 1 ? parts[1] : '';
                    if (after.isEmpty) {
                      _weight += d;
                    }
                  } else {
                    if (_weight.length < 3) {
                      _weight += d;
                    }
                  }
                }
              }),
              onClear: () => setState(() => _weight = ''),
              onBackspace: () => setState(() {
                if (_weight.isNotEmpty) {
                  _weight = _weight.substring(0, _weight.length - 1);
                }
              }),
            ),
          ),
      ],
    );

    // ── validate + id chip ──────────────────────────────────────
    Widget buildRightPanel({bool expandButton = true}) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (expandButton) ...[
          const Spacer(flex: 2),
          SizedBox(
            height: 160,
            child: ElevatedButton(
              onPressed: canSubmit ? () => _submit(app) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: leaf,
                disabledBackgroundColor: leaf.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check, size: 48, color: Colors.white),
                    const SizedBox(width: 14),
                    Text(
                      context.tr('prod_valider'),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(flex: 3),
        ] else ...[
          SizedBox(
            height: 64,
            child: ElevatedButton(
              onPressed: canSubmit ? () => _submit(app) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: leaf,
                disabledBackgroundColor: leaf.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check, size: 28, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(
                      context.tr('prod_valider'),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: leafTint,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  context.tr('prod_id_auto'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: leafDark,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  app.nextBBCode,
                  style: AppTextStyles.monoWeight(
                    32,
                    FontWeight.w800,
                    color: leafDark,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  context.tr('prod_ecrire_sac'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: leafDark.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    // ── landscape: full-screen two-column ─────────────────────────────────
    if (isWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 6, child: buildWeightPad(expandKeypad: true)),
                const SizedBox(width: 16),
                Expanded(flex: 5, child: buildRightPanel(expandButton: true)),
              ],
            ),
          ),
        ],
      );
    }

    // ── portrait: scroll-free single-column ──────────────────────────────
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: 12),
        _WeightDisplay(weight: _weight, ink: ink, mute: mute),
        const SizedBox(height: 12),
        Expanded(
          child: NumericKeypad(
            expand: true,
            onDigit: (d) => setState(() {
              if (d == ',') {
                if (_weight.isEmpty) {
                  _weight = '0,';
                } else if (!_weight.contains(',')) {
                  _weight += ',';
                }
              } else {
                if (_weight.contains(',')) {
                  final parts = _weight.split(',');
                  final after = parts.length > 1 ? parts[1] : '';
                  if (after.isEmpty) {
                    _weight += d;
                  }
                } else {
                  if (_weight.length < 3) {
                    _weight += d;
                  }
                }
              }
            }),
            onClear: () => setState(() => _weight = ''),
            onBackspace: () => setState(() {
              if (_weight.isNotEmpty) {
                _weight = _weight.substring(0, _weight.length - 1);
              }
            }),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 64,
          child: ElevatedButton(
            onPressed: canSubmit ? () => _submit(app) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: leaf,
              disabledBackgroundColor: leaf.withValues(alpha: 0.35),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check, size: 28, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    context.tr('prod_valider'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: leafTint,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  context.tr('prod_id_auto'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: leafDark,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  app.nextBBCode,
                  style: AppTextStyles.monoWeight(
                    32,
                    FontWeight.w800,
                    color: leafDark,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  context.tr('prod_ecrire_sac'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: leafDark.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeightDisplay extends StatelessWidget {
  final String weight;
  final Color ink;
  final Color mute;
  const _WeightDisplay({
    required this.weight,
    required this.ink,
    required this.mute,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final leaf = isDark ? AppColors.leafOnDark : AppColors.leaf;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.card,
        border: Border.all(color: leaf, width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.tr('prod_poids'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: mute,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  weight.isEmpty ? '0' : weight,
                  style: AppTextStyles.monoWeight(
                    72,
                    FontWeight.w800,
                    color: weight.isEmpty ? mute : ink,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  context.tr('prod_kg'),
                  style: TextStyle(
                    fontSize: 28,
                    color: mute,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketCta extends StatelessWidget {
  final VoidCallback onTap;
  final Color leaf;
  const _TicketCta({required this.onTap, required this.leaf});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: leaf,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  '+',
                  style: TextStyle(
                    fontSize: 40,
                    color: Colors.white,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('prod_new'),
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.tr('prod_intro_subtitle'),
                      style: const TextStyle(
                        fontSize: 21,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white70,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Table des derniers Big Bags produits
// ---------------------------------------------------------------------------

class _PastDayBanner extends StatelessWidget {
  final Color mute;
  const _PastDayBanner({required this.mute});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: mute.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline_rounded, size: 32, color: mute),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              context.tr('prod_past_day_locked'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: mute,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentTable extends StatelessWidget {
  final List<BigBag> bags;
  final Color ink;
  final Color mute;

  const _RecentTable({
    required this.bags,
    required this.ink,
    required this.mute,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fmt = DateFormat('HH:mm', 'fr_FR');
    final weightFmt = NumberFormat('#,##0.##', 'fr_FR');

    // ── vivid status colours ─────────────────────────────────────────────
    Color rowBg(BigBagStatus s) => switch (s) {
      BigBagStatus.stock =>
        isDark ? const Color(0xFF1B4D2E) : const Color(0xFF2E7D32),
      BigBagStatus.charge =>
        isDark ? const Color(0xFF4D3800) : const Color(0xFFF57F17),
      BigBagStatus.expedie => const Color(0xFF881337),
    };

    Color rowFg(BigBagStatus s) => Colors.white;

    Color rowFgSub(BigBagStatus s) => Colors.white.withValues(alpha: 0.75);

    IconData statusIcon(BigBagStatus s) => switch (s) {
      BigBagStatus.stock => Icons.warehouse_rounded,
      BigBagStatus.charge => Icons.local_shipping_rounded,
      BigBagStatus.expedie => Icons.check_circle_rounded,
    };

    return Column(
      children: [
        for (var i = 0; i < bags.length; i++)
          GestureDetector(
            onTap: bags[i].status == BigBagStatus.expedie
                ? null
                : () => _showEditOptionsDialog(context, bags[i]),
            child: Container(
              margin: EdgeInsets.only(bottom: i < bags.length - 1 ? 10 : 0),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: rowBg(bags[i].status),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  // ── big bag number ──────────────────────────────────────
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${bags.length - i}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // ── code + time ─────────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bags[i].code,
                          style: AppTextStyles.monoWeight(
                            22,
                            FontWeight.w900,
                            color: rowFg(bags[i].status),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          fmt.format(bags[i].createdAt),
                          style: TextStyle(
                            fontSize: 15,
                            color: rowFgSub(bags[i].status),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ── weight ──────────────────────────────────────────────
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${weightFmt.format(bags[i].poidsBrut)} kg',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: rowFg(bags[i].status),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // ── status icon chip ────────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              statusIcon(bags[i].status),
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              switch (bags[i].status) {
                                BigBagStatus.stock => context.tr('st_stock'),
                                BigBagStatus.charge => context.tr('st_charge'),
                                BigBagStatus.expedie => context.tr('st_expedie'),
                              },
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showEditOptionsDialog(BuildContext context, BigBag bag) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Center(
            child: Text(
              context.tr('prod_edit_dialog_title'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
          ),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _showModifyWeightDialog(context, bag);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit, size: 36),
                      const SizedBox(height: 8),
                      Text(
                        context.tr('prod_edit_dialog_modify'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _showConfirmDeleteDialog(context, bag);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.delete, size: 36),
                      const SizedBox(height: 8),
                      Text(
                        context.tr('prod_edit_dialog_delete'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showConfirmDeleteDialog(BuildContext context, BigBag bag) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            context.tr('prod_confirm_delete_title'),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          content: Text(
            context.tr('prod_confirm_delete_body'),
            style: const TextStyle(fontSize: 18),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actionsPadding: const EdgeInsets.all(16),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                context.tr('cancel'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                _showSecondConfirmDeleteDialog(context, bag);
              },
              child: Text(
                context.tr('yes'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSecondConfirmDeleteDialog(BuildContext context, BigBag bag) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            context.tr('prod_confirm_delete_title'),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          content: Text(
            context.tr('prod_confirm_delete_body'),
            style: const TextStyle(fontSize: 18),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actionsPadding: const EdgeInsets.all(16),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                context.tr('cancel'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final app = context.read<AppProvider>();
                await app.deleteBigBag(bag.id);
                if (context.mounted) {
                  Navigator.of(ctx).pop();
                  showAppToast(context, context.tr('saved'));
                }
              },
              child: Text(
                context.tr('yes'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showModifyWeightDialog(BuildContext context, BigBag bag) {
    final controller = TextEditingController(text: bag.poidsBrut.toString());
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            context.tr('prod_modify_dialog_title'),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          content: Container(
            width: 320,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: TextField(
              controller: controller,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                suffixText: context.tr('kg'),
                suffixStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actionsPadding: const EdgeInsets.all(16),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                context.tr('cancel'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final text = controller.text.replaceAll(',', '.');
                final w = double.tryParse(text);
                if (w == null || w < 50) {
                  showAppToast(context, "Poids invalide (< 50)");
                  return;
                }
                Navigator.of(ctx).pop();
                _showConfirmSaveDialog(context, bag, w);
              },
              child: Text(
                context.tr('prod_save'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showConfirmSaveDialog(BuildContext context, BigBag bag, double newWeight) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            context.tr('prod_confirm_save_title'),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          content: Text(
            context.tr('prod_confirm_save_body'),
            style: const TextStyle(fontSize: 18),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actionsPadding: const EdgeInsets.all(16),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                context.tr('cancel'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final app = context.read<AppProvider>();
                await app.updateBigBagWeight(bag.id, newWeight);
                if (context.mounted) {
                  Navigator.of(ctx).pop();
                  showAppToast(context, context.tr('saved'));
                }
              },
              child: Text(
                context.tr('yes'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
