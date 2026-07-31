import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/big_bag.dart';
import '../providers/app_provider.dart';
import '../providers/language_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/bb_code_keypad.dart';
import '../utils/toast.dart';

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
    final fmt = NumberFormat('#,##0.##', 'fr_FR');

    // Memorable high-contrast colors for outdoor usage (sun exposure)
    final box1Bg = isDark ? const Color(0xFF065F46) : const Color(0xFF059669); // Emerald Green (EN STOCK)
    final box2Bg = isDark ? const Color(0xFF1E3A8A) : const Color(0xFF2563EB); // Royal Blue (POIDS)
    final box3Bg = isDark ? const Color(0xFF9A3412) : const Color(0xFFEA580C); // Orange/Yellow (CHARGÉS)
    final box4Bg = isDark ? const Color(0xFF881337) : const Color(0xFFBE123C); // Clay/Rose/Red (EXPÉDIÉS)

    final boxTextColor = Colors.white.withValues(alpha: 0.76);
    final boxValueColor = Colors.white;
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');

    int dateFilteredTotal = 0;
    int dateFilteredStock = 0;
    int dateFilteredCharge = 0;
    int dateFilteredExpedie = 0;
    double dateFilteredStockPoids = 0.0;

    if (!_showSearchPad) {
      for (final b in app.bigBags) {
        if (_selectedDate != null) {
          final isSameDay = b.createdAt.year == _selectedDate!.year &&
              b.createdAt.month == _selectedDate!.month &&
              b.createdAt.day == _selectedDate!.day;
          if (!isSameDay) continue;
        }
        dateFilteredTotal++;
        switch (b.status) {
          case BigBagStatus.stock:
            dateFilteredStock++;
            dateFilteredStockPoids += b.poidsBrut;
            break;
          case BigBagStatus.charge:
            dateFilteredCharge++;
            break;
          case BigBagStatus.expedie:
            dateFilteredExpedie++;
            break;
        }
      }
    }

    final List<BigBag> filtered;
    if (_showSearchPad && _search.isNotEmpty) {
      final cleanQuery = _digits.replaceFirst(RegExp(r'^0+'), '');
      if (cleanQuery.isEmpty) {
        filtered = const [];
      } else {
        filtered = app.bigBags
            .where((b) => b.code.contains(cleanQuery))
            .take(20)
            .toList();
      }
    } else {
      filtered = app.filterBigBags(status: _filter, search: _search).where((b) {
        if (_selectedDate == null) return true;
        return b.createdAt.year == _selectedDate!.year &&
            b.createdAt.month == _selectedDate!.month &&
            b.createdAt.day == _selectedDate!.day;
      }).toList();
    }
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 700;

    final cols = [
      context.tr('bon_num'),
      context.tr('prod_poids'),
      context.tr('bon_date'),
      context.tr('nav_stock'),
    ];
    const flexes = [4, 3, 4, 3];

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              context.tr('stock_title'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w800,
                                color: ink,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              context.tr('stock_subtitle'),
                              textAlign: TextAlign.center,
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
                                          _search.isEmpty ? context.tr('stock_search') : _search,
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
                                    _search.isEmpty ? context.tr('stock_search') : _search,
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

                  if (!_showSearchPad) ...[
                    // ── Stat tiles ─────────────────────────────────────────
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _StatTile(
                          label: context.tr('stock_poids_total'),
                          value: fmt.format(dateFilteredStockPoids),
                          unit: 'kg',
                          fmt: fmt,
                          bgColor: box2Bg,
                          textColor: boxTextColor,
                          valueColor: boxValueColor,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _StatTile(
                                label: context.tr('st_stock'),
                                value: '$dateFilteredStock',
                                unit: 'BB',
                                fmt: fmt,
                                bgColor: box1Bg,
                                textColor: boxTextColor,
                                valueColor: boxValueColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StatTile(
                                label: context.tr('stock_filter_charge'),
                                value: '$dateFilteredCharge',
                                unit: 'BB',
                                fmt: fmt,
                                bgColor: box3Bg,
                                textColor: boxTextColor,
                                valueColor: boxValueColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StatTile(
                                label: context.tr('stock_filter_expedie'),
                                value: '$dateFilteredExpedie',
                                unit: 'BB',
                                fmt: fmt,
                                bgColor: box4Bg,
                                textColor: boxTextColor,
                                valueColor: boxValueColor,
                              ),
                            ),
                          ],
                        ),
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
                                    label: context.tr('stock_filter_all'),
                                    count: dateFilteredTotal,
                                    active: _filter == null,
                                    onTap: () => setState(() => _filter = null),
                                  ),
                                  const SizedBox(width: 10),
                                  _FilterChip(
                                    label: context.tr('stock_filter_stock'),
                                    count: dateFilteredStock,
                                    active: _filter == BigBagStatus.stock,
                                    onTap: () => setState(() => _filter = BigBagStatus.stock),
                                  ),
                                  const SizedBox(width: 10),
                                  _FilterChip(
                                    label: context.tr('stock_filter_charge'),
                                    count: dateFilteredCharge,
                                    active: _filter == BigBagStatus.charge,
                                    onTap: () => setState(() => _filter = BigBagStatus.charge),
                                  ),
                                  const SizedBox(width: 10),
                                  _FilterChip(
                                    label: context.tr('stock_filter_expedie'),
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
                                    label: context.tr('stock_filter_all'),
                                    count: dateFilteredTotal,
                                    active: _filter == null,
                                    onTap: () => setState(() => _filter = null),
                                    compact: true,
                                  ),
                                  const SizedBox(width: 6),
                                  _FilterChip(
                                    label: context.tr('stock_filter_stock'),
                                    count: dateFilteredStock,
                                    active: _filter == BigBagStatus.stock,
                                    onTap: () => setState(() => _filter = BigBagStatus.stock),
                                    compact: true,
                                  ),
                                  const SizedBox(width: 6),
                                  _FilterChip(
                                    label: context.tr('stock_filter_charge'),
                                    count: dateFilteredCharge,
                                    active: _filter == BigBagStatus.charge,
                                    onTap: () => setState(() => _filter = BigBagStatus.charge),
                                    compact: true,
                                  ),
                                  const SizedBox(width: 6),
                                  _FilterChip(
                                    label: context.tr('stock_filter_expedie'),
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
                  ],
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
                        context.tr('stock_empty'),
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
                      
                      // ── vivid status colours ─────────────────────────────────────────────
                      final Color cardBg = switch (bb.status) {
                        BigBagStatus.stock =>
                          isDark ? const Color(0xFF1B4D2E) : const Color(0xFF2E7D32),
                        BigBagStatus.charge =>
                          isDark ? const Color(0xFFD97706) : const Color(0xFFF57F17),
                        BigBagStatus.expedie => const Color(0xFF881337),
                      };

                      final IconData icon = switch (bb.status) {
                        BigBagStatus.stock => Icons.warehouse_rounded,
                        BigBagStatus.charge => Icons.local_shipping_rounded,
                        BigBagStatus.expedie => Icons.check_circle_rounded,
                      };

                      return Container(
                        margin: EdgeInsets.only(bottom: i < filtered.length - 1 ? 10 : 0),
                        child: Material(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: bb.status == BigBagStatus.expedie
                                ? null
                                : () => _showEditOptionsDialog(context, bb),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                              child: Row(
                                children: [
                                  // ── Code (flex 4) ──────────────────────────────────────
                                  Expanded(
                                    flex: flexes[0],
                                    child: Text(
                                      bb.code,
                                      style: AppTextStyles.monoWeight(
                                        20,
                                        FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // ── Weight (flex 3) ──────────────────────────────────────
                                  Expanded(
                                    flex: flexes[1],
                                    child: Text(
                                      '${fmt.format(bb.poidsBrut)} kg',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // ── Date (flex 4) ──────────────────────────────────────
                                  Expanded(
                                    flex: flexes[2],
                                    child: Text(
                                      dateFmt.format(bb.createdAt),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // ── Status Chip (flex 3) ──────────────────────────────────
                                  Expanded(
                                    flex: flexes[3],
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              icon,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 5),
                                            Flexible(
                                              child: Text(
                                                switch (bb.status) {
                                                  BigBagStatus.stock => context.tr('st_stock'),
                                                  BigBagStatus.charge => context.tr('st_charge'),
                                                  BigBagStatus.expedie => context.tr('st_expedie'),
                                                },
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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

// ── Stat tile ──────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final NumberFormat fmt;
  final Color bgColor;
  final Color textColor;
  final Color valueColor;

  const _StatTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.fmt,
    required this.bgColor,
    required this.textColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: 0.5,
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
                    style: AppTextStyles.monoWeight(
                      36,
                      FontWeight.w900,
                      color: valueColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: textColor,
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
        ? context.tr('stock_all_dates')
        : (isToday ? context.tr('stock_today') : dateFmt.format(selectedDate!));

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


