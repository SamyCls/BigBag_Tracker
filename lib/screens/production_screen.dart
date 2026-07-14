import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/big_bag.dart';
import '../providers/app_provider.dart';
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
  Quality _quality = Quality.clair;

  void _submit(AppProvider app) async {
    final w = int.tryParse(_weight);
    if (w == null || w < 50) return;
    final bb = await app.createBigBag(
      poidsBrut: w.toDouble(),
      qualite: _quality,
    );
    if (!mounted) return;
    showAppToast(context, '${bb.code} créé · écrire ce numéro sur le sac');
    setState(() {
      _weight = '';
      _quality = Quality.clair;
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
    final isWide = width >= 980;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    if (_entering) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _buildEntryForm(
            context,
            app,
            isWide && isLandscape,
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
    final recent = app.recentBigBags();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Production Big Bag',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tapez pour créer un nouveau Big Bag · pesée manuelle',
                    style: TextStyle(fontSize: 21, color: mute, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            if (isWide) _nextIdChip(app, leaf, ink, mute),
          ],
        ),
        if (!isWide)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _nextIdChip(app, leaf, ink, mute),
          ),
        const SizedBox(height: 20),
        _TicketCta(onTap: () => setState(() => _entering = true), leaf: leaf),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Derniers produits',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: ink,
              ),
            ),
            Text(
              '${recent.length} derniers',
              style: TextStyle(fontSize: 20, color: mute, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (recent.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'Aucun Big Bag produit pour le moment',
                style: TextStyle(color: mute, fontSize: 20),
              ),
            ),
          )
        else
          _RecentTable(bags: recent, ink: ink, mute: mute),
      ],
    );
  }

  Widget _nextIdChip(AppProvider app, Color leaf, Color ink, Color mute) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      constraints: const BoxConstraints(minWidth: 180),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.card,
        border: Border.all(color: isDark ? AppColors.lineDark : AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'PROCHAIN ID',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: mute,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            app.nextBBCode,
            style: AppTextStyles.monoWeight(32, FontWeight.w800, color: leaf),
          ),
        ],
      ),
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
    final canSubmit = int.tryParse(_weight) != null && int.parse(_weight) >= 50;

    // ── shared header ─────────────────────────────────────────────────────
    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nouveau Big Bag',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ID prévu : ${app.nextBBCode} · écrivez ce numéro au marqueur sur le sac',
                style: TextStyle(fontSize: 19, color: mute, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => setState(() {
            _entering = false;
            _weight = '';
            _quality = Quality.clair;
          }),
          icon: const Icon(Icons.arrow_back, size: 22),
          label: const Text('Retour', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ),
      ],
    );

    // ── weight pad ────────────────────────────────────────────────────────
    Widget buildWeightPad({bool expandKeypad = true}) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WeightDisplay(weight: _weight, ink: ink, mute: mute),
        const SizedBox(height: 10),
        Row(
          children: [500, 550, 600, 650, 700]
              .map(
                (v) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _SuggestionButton(
                      value: v,
                      onTap: () => setState(() => _weight = '$v'),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 10),
        if (expandKeypad)
          Expanded(
            child: NumericKeypad(
              expand: true,
              onDigit: (d) => setState(() {
                if (_weight.length < 5) _weight += d;
              }),
              onClear: () => setState(() => _weight = ''),
              onBackspace: () => setState(() {
                if (_weight.isNotEmpty)
                  _weight = _weight.substring(0, _weight.length - 1);
              }),
            ),
          )
        else
          SizedBox(
            height: 320,
            child: NumericKeypad(
              expand: true,
              onDigit: (d) => setState(() {
                if (_weight.length < 5) _weight += d;
              }),
              onClear: () => setState(() => _weight = ''),
              onBackspace: () => setState(() {
                if (_weight.isNotEmpty)
                  _weight = _weight.substring(0, _weight.length - 1);
              }),
            ),
          ),
      ],
    );

    // ── quality + validate + id chip ──────────────────────────────────────
    Widget buildRightPanel({bool expandButton = true}) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.cardDark
                : AppColors.card,
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.lineDark
                  : AppColors.line,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'QUALITÉ',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: mute,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: Quality.values
                    .map(
                      (q) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _QualityOption(
                            quality: q,
                            selected: _quality == q,
                            onTap: () => setState(() => _quality = q),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (expandButton)
          Expanded(
            child: ElevatedButton(
              onPressed: canSubmit ? () => _submit(app) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: leaf,
                disabledBackgroundColor: leaf.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.check, size: 42, color: Colors.white),
                  SizedBox(width: 14),
                  Text(
                    'VALIDER',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 90,
            child: ElevatedButton(
              onPressed: canSubmit ? () => _submit(app) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: leaf,
                disabledBackgroundColor: leaf.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.check, size: 36, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    'VALIDER',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: leafTint,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Text(
                'ID GÉNÉRÉ AUTOMATIQUEMENT',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: leafDark,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                app.nextBBCode,
                style: AppTextStyles.monoWeight(
                  40,
                  FontWeight.w800,
                  color: leafDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Écrire ce numéro sur le sac',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: leafDark.withValues(alpha: 0.8),
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
          const SizedBox(height: 14),
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

    // ── portrait: scrollable single-column ────────────────────────────────
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 16),
          buildWeightPad(expandKeypad: false),
          const SizedBox(height: 16),
          buildRightPanel(expandButton: false),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.card,
        border: Border.all(color: leaf, width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            'POIDS BRUT',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: mute,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                weight.isEmpty ? '0' : weight,
                style: AppTextStyles.monoWeight(
                  96,
                  FontWeight.w800,
                  color: weight.isEmpty ? mute : ink,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'kg',
                style: TextStyle(
                  fontSize: 32,
                  color: mute,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SuggestionButton extends StatelessWidget {
  final int value;
  final VoidCallback onTap;
  const _SuggestionButton({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.cardDark : AppColors.card,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? AppColors.lineDark : AppColors.line,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: Text(
            '$value',
            style: AppTextStyles.monoWeight(26, FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

class _QualityOption extends StatelessWidget {
  final Quality quality;
  final bool selected;
  final VoidCallback onTap;
  const _QualityOption({
    required this.quality,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final leaf = isDark ? AppColors.leafOnDark : AppColors.leaf;
    final leafTint = isDark
        ? AppColors.leafOnDark.withValues(alpha: 0.16)
        : AppColors.leafTint;
    final leafDark = isDark ? AppColors.leafOnDark : AppColors.leafDark;
    final line = isDark ? AppColors.lineDark : AppColors.line;
    final mute = isDark ? AppColors.inkMuteDark : AppColors.inkMute;

    return Material(
      color: selected
          ? leafTint
          : (isDark ? AppColors.cardDark : AppColors.card),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: selected ? leaf : line, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            quality.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: selected ? leafDark : mute,
            ),
          ),
        ),
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NOUVEAU BIG BAG',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Pesée · qualité · validation en 3 taps',
                      style: TextStyle(
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
    final card = isDark ? AppColors.cardDark : AppColors.card;
    final line = isDark ? AppColors.lineDark : AppColors.line;
    final fmt = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');

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

    return Container(
      decoration: BoxDecoration(
        color: card,
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: line)),
            ),
            child: Row(
              children: [
                for (var i = 0; i < cols.length; i++) ...[
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
              ],
            ),
          ),
          // Data rows
          for (var i = 0; i < bags.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                border: i < bags.length - 1
                    ? Border(bottom: BorderSide(color: line, width: 0.8))
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: flexes[0],
                    child: Text(
                      bags[i].code,
                      style: AppTextStyles.monoWeight(20, FontWeight.w800, color: ink),
                    ),
                  ),
                  Expanded(
                    flex: flexes[1],
                    child: cell('${bags[i].poidsBrut.toStringAsFixed(0)} kg'),
                  ),
                  Expanded(
                    flex: flexes[2],
                    child: cell(bags[i].qualite.label),
                  ),
                  Expanded(
                    flex: flexes[3],
                    child: cell(fmt.format(bags[i].createdAt)),
                  ),
                  Expanded(
                    flex: flexes[4],
                    child: _StatusBadge(status: bags[i].status),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

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
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
