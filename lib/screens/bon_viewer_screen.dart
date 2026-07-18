import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/big_bag.dart';
import '../models/chargement.dart';
import '../providers/app_provider.dart';
import '../providers/language_provider.dart';
import '../theme/app_theme.dart';
import '../utils/share_bon.dart';

/// Affiche le bon d'expédition généré automatiquement à la fin d'un
/// chargement, avec bouton Imprimer/PDF (utilise le plugin `printing`).
class BonViewerScreen extends StatefulWidget {
  final int chargementId;
  const BonViewerScreen({super.key, required this.chargementId});

  @override
  State<BonViewerScreen> createState() => _BonViewerScreenState();
}

class _BonViewerScreenState extends State<BonViewerScreen> {
  Chargement? _chargement;
  List<BigBag> _bigBags = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final app = context.read<AppProvider>();
    final matches = [
      ...app.activeChargements,
      ...app.terminatedChargements,
    ].where((c) => c.id == widget.chargementId);
    final ch = matches.isEmpty ? null : matches.first;
    final bbs = await app.bigBagsForBon(widget.chargementId);
    if (!mounted) return;
    setState(() {
      _chargement = ch;
      _bigBags = bbs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    context.watch<LanguageProvider>();

    if (_loading || _chargement == null) {
      return const Dialog(
        child: SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final ch = _chargement!;
    final fmt = NumberFormat('#,##0.##', 'fr_FR');
    final dtFmt = DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR');
    final brut = _bigBags.fold(0.0, (s, b) => s + b.poidsBrut);
    final tare = _bigBags.length * BigBag.tareKg;
    final net = brut - tare;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 900),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.ink,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 16,
                    ),
                    label: Text(
                      context.tr('close'),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "${context.tr('bon_title')} · ${ch.bonNumero ?? ''}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => shareBon(
                      chargement: ch,
                      bigBags: _bigBags,
                    ),
                    icon: const Icon(Icons.share, size: 16),
                    label: Text(context.tr('bon_share')),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                'assets/icon/logorecycle.png',
                                width: 80,
                                height: 80,
                              ),
                              const SizedBox(width: 12),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Delta Recycl',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Text(
                                    'Recyclage PET',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.inkMute,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Bon d\'expédition',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              Text(
                                '${ch.bonNumero ?? ""} · ${DateFormat('dd MMM yyyy', 'fr_FR').format(ch.closedAt ?? DateTime.now())}',
                                style: AppTextStyles.monoWeight(
                                  12,
                                  FontWeight.w500,
                                  color: AppColors.inkMute,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF8F2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 4.5,
                          children: [
                            _meta('CLIENT', ch.client),
                            _meta(
                              'DATE',
                              dtFmt.format(ch.closedAt ?? DateTime.now()),
                            ),
                            _meta('CAMION', ch.camion ?? '—'),
                            _meta('CHAUFFEUR', ch.chauffeur ?? '—'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Table(
                        columnWidths: const {0: FixedColumnWidth(40)},
                        children: [
                          TableRow(
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  width: 2,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            children: [
                              const _Th('#'),
                              const _Th('ID BIG BAG'),
                              const _Th('POIDS BRUT', alignRight: true),
                            ],
                          ),
                          ..._bigBags.asMap().entries.map(
                            (e) => TableRow(
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    width: 1,
                                    color: AppColors.line,
                                  ),
                                ),
                              ),
                              children: [
                                _Td('${e.key + 1}'),
                                _Td(e.value.code, bold: true),
                                _Td(
                                  '${fmt.format(e.value.poidsBrut)} kg',
                                  alignRight: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.ink,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _totalRow(
                              'Nombre de Big Bags',
                              '${_bigBags.length}',
                            ),
                            _totalRow(
                              'Poids brut total',
                              '${fmt.format(brut)} kg',
                            ),
                            _totalRow(
                              'Tare totale (3 x ${_bigBags.length})',
                              '- ${fmt.format(tare)} kg',
                            ),
                            const Divider(
                              color: AppColors.leaf,
                              thickness: 1.5,
                              height: 20,
                            ),
                            _totalRow(
                              'Poids net',
                              '${fmt.format(net)} kg',
                              big: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 36),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(color: AppColors.ink),
                                Text(
                                  'Signature Delta Recycl',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.inkMute,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 30),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(color: AppColors.ink),
                                const Text(
                                  'Signature transporteur',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.inkMute,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _meta(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.inkMute,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _totalRow(String label, String value, {bool big = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.white, fontSize: big ? 15 : 13),
          ),
          Text(
            value,
            style: AppTextStyles.monoWeight(
              big ? 22 : 15,
              FontWeight.w800,
              color: big ? AppColors.leafOnDark : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _Th extends StatelessWidget {
  final String text;
  final bool alignRight;
  const _Th(this.text, {this.alignRight = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
    child: Text(
      text,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    ),
  );
}

class _Td extends StatelessWidget {
  final String text;
  final bool bold;
  final bool alignRight;
  const _Td(this.text, {this.bold = false, this.alignRight = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
    child: Text(
      text,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: AppTextStyles.monoWeight(
        13,
        bold ? FontWeight.w800 : FontWeight.w400,
      ),
    ),
  );
}
