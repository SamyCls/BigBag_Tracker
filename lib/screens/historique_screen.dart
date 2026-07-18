import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/big_bag.dart';
import '../providers/app_provider.dart';
import '../providers/language_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/bb_code_keypad.dart';
import 'bon_viewer_screen.dart';

/// Écran Historique : liste des bons d'expédition archivés, avec
/// possibilité de rouvrir/réimprimer chaque bon.
class HistoriqueScreen extends StatefulWidget {
  const HistoriqueScreen({super.key});

  @override
  State<HistoriqueScreen> createState() => _HistoriqueScreenState();
}

class _HistoriqueScreenState extends State<HistoriqueScreen> {
  // 8-digit buffer for BE-YYYY-NNNN search (first 4 = year, last 4 = number)
  String _digits = '00000000';
  bool _showSearchPad = false;
  DateTime? _selectedDate;
  String? _quickFilter; // 'week' | 'month' | null

  // Pre-loaded big bags per terminated chargement — avoids FutureBuilder per row
  final Map<int, List<BigBag>> _bonBags = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadMissingBags();
  }

  Future<void> _loadMissingBags() async {
    final app = context.read<AppProvider>();
    final missing = app.terminatedChargements
        .where((c) => !_bonBags.containsKey(c.id))
        .toList();
    if (missing.isEmpty) return;
    final newEntries = <int, List<BigBag>>{};
    for (final c in missing) {
      newEntries[c.id] = await app.bigBagsForBon(c.id);
    }
    if (mounted && newEntries.isNotEmpty) {
      setState(() => _bonBags.addAll(newEntries));
    }
  }

  void _onKeyTap(String digit) {
    setState(() {
      _digits = (_digits + digit).substring(1).padLeft(8, '0');
    });
  }

  void _onBackspace() {
    setState(() {
      if (_digits == '00000000') return;
      _digits = '0${_digits.substring(0, 7)}';
    });
  }

  void _onClear() {
    setState(() => _digits = '00000000');
  }

  void _toggleSearchPad() {
    setState(() {
      _showSearchPad = !_showSearchPad;
      if (!_showSearchPad) _digits = '00000000';
    });
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: Locale(context.read<LanguageProvider>().languageCode),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _quickFilter = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkOnDark : AppColors.ink;
    final mute = isDark ? AppColors.inkMuteDark : AppColors.inkMute;
    final line = isDark ? AppColors.lineDark : AppColors.line;
    final leaf = isDark ? AppColors.leafOnDark : AppColors.leaf;
    final card = isDark ? AppColors.cardDark : AppColors.card;
    final fmt = NumberFormat('#,##0.##', 'fr_FR');
    final dateFmt = DateFormat('dd MMM yyyy', 'fr_FR');
    // ── Filter ─────────────────────────────────────────────────────────
    final now = DateTime.now();
    final hasDigitFilter = _digits != '00000000';
    final all = app.terminatedChargements.where((c) {
      if (_selectedDate != null) {
        final d = c.closedAt;
        if (d == null ||
            d.year != _selectedDate!.year ||
            d.month != _selectedDate!.month ||
            d.day != _selectedDate!.day) {
          return false;
        }
      }
      if (_quickFilter == 'month') {
        final d = c.closedAt;
        if (d == null || d.year != now.year || d.month != now.month) return false;
      }
      if (_quickFilter == 'week') {
        final d = c.closedAt;
        if (d == null) return false;
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final weekStart = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        final weekEnd = weekStart.add(const Duration(days: 7));
        if (d.isBefore(weekStart) || !d.isBefore(weekEnd)) return false;
      }
      if (hasDigitFilter) {
        final yearPart = _digits.substring(0, 4);
        final numPart = _digits.substring(4, 8);
        final yearActive = yearPart != '0000';
        final numActive = numPart != '0000';
        if (yearActive && numActive) {
          return c.bonNumero?.contains('$yearPart-$numPart') == true;
        } else if (yearActive) {
          return c.bonNumero?.contains(yearPart) == true;
        } else {
          return c.bonNumero?.contains(numPart) == true;
        }
      }
      return true;
    }).toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Text(
              context.tr('hist_title'),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${all.length} / ${app.terminatedChargements.length} ${context.tr('hist_subtitle')}',
              style: TextStyle(
                fontSize: 16,
                color: mute,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),

            // ── Search bar + calendar ────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _toggleSearchPad,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _showSearchPad ? leaf : line,
                          width: _showSearchPad ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: card,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search,
                              size: 20,
                              color: _showSearchPad ? leaf : mute),
                          const SizedBox(width: 8),
                          if (_showSearchPad || hasDigitFilter) ...[          
                            Text(
                              'BE-',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: ink,
                              ),
                            ),
                            ...List.generate(4, (i) {
                              final isZero = _digits[i] == '0' &&
                                  !_digits
                                      .substring(0, i + 1)
                                      .contains(RegExp(r'[1-9]'));
                              return Text(
                                _digits[i],
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: isZero
                                      ? mute.withValues(alpha: 0.45)
                                      : ink,
                                  fontFamily: 'monospace',
                                ),
                              );
                            }),
                            Text(
                              '-',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: ink,
                              ),
                            ),
                            ...List.generate(4, (i) {
                              final idx = i + 4;
                              final isZero = _digits[idx] == '0' &&
                                  !_digits
                                      .substring(0, idx + 1)
                                      .contains(RegExp(r'[1-9]'));
                              return Text(
                                _digits[idx],
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: isZero
                                      ? mute.withValues(alpha: 0.45)
                                      : ink,
                                  fontFamily: 'monospace',
                                ),
                              );
                            }),

                          ] else
                            Text(
                              context.tr('hist_search'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: mute,
                              ),
                            ),
                          const Spacer(),
                          if (_showSearchPad || hasDigitFilter)
                            GestureDetector(
                              onTap: () => setState(() {
                                _digits = '00000000';
                                _showSearchPad = false;
                              }),
                              child:
                                  Icon(Icons.clear, size: 18, color: mute),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Calendar filter button
                GestureDetector(
                  // Tap: clear if date set, else open picker
                  onTap: _selectedDate != null
                      ? () => setState(() => _selectedDate = null)
                      : () => _pickDate(context),
                  // Long-press: always open picker to change date
                  onLongPress: () => _pickDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedDate != null ? leaf : line,
                        width: _selectedDate != null ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: card,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _selectedDate != null
                              ? Icons.close
                              : Icons.calendar_today,
                          size: 18,
                          color: _selectedDate != null ? leaf : mute,
                        ),
                        if (_selectedDate != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('dd MMM yyyy', context.watch<LanguageProvider>().languageCode)
                                .format(_selectedDate!),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: leaf,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            // ── Quick filters ────────────────────────────────────────────
            Row(
              children: [
                _QuickChip(
                  label: context.tr('hist_all'),
                  active: _quickFilter == null && _selectedDate == null,
                  activeColor: leaf,
                  onTap: () => setState(() {
                    _quickFilter = null;
                    _selectedDate = null;
                  }),
                  card: card,
                  line: line,
                  ink: ink,
                  mute: mute,
                ),
                const SizedBox(width: 8),
                _QuickChip(
                  label: context.tr('hist_this_week'),
                  active: _quickFilter == 'week',
                  activeColor: leaf,
                  onTap: () => setState(() {
                    _quickFilter = _quickFilter == 'week' ? null : 'week';
                    _selectedDate = null;
                  }),
                  card: card,
                  line: line,
                  ink: ink,
                  mute: mute,
                ),
                const SizedBox(width: 8),
                _QuickChip(
                  label: context.tr('hist_this_month'),
                  active: _quickFilter == 'month',
                  activeColor: leaf,
                  onTap: () => setState(() {
                    _quickFilter = _quickFilter == 'month' ? null : 'month';
                    _selectedDate = null;
                  }),
                  card: card,
                  line: line,
                  ink: ink,
                  mute: mute,
                ),
              ],
            ),

            // ── Keypad ──────────────────────────────────────────────────
            if (_showSearchPad) ...[              
              const SizedBox(height: 10),
              BbCodeKeypad(
                onKeyTap: _onKeyTap,
                onClear: _onClear,
                onBackspace: _onBackspace,
              ),
            ],
            const SizedBox(height: 12),

            // ── List ────────────────────────────────────────────────────
            Expanded(
              child: all.isEmpty
                  ? Center(
                      child: Text(
                        hasDigitFilter || _selectedDate != null || _quickFilter != null
                            ? context.tr('hist_no_results')
                            : context.tr('hist_empty'),
                        style: TextStyle(color: mute, fontSize: 18),
                      ),
                    )
                  : ListView.separated(
                      itemCount: all.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final c = all[i];
                        final bbs = _bonBags[c.id] ?? [];
                        final brut = bbs.fold(0.0, (s, b) => s + b.poidsBrut);
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
                            builder: (_) => BonViewerScreen(
                                chargementId: c.id),
                          ),
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
    final isWide = MediaQuery.of(context).size.width >= 700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: card,
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: isWide
          ? _wideRow(context, ink, mute, leafTint, leafDark)
          : _narrowCol(context, ink, mute, leafTint, leafDark),
    );
  }

  Widget _wideRow(
      BuildContext context, Color ink, Color mute, Color leafTint, Color leafDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Bon + date
        SizedBox(
          width: 160,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(bonNumero,
                  style: AppTextStyles.monoWeight(
                      15, FontWeight.w800, color: ink)),
              Text(date,
                  style: TextStyle(
                      fontSize: 13,
                      color: mute,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        // Client + camion/chauffeur
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(client,
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: ink),
                  overflow: TextOverflow.ellipsis),
              if ((camion?.trim().isNotEmpty ?? false) ||
                  (chauffeur?.trim().isNotEmpty ?? false))
                Text(
                  [
                    if (camion?.trim().isNotEmpty ?? false)
                      camion!.trim(),
                    if (chauffeur?.trim().isNotEmpty ?? false)
                      chauffeur!.trim(),
                  ].join(' · '),
                  style: TextStyle(
                      fontSize: 13,
                      color: mute,
                      fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        // Stats
        _mini('$nbBB ${context.tr('stock_total_bb') == 'Big Bags' ? 'BB' : 'كيس'}', ink, mute),
        const SizedBox(width: 16),
        _mini('$brut ${context.tr('kg')} ${context.tr('ch_brut').toLowerCase()}', ink, mute),
        const SizedBox(width: 12),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: leafTint,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$net ${context.tr('kg')} ${context.tr('bon_net').toLowerCase()}',
            style: AppTextStyles.monoWeight(
                15, FontWeight.w800, color: leafDark),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: onOpen,
          icon: const Icon(Icons.print, size: 16),
          label: Text(context.watch<LanguageProvider>().languageCode == 'ar' ? 'فتح' : 'Rouvrir',
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          style: OutlinedButton.styleFrom(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  Widget _narrowCol(
      BuildContext context, Color ink, Color mute, Color leafTint, Color leafDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bonNumero,
                      style: AppTextStyles.monoWeight(
                          14, FontWeight.w800, color: ink)),
                  Text(date,
                      style: TextStyle(
                          fontSize: 12,
                          color: mute,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.print, size: 16),
              label: Text(context.watch<LanguageProvider>().languageCode == 'ar' ? 'فتح' : 'Rouvrir',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(client,
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: ink),
            overflow: TextOverflow.ellipsis),
        if ((camion?.trim().isNotEmpty ?? false) ||
            (chauffeur?.trim().isNotEmpty ?? false))
          Text(
            [
              if (camion?.trim().isNotEmpty ?? false) camion!.trim(),
              if (chauffeur?.trim().isNotEmpty ?? false)
                chauffeur!.trim(),
            ].join(' · '),
            style: TextStyle(
                fontSize: 13,
                color: mute,
                fontWeight: FontWeight.w500),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            _mini('$nbBB ${context.tr('stock_total_bb') == 'Big Bags' ? 'BB' : 'كيس'}', ink, mute),
            const SizedBox(width: 14),
            _mini('$brut ${context.tr('kg')} ${context.tr('ch_brut').toLowerCase()}', ink, mute),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: leafTint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$net ${context.tr('kg')} ${context.tr('bon_net').toLowerCase()}',
                style: AppTextStyles.monoWeight(
                    14, FontWeight.w800, color: leafDark),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _mini(String text, Color ink, Color mute) {
    return Text(
      text,
      style: AppTextStyles.monoWeight(14, FontWeight.w700, color: mute),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;
  final Color card;
  final Color line;
  final Color ink;
  final Color mute;

  const _QuickChip({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onTap,
    required this.card,
    required this.line,
    required this.ink,
    required this.mute,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? activeColor.withValues(alpha: 0.12) : card,
          border: Border.all(
            color: active ? activeColor : line,
            width: active ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? activeColor : mute,
          ),
        ),
      ),
    );
  }
}
