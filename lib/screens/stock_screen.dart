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
  DateTime? _selectedDate;
  bool _showSearchPad = false;

  void _onKeyTap(String digit) {
    setState(() {
      if (_search.isEmpty || _search == 'BB-') {
        _search = 'BB-$digit';
      } else {
        _search += digit;
      }
    });
  }

  void _onBackspace() {
    setState(() {
      if (_search.length <= 3) {
        _search = 'BB-';
      } else {
        _search = _search.substring(0, _search.length - 1);
      }
    });
  }

  void _onClear() {
    setState(() {
      _search = 'BB-';
    });
  }

  void _toggleSearchPad() {
    setState(() {
      _showSearchPad = !_showSearchPad;
      if (_showSearchPad) {
        if (_search.isEmpty) {
          _search = 'BB-';
        }
      } else {
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
                  // Search & Date Row (Responsive)
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
                                      Icon(Icons.search, size: 22, color: mute),
                                      const SizedBox(width: 10),
                                      Text(
                                        _search.isEmpty ? 'Chercher BB-...' : _search,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: _search.isEmpty ? mute : ink,
                                        ),
                                      ),
                                      if (_search.isNotEmpty) ...[
                                        const Spacer(),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _search = '';
                                              _showSearchPad = false;
                                            });
                                          },
                                          child: Icon(Icons.clear, size: 20, color: mute),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              if (_showSearchPad) ...[
                                const SizedBox(height: 10),
                                _SearchKeypad(
                                  onKeyTap: _onKeyTap,
                                  onClear: _onClear,
                                  onBackspace: _onBackspace,
                                ),
                              ],
                            ],
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
                                Icon(Icons.search, size: 22, color: mute),
                                const SizedBox(width: 10),
                                Text(
                                  _search.isEmpty ? 'Chercher BB-...' : _search,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: _search.isEmpty ? mute : ink,
                                  ),
                                ),
                                if (_search.isNotEmpty) ...[
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _search = '';
                                        _showSearchPad = false;
                                      });
                                    },
                                    child: Icon(Icons.clear, size: 20, color: mute),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        if (_showSearchPad) ...[
                          const SizedBox(height: 10),
                          _SearchKeypad(
                            onKeyTap: _onKeyTap,
                            onClear: _onClear,
                            onBackspace: _onBackspace,
                          ),
                        ],
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _DateFilterButton(
                            selectedDate: _selectedDate,
                            onChanged: (date) => setState(() => _selectedDate = date),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),

                  // ── Stat tiles ─────────────────────────────────────────
                  if (isWide) ...[
                    Row(
                      children: [
                        Expanded(child: _StatTile(label: 'EN STOCK', value: '${app.stockCount}', unit: 'BB', fmt: fmt)),
                        const SizedBox(width: 12),
                        Expanded(child: _StatTile(label: 'POIDS EN STOCK', value: fmt.format(app.stockPoidsTotal), unit: 'kg', fmt: fmt)),
                        const SizedBox(width: 12),
                        Expanded(child: _StatTile(label: 'CHARGÉS', value: '${app.chargeCount}', unit: 'BB', fmt: fmt)),
                        const SizedBox(width: 12),
                        Expanded(child: _StatTile(label: 'EXPÉDIÉS', value: '${app.expedieCount}', unit: 'BB', fmt: fmt)),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.2,
                      children: [
                        _StatTile(label: 'EN STOCK', value: '${app.stockCount}', unit: 'BB', fmt: fmt),
                        _StatTile(label: 'POIDS EN STOCK', value: fmt.format(app.stockPoidsTotal), unit: 'kg', fmt: fmt),
                        _StatTile(label: 'CHARGÉS', value: '${app.chargeCount}', unit: 'BB', fmt: fmt),
                        _StatTile(label: 'EXPÉDIÉS', value: '${app.expedieCount}', unit: 'BB', fmt: fmt),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Filter chips ────────────────────────────────────────
                  SingleChildScrollView(
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
                              child: cell(dateFmt.format(bb.createdAt)),
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

    return Container(
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

class _SearchKeypad extends StatelessWidget {
  final ValueChanged<String> onKeyTap;
  final VoidCallback onClear;
  final VoidCallback onBackspace;

  const _SearchKeypad({
    required this.onKeyTap,
    required this.onClear,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['C', '0', '←'],
    ];

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.card,
        border: Border.all(color: isDark ? AppColors.lineDark : AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var row in keys) ...[
            Row(
              children: [
                for (var key in row) ...[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: _SearchKey(
                        label: key,
                        onTap: () {
                          if (key == 'C') {
                            onClear();
                          } else if (key == '←') {
                            onBackspace();
                          } else {
                            onKeyTap(key);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchKey extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _SearchKey({required this.label, required this.onTap});

  @override
  State<_SearchKey> createState() => _SearchKeyState();
}

class _SearchKeyState extends State<_SearchKey> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final leaf = isDark ? AppColors.leafOnDark : AppColors.leaf;
    final ink = isDark ? AppColors.inkOnDark : AppColors.ink;
    final line = isDark ? AppColors.lineDark : AppColors.line;

    Color bg;
    Color fg;
    if (_isPressed) {
      bg = leaf;
      fg = isDark ? const Color(0xFF0D1F0F) : Colors.white;
    } else {
      bg = isDark ? const Color(0xFF1E2221) : AppColors.bg;
      fg = ink;
    }

    return Listener(
      onPointerDown: (_) => setState(() => _isPressed = true),
      onPointerUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onPointerCancel: (_) => setState(() => _isPressed = false),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _isPressed ? leaf : line, width: 0.8),
        ),
        alignment: Alignment.center,
        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: fg,
            fontFamily: widget.label == '←' ? null : 'monospace',
          ),
        ),
      ),
    );
  }
}
