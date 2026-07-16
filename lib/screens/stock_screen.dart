import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/big_bag.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/bb_code_keypad.dart';

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
  DateTime? _selectedDate;
  bool _showSearchPad = false;

  // Right-to-left calculator-style digit buffer (always 6 chars, zero-padded)
  String _digits = '000000';

  void _onKeyTap(String digit) {
    setState(() {
      // Shift digits left, append new digit on right
      final trimmed = (_digits + digit).substring(1);
      _digits = trimmed.padLeft(6, '0');
      _search = 'BB-$_digits';
    });
  }

  void _onBackspace() {
    setState(() {
      // Shift digits right, prepend 0 on left
      if (_digits == '000000') return;
      _digits = '0${_digits.substring(0, _digits.length - 1)}';
      _search = 'BB-$_digits';
    });
  }

  void _onClear() {
    setState(() {
      _digits = '000000';
      _search = 'BB-$_digits';
    });
  }

  void _toggleSearchPad() {
    setState(() {
      _showSearchPad = !_showSearchPad;
      if (_showSearchPad) {
        _digits = '000000';
        _search = 'BB-$_digits';
      } else {
        _digits = '000000';
        _search = '';
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkOnDark : AppColors.ink;
    final mute = isDark ? AppColors.inkMuteDark : AppColors.inkMute;
    final line = isDark ? AppColors.lineDark : AppColors.line;
    final leaf = isDark ? AppColors.leafOnDark : AppColors.leaf;
    final fmt = NumberFormat('#,##0', 'fr_FR');
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');

    final dateFilteredBags = app.bigBags.where((b) {
      if (_selectedDate == null) return true;
      return b.createdAt.year == _selectedDate!.year &&
          b.createdAt.month == _selectedDate!.month &&
          b.createdAt.day == _selectedDate!.day;
    }).toList();

    final dateFilteredTotal = dateFilteredBags.length;
    final dateFilteredStock = dateFilteredBags.where((b) => b.status == BigBagStatus.stock).length;
    final dateFilteredCharge = dateFilteredBags.where((b) => b.status == BigBagStatus.charge).length;
    final dateFilteredExpedie = dateFilteredBags.where((b) => b.status == BigBagStatus.expedie).length;

    final filtered = app.filterBigBags(status: _filter, search: _search).where((b) {
      if (_selectedDate == null) return true;
      return b.createdAt.year == _selectedDate!.year &&
          b.createdAt.month == _selectedDate!.month &&
          b.createdAt.day == _selectedDate!.day;
    }).toList();
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 700;

    const cols = ['ID', 'POIDS BRUT', 'CRÉÉ', 'STATUT'];
    const flexes = [4, 3, 4, 3];

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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
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
                    ],
                  ),
                  const SizedBox(height: 12),
                   // Search row — same for wide and narrow
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              GestureDetector(
                                onTap: _toggleSearchPad,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: _showSearchPad ? leaf : line, width: _showSearchPad ? 2 : 1),
                                    borderRadius: BorderRadius.circular(12),
                                    color: isDark ? AppColors.cardDark : AppColors.card,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.search, size: 22, color: _showSearchPad ? leaf : mute),
                                      const SizedBox(width: 10),
                                      if (_showSearchPad) ...[
                                        // Styled zero-padded display: zeros muted, typed digits bold
                                        Text('BB-', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ink)),
                                        ...List.generate(6, (i) {
                                          final isZero = _digits[i] == '0' && !_digits.substring(0, i + 1).contains(RegExp(r'[1-9]'));
                                          return Text(
                                            _digits[i],
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w800,
                                              color: isZero ? mute.withValues(alpha: 0.45) : ink,
                                              fontFamily: 'monospace',
                                            ),
                                          );
                                        }),
                                      ] else ...[
                                        Text(
                                          _search.isEmpty ? 'Chercher BB-...' : _search,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                            color: _search.isEmpty ? mute : ink,
                                          ),
                                        ),
                                      ],
                                      const Spacer(),
                                      if (_showSearchPad || _search.isNotEmpty)
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _search = '';
                                              _digits = '000000';
                                              _showSearchPad = false;
                                            });
                                          },
                                          child: Icon(Icons.clear, size: 20, color: mute),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              if (_showSearchPad) ...[
                                const SizedBox(height: 10),
                                BbCodeKeypad(
                                  onKeyTap: _onKeyTap,
                                  onClear: _onClear,
                                  onBackspace: _onBackspace,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GestureDetector(
                          onTap: _toggleSearchPad,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: _showSearchPad ? leaf : line, width: _showSearchPad ? 2 : 1),
                              borderRadius: BorderRadius.circular(12),
                              color: isDark ? AppColors.cardDark : AppColors.card,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.search, size: 22, color: _showSearchPad ? leaf : mute),
                                const SizedBox(width: 10),
                                if (_showSearchPad) ...[
                                  Text('BB-', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ink)),
                                  ...List.generate(6, (i) {
                                    final isZero = _digits[i] == '0' && !_digits.substring(0, i + 1).contains(RegExp(r'[1-9]'));
                                    return Text(
                                      _digits[i],
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: isZero ? mute.withValues(alpha: 0.45) : ink,
                                        fontFamily: 'monospace',
                                      ),
                                    );
                                  }),
                                ] else ...[
                                  Text(
                                    _search.isEmpty ? 'Chercher BB-...' : _search,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: _search.isEmpty ? mute : ink,
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                if (_showSearchPad || _search.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _search = '';
                                        _digits = '000000';
                                        _showSearchPad = false;
                                      });
                                    },
                                    child: Icon(Icons.clear, size: 20, color: mute),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (_showSearchPad) ...[
                          const SizedBox(height: 10),
                          BbCodeKeypad(
                            onKeyTap: _onKeyTap,
                            onClear: _onClear,
                            onBackspace: _onBackspace,
                          ),
                        ],
                      ],
                    ),
                  const SizedBox(height: 20),

                  // ── Stat tiles ─────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(child: _StatTile(label: 'EN STOCK', value: '${app.stockCount}', unit: 'BB', fmt: fmt, accentColor: AppColors.leaf)),
                      const SizedBox(width: 8),
                      Expanded(child: _StatTile(label: 'POIDS', value: fmt.format(app.stockPoidsTotal), unit: 'kg', fmt: fmt, accentColor: AppColors.sun)),
                      const SizedBox(width: 8),
                      Expanded(child: _StatTile(label: 'CHARGÉS', value: '${app.chargeCount}', unit: 'BB', fmt: fmt, accentColor: const Color(0xFF3B82F6))),
                      const SizedBox(width: 8),
                      Expanded(child: _StatTile(label: 'EXPÉDIÉS', value: '${app.expedieCount}', unit: 'BB', fmt: fmt, accentColor: AppColors.clay)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Filter chips + Date button ──────────────────────────
                  if (isWide)
                    // Wide: chips left, date right in one row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _FilterChip(
                                  label: 'TOUT',
                                  count: dateFilteredTotal,
                                  active: _filter == null,
                                  onTap: () => setState(() => _filter = null),
                                ),
                                const SizedBox(width: 10),
                                _FilterChip(
                                  label: 'EN STOCK',
                                  count: dateFilteredStock,
                                  active: _filter == BigBagStatus.stock,
                                  onTap: () => setState(() => _filter = BigBagStatus.stock),
                                ),
                                const SizedBox(width: 10),
                                _FilterChip(
                                  label: 'CHARGÉ',
                                  count: dateFilteredCharge,
                                  active: _filter == BigBagStatus.charge,
                                  onTap: () => setState(() => _filter = BigBagStatus.charge),
                                ),
                                const SizedBox(width: 10),
                                _FilterChip(
                                  label: 'EXPÉDIÉ',
                                  count: dateFilteredExpedie,
                                  active: _filter == BigBagStatus.expedie,
                                  onTap: () => setState(() => _filter = BigBagStatus.expedie),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _DateFilterButton(
                          selectedDate: _selectedDate,
                          onChanged: (date) => setState(() => _selectedDate = date),
                        ),
                      ],
                    )
                  else
                    // Narrow: small compact chips left, date button right — all in one row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _FilterChip(
                                  label: 'TOUT',
                                  count: dateFilteredTotal,
                                  active: _filter == null,
                                  onTap: () => setState(() => _filter = null),
                                  compact: true,
                                ),
                                const SizedBox(width: 6),
                                _FilterChip(
                                  label: 'EN STOCK',
                                  count: dateFilteredStock,
                                  active: _filter == BigBagStatus.stock,
                                  onTap: () => setState(() => _filter = BigBagStatus.stock),
                                  compact: true,
                                ),
                                const SizedBox(width: 6),
                                _FilterChip(
                                  label: 'CHARGÉ',
                                  count: dateFilteredCharge,
                                  active: _filter == BigBagStatus.charge,
                                  onTap: () => setState(() => _filter = BigBagStatus.charge),
                                  compact: true,
                                ),
                                const SizedBox(width: 6),
                                _FilterChip(
                                  label: 'EXPÉDIÉ',
                                  count: dateFilteredExpedie,
                                  active: _filter == BigBagStatus.expedie,
                                  onTap: () => setState(() => _filter = BigBagStatus.expedie),
                                  compact: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _DateFilterButton(
                          selectedDate: _selectedDate,
                          onChanged: (date) => setState(() => _selectedDate = date),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),

                  // ── Table Header ──────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                                fontSize: 15,
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

            // ── Table body ───────────────────────────────────
            filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'Aucun Big Bag',
                        style: TextStyle(color: mute, fontSize: 20),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final bb = filtered[i];
                      final isDarkRow = isDark;
                      Color rowBg;
                      Color codeColor;
                      switch (bb.status) {
                        case BigBagStatus.stock:
                          rowBg = isDarkRow
                              ? AppColors.leafOnDark.withValues(alpha: 0.08)
                              : AppColors.leafTint.withValues(alpha: 0.5);
                          codeColor = isDarkRow ? AppColors.leafOnDark : AppColors.leafDark;
                        case BigBagStatus.charge:
                          rowBg = isDarkRow
                              ? AppColors.sunOnDark.withValues(alpha: 0.08)
                              : AppColors.sunTint.withValues(alpha: 0.5);
                          codeColor = isDarkRow ? AppColors.sunOnDark : AppColors.sun;
                        case BigBagStatus.expedie:
                          rowBg = isDarkRow
                              ? AppColors.clayOnDark.withValues(alpha: 0.08)
                              : AppColors.clayTint.withValues(alpha: 0.5);
                          codeColor = isDarkRow ? AppColors.clayOnDark : AppColors.clay;
                      }
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: rowBg,
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
                                  color: codeColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: flexes[1],
                              child: cell('${bb.poidsBrut.toStringAsFixed(0)} kg', color: codeColor.withValues(alpha: 0.85)),
                            ),
                            Expanded(
                              flex: flexes[2],
                              child: cell(dateFmt.format(bb.createdAt), color: codeColor.withValues(alpha: 0.8)),
                            ),
                            Expanded(
                              flex: flexes[3],
                              child: _StatusBadge(status: bb.status),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 32),
          ],
        ),
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
  final Color accentColor;

  const _StatTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.fmt,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Derive tint from accent
    final cardBg = accentColor.withValues(alpha: isDark ? 0.12 : 0.08);
    final borderColor = accentColor.withValues(alpha: isDark ? 0.3 : 0.25);


    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border.all(color: borderColor),
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
              color: accentColor.withValues(alpha: isDark ? 0.8 : 0.75),
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
                    style: AppTextStyles.monoWeight(36, FontWeight.w800, color: accentColor),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: accentColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
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
  final bool compact;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkOnDark : AppColors.ink;
    final card = isDark ? AppColors.cardDark : AppColors.card;
    final line = isDark ? AppColors.lineDark : AppColors.line;
    final mute = isDark ? AppColors.inkMuteDark : AppColors.inkMute;

    final hPad = compact ? 10.0 : 20.0;
    final vPad = compact ? 6.0 : 10.0;
    final fontSize = compact ? 13.0 : 17.0;

    return Material(
      color: active ? ink : card,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          decoration: BoxDecoration(
            border: Border.all(color: active ? ink : line),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            '$label  $count',
            style: TextStyle(
              fontSize: fontSize,
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
          isDark
              ? AppColors.clayOnDark.withValues(alpha: 0.16)
              : AppColors.clayTint,
          isDark ? AppColors.clayOnDark : AppColors.clay,
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

class _DateFilterButton extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime?> onChanged;

  const _DateFilterButton({
    required this.selectedDate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkOnDark : AppColors.ink;
    final line = isDark ? AppColors.lineDark : AppColors.line;
    final leaf = isDark ? AppColors.leafOnDark : AppColors.leaf;

    final dateFmt = DateFormat('dd/MM/yyyy', 'fr_FR');
    final today = DateTime.now();
    final isToday = selectedDate != null &&
        selectedDate!.year == today.year &&
        selectedDate!.month == today.month &&
        selectedDate!.day == today.day;

    final label = selectedDate == null
        ? 'Toutes les dates'
        : (isToday ? "Aujourd'hui" : dateFmt.format(selectedDate!));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          onPressed: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: (selectedDate != null && selectedDate!.isBefore(now)) ? selectedDate! : now,
              firstDate: DateTime(2025),
              lastDate: now,
            );
            if (picked != null) {
              onChanged(picked);
            }
          },
          icon: Icon(Icons.calendar_today, size: 20, color: selectedDate != null ? leaf : ink),
          label: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: selectedDate != null ? leaf : ink,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            side: BorderSide(color: selectedDate != null ? leaf : line, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        if (selectedDate != null) ...[
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.clear, size: 22),
            onPressed: () => onChanged(null),
            style: IconButton.styleFrom(
              foregroundColor: AppColors.clay,
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ],
    );
  }
}


