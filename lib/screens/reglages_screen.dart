import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../theme/app_theme.dart';

/// Écran Réglages : thème clair/sombre, langue, réinitialisation des données locales.
class ReglagesScreen extends StatelessWidget {
  const ReglagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkOnDark : AppColors.ink;
    final mute = isDark ? AppColors.inkMuteDark : AppColors.inkMute;
    final card = isDark ? AppColors.cardDark : AppColors.card;
    final line = isDark ? AppColors.lineDark : AppColors.line;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Réglages',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Préférences locales de cette tablette',
                  style: TextStyle(fontSize: 20, color: mute, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 20),

                // ── Thème Section ──────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: card,
                    border: Border.all(color: line),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'THÈME',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: mute,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _ThemeOption(
                              icon: Icons.light_mode,
                              label: 'Clair',
                              selected: !themeProvider.isDark,
                              onTap: () => themeProvider.setDark(false),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _ThemeOption(
                              icon: Icons.dark_mode,
                              label: 'Sombre',
                              selected: themeProvider.isDark,
                              onTap: () => themeProvider.setDark(true),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ── Langue Section ─────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: card,
                    border: Border.all(color: line),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LANGUE',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: mute,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _LanguageOption(
                              flag: '🇫🇷',
                              label: 'Français',
                              selected: languageProvider.languageCode == 'fr',
                              onTap: () => languageProvider.setLanguage('fr'),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _LanguageOption(
                              flag: '🇩🇿',
                              label: 'العربية',
                              selected: languageProvider.languageCode == 'ar',
                              onTap: () => languageProvider.setLanguage('ar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ── Données Section ────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: card,
                    border: Border.all(color: line),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DONNÉES',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: mute,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 70,
                        child: OutlinedButton.icon(
                          onPressed: () => _confirmReset(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: isDark
                                ? AppColors.clayOnDark
                                : AppColors.clay,
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.delete_outline, size: 28),
                          label: const Text(
                            'Réinitialiser les données',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Big Bag Manager — Delta Recycl · Données stockées localement (SQLite) sur cette tablette.',
                        style: TextStyle(fontSize: 16, color: mute, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    final passwordCtrl = TextEditingController();
    bool wrongPassword = false;
    bool resetSequence = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text(
            'Réinitialiser les données',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cette action est irréversible : tous les Big Bags et chargements seront supprimés.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                title: const Text(
                  'Réinitialiser aussi la numérotation (repartir de BB-000001)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                value: resetSequence,
                onChanged: (val) {
                  setStateDialog(() => resetSequence = val ?? false);
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.clay,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordCtrl,
                obscureText: true,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  errorText: wrongPassword ? 'Mot de passe incorrect' : null,
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                onChanged: (_) {
                  if (wrongPassword) setStateDialog(() => wrongPassword = false);
                },
                onSubmitted: (_) async {
                  if (passwordCtrl.text == 'bamo123') {
                    await context.read<AppProvider>().resetAllData(resetSequence: resetSequence);
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  } else {
                    setStateDialog(() => wrongPassword = true);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            FilledButton(
              onPressed: () async {
                if (passwordCtrl.text == 'bamo123') {
                  await context.read<AppProvider>().resetAllData(resetSequence: resetSequence);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                } else {
                  setStateDialog(() => wrongPassword = true);
                }
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.clay),
              child: const Text('Confirmer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeOption({
    required this.icon,
    required this.label,
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
    final card = isDark ? AppColors.cardDark : AppColors.card;

    return Material(
      color: selected ? leafTint : card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 28),
          decoration: BoxDecoration(
            border: Border.all(color: selected ? leaf : line, width: 2.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(icon, size: 36, color: selected ? leafDark : mute),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: selected ? leafDark : mute,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String flag;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _LanguageOption({
    required this.flag,
    required this.label,
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
    final card = isDark ? AppColors.cardDark : AppColors.card;

    return Material(
      color: selected ? leafTint : card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            border: Border.all(color: selected ? leaf : line, width: 2.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Text(
                flag,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: selected ? leafDark : mute,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
