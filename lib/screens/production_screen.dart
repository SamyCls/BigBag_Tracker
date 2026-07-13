import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/big_bag.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/big_bag_card.dart';
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
    final isWide = width >= 800;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _entering
            ? _buildEntryForm(
                context,
                app,
                isWide,
                ink,
                mute,
                leaf,
                leafDark,
                leafTint,
              )
            : _buildHome(context, app, isWide, ink, mute, leaf),
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
                    'Production',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tapez pour créer un nouveau Big Bag · pesée manuelle',
                    style: TextStyle(fontSize: 13, color: mute),
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
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
            Text(
              '${recent.length} tickets',
              style: TextStyle(fontSize: 13, color: mute),
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
                style: TextStyle(color: mute),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 260,
              mainAxisExtent: 108,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: recent.length,
            itemBuilder: (context, i) => BigBagCard(bb: recent[i]),
          ),
      ],
    );
  }

  Widget _nextIdChip(AppProvider app, Color leaf, Color ink, Color mute) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      constraints: const BoxConstraints(minWidth: 160),
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
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: mute,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            app.nextBBCode,
            style: AppTextStyles.monoWeight(22, FontWeight.w800, color: leaf),
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

    final weightPad = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WeightDisplay(weight: _weight, ink: ink, mute: mute),
        const SizedBox(height: 12),
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
        const SizedBox(height: 12),
        NumericKeypad(
          onDigit: (d) => setState(() {
            if (_weight.length < 5) _weight += d;
          }),
          onClear: () => setState(() => _weight = ''),
          onBackspace: () => setState(() {
            if (_weight.isNotEmpty)
              _weight = _weight.substring(0, _weight.length - 1);
          }),
        ),
      ],
    );

    final rightPanel = Column(
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
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: mute,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
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
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
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
                Icon(Icons.check, size: 26, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  'VALIDER',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
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
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: leafDark,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                app.nextBBCode,
                style: AppTextStyles.monoWeight(
                  28,
                  FontWeight.w800,
                  color: leafDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Écrire ce numéro sur le sac',
                style: TextStyle(
                  fontSize: 12,
                  color: leafDark.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );

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
                    'Nouveau Big Bag',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID prévu : ${app.nextBBCode} · écrivez ce numéro au marqueur sur le sac',
                    style: TextStyle(fontSize: 13, color: mute),
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => setState(() {
                _entering = false;
                _weight = '';
              }),
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Annuler'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: weightPad),
              const SizedBox(width: 20),
              Expanded(flex: 5, child: rightPanel),
            ],
          )
        else
          Column(children: [weightPad, const SizedBox(height: 20), rightPanel]),
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
              fontSize: 12,
              fontWeight: FontWeight.w700,
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
                  64,
                  FontWeight.w800,
                  color: weight.isEmpty ? mute : ink,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'kg',
                style: TextStyle(
                  fontSize: 20,
                  color: mute,
                  fontWeight: FontWeight.w600,
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
            style: AppTextStyles.monoWeight(15, FontWeight.w700),
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
              fontSize: 13,
              fontWeight: FontWeight.w700,
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
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Pesée · qualité · validation en 3 taps',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
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
