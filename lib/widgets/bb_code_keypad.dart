import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Compact calculator-style keypad for entering a BB-XXXXXX code.
/// Shared between [StockScreen] (search) and [ChargementScreen] (manual add).
class BbCodeKeypad extends StatelessWidget {
  final ValueChanged<String> onKeyTap;
  final VoidCallback onClear;
  final VoidCallback onBackspace;

  const BbCodeKeypad({
    super.key,
    required this.onKeyTap,
    required this.onClear,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const keys = [
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
          for (var row in keys)
            Row(
              children: [
                for (var key in row)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: _BbKey(
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
            ),
        ],
      ),
    );
  }
}

class _BbKey extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _BbKey({required this.label, required this.onTap});

  @override
  State<_BbKey> createState() => _BbKeyState();
}

class _BbKeyState extends State<_BbKey> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final leaf = isDark ? AppColors.leafOnDark : AppColors.leaf;
    final ink = isDark ? AppColors.inkOnDark : AppColors.ink;
    final line = isDark ? AppColors.lineDark : AppColors.line;

    final Color bg;
    final Color fg;
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
        height: 72,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _isPressed ? leaf : line, width: 1.0),
        ),
        alignment: Alignment.center,
        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: fg,
            fontFamily: widget.label == '←' ? null : 'monospace',
          ),
        ),
      ),
    );
  }
}
