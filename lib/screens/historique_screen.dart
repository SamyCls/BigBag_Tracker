import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/big_bag.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'bon_viewer_screen.dart';

/// Écran Historique : liste des bons d'expédition archivés, avec
/// possibilité de rouvrir/réimprimer chaque bon.
class HistoriqueScreen extends StatelessWidget {
  const HistoriqueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkOnDark : AppColors.ink;
    final mute = isDark ? AppColors.inkMuteDark : AppColors.inkMute;
    final done = app.terminatedChargements;
    final fmt = NumberFormat('#,##0', 'fr_FR');
    final dateFmt = DateFormat('dd MMM yyyy', 'fr_FR');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historique des expéditions',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                color: ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${done.length} bon(s) d\'expédition · archivés localement',
              style: TextStyle(fontSize: 20, color: mute, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: done.isEmpty
                  ? Center(
                      child: Text(
                        'Aucun chargement terminé',
                        style: TextStyle(color: mute, fontSize: 22),
                      ),
                    )
                  : ListView.separated(
                      itemCount: done.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, i) {
                        final c = done[i];
                        return FutureBuilder<List<BigBag>>(
                          future: app.bigBagsForBon(c.id),
                          builder: (context, snap) {
                            final bbs = snap.data ?? [];
                            final brut = bbs.fold(
                              0.0,
                              (s, b) => s + b.poidsBrut,
                            );
                            final net = brut - bbs.length * BigBag.tareKg;
                            return _HistRow(
                              bonNumero: c.bonNumero ?? '—',
                              date: c.closedAt != null
                                  ? dateFmt.format(c.closedAt!)
                                  : '—',
                              client: c.client,
                              camion: c.camion,
                              chauffeur: c.chauffeur,
                              nbBB: bbs.length,
                              brut: fmt.format(brut),
                              net: fmt.format(net),
                              onOpen: () => showDialog(
                                context: context,
                                builder: (_) =>
                                    BonViewerScreen(chargementId: c.id),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistRow extends StatelessWidget {
  final String bonNumero;
  final String date;
  final String client;
  final String? camion;
  final String? chauffeur;
  final int nbBB;
  final String brut;
  final String net;
  final VoidCallback onOpen;

  const _HistRow({
    required this.bonNumero,
    required this.date,
    required this.client,
    this.camion,
    this.chauffeur,
    required this.nbBB,
    required this.brut,
    required this.net,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.cardDark : AppColors.card;
    final line = isDark ? AppColors.lineDark : AppColors.line;
    final ink = isDark ? AppColors.inkOnDark : AppColors.ink;
    final mute = isDark ? AppColors.inkMuteDark : AppColors.inkMute;
    final leafTint = isDark
        ? AppColors.leafOnDark.withValues(alpha: 0.14)
        : AppColors.leafTint;
    final leafDark = isDark ? AppColors.leafOnDark : AppColors.leafDark;

    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 760;

    final content = isWide
        ? Row(
            children: [
              SizedBox(
                width: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bonNumero,
                      style: AppTextStyles.monoWeight(
                        22,
                        FontWeight.w800,
                        color: ink,
                      ),
                    ),
                    Text(date, style: TextStyle(fontSize: 17, color: mute, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: ink,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${camion ?? "—"} · ${chauffeur ?? "—"}',
                      style: TextStyle(fontSize: 17, color: mute, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              _stat('$nbBB', 'BB', ink, mute),
              const SizedBox(width: 24),
              _stat(brut, 'BRUT KG', ink, mute),
              const SizedBox(width: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: leafTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      net,
                      style: AppTextStyles.monoWeight(
                        28,
                        FontWeight.w800,
                        color: leafDark,
                      ),
                    ),
                    Text(
                      'NET KG',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: leafDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.print, size: 24),
                label: const Text('Rouvrir', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bonNumero,
                        style: AppTextStyles.monoWeight(
                          22,
                          FontWeight.w800,
                          color: ink,
                        ),
                      ),
                      Text(date, style: TextStyle(fontSize: 17, color: mute, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.print, size: 22),
                    label: const Text(
                      'Rouvrir',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                client,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${camion ?? "—"} · ${chauffeur ?? "—"}',
                style: TextStyle(fontSize: 17, color: mute, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _stat('$nbBB', 'BB', ink, mute),
                  const SizedBox(width: 20),
                  _stat(brut, 'BRUT KG', ink, mute),
                  const SizedBox(width: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: leafTint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          net,
                          style: AppTextStyles.monoWeight(
                            26,
                            FontWeight.w800,
                            color: leafDark,
                          ),
                        ),
                        Text(
                          'NET KG',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: leafDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: card,
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: content,
    );
  }

  Widget _stat(String value, String label, Color ink, Color mute) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.monoWeight(28, FontWeight.w800, color: ink),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: mute,
          ),
        ),
      ],
    );
  }
}
