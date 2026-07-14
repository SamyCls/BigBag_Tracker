import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Grand clavier numérique tactile (0-9, effacer, retour arrière) —
/// pensé pour être utilisé avec des gants / gros doigts sur tablette.
class NumericKeypad extends StatelessWidget {
  final void Function(String digit) onDigit;
  final VoidCallback onClear;
  final VoidCallback onBackspace;

  /// When true the keypad expands to fill its parent (use inside an Expanded /
  /// SizedBox with a fixed height). When false it shrink-wraps via GridView.
  final bool expand;

  const NumericKeypad({
    super.key,
    required this.onDigit,
    required this.onClear,
    required this.onBackspace,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final line = isDark ? AppColors.lineDark : AppColors.line;
    final card = isDark ? AppColors.cardDark : AppColors.card;
    final ink = isDark ? AppColors.inkOnDark : AppColors.ink;
    final clayTint = isDark
        ? AppColors.clayOnDark.withValues(alpha: 0.18)
        : AppColors.clayTint;
    final clay = isDark ? AppColors.clayOnDark : AppColors.clay;
    final sunTint = isDark
        ? AppColors.sunOnDark.withValues(alpha: 0.18)
        : AppColors.sunTint;
    final sun = isDark ? AppColors.sunOnDark : AppColors.sun;

    Widget key(String label, {VoidCallback? onTap, Color? bg, Color? fg}) {
      return _KeypadKey(
        label: label,
        onTap: onTap,
        bg: bg ?? card,
        fg: fg ?? ink,
        border: line,
      );
    }

    final rows = [
      [
        key('7', onTap: () => onDigit('7')),
        key('8', onTap: () => onDigit('8')),
        key('9', onTap: () => onDigit('9')),
      ],
      [
        key('4', onTap: () => onDigit('4')),
        key('5', onTap: () => onDigit('5')),
        key('6', onTap: () => onDigit('6')),
      ],
      [
        key('1', onTap: () => onDigit('1')),
        key('2', onTap: () => onDigit('2')),
        key('3', onTap: () => onDigit('3')),
      ],
      [
        key('C', onTap: onClear, bg: clayTint, fg: clay),
        key('0', onTap: () => onDigit('0')),
        key('←', onTap: onBackspace, bg: sunTint, fg: sun),
      ],
    ];

    if (expand) {
      // Fills whatever space is given — place inside Expanded / SizedBox.
      return Column(
        children: rows.map((rowKeys) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: rowKeys.map((k) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: k,
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        }).toList(),
      );
    }

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.6,
      children: [
        key('7', onTap: () => onDigit('7')),
        key('8', onTap: () => onDigit('8')),
        key('9', onTap: () => onDigit('9')),
        key('4', onTap: () => onDigit('4')),
        key('5', onTap: () => onDigit('5')),
        key('6', onTap: () => onDigit('6')),
        key('1', onTap: () => onDigit('1')),
        key('2', onTap: () => onDigit('2')),
        key('3', onTap: () => onDigit('3')),
        key('C', onTap: onClear, bg: clayTint, fg: clay),
        key('0', onTap: () => onDigit('0')),
        key('←', onTap: onBackspace, bg: sunTint, fg: sun),
      ],
    );
  }
}

class _KeypadKey extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color bg;
  final Color fg;
  final Color border;

  const _KeypadKey({
    required this.label,
    required this.onTap,
    required this.bg,
    required this.fg,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.monoWeight(36, FontWeight.w800, color: fg),
          ),
        ),
      ),
    );
  }
}
