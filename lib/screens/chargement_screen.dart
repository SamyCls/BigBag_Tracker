import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/chargement.dart';
import '../models/big_bag.dart';
import '../providers/app_provider.dart';
import '../providers/language_provider.dart';
import '../theme/app_theme.dart';
import '../utils/toast.dart';
import '../widgets/bb_code_keypad.dart';
import 'bon_viewer_screen.dart';

/// Écran Chargement : liste des sessions actives/en pause + création
/// d'une nouvelle session + interface ultra rapide d'ajout de Big Bags.
class ChargementScreen extends StatefulWidget {
  const ChargementScreen({super.key});

  @override
  State<ChargementScreen> createState() => _ChargementScreenState();
}

enum _Mode { list, setup, session }

class _ChargementScreenState extends State<ChargementScreen> {
  _Mode _mode = _Mode.list;
  int? _activeId;

  @override
  Widget build(BuildContext context) {
    switch (_mode) {
      case _Mode.setup:
        return _SetupView(
          onCancel: () => setState(() => _mode = _Mode.list),
          onStart: (client, camion, chauffeur) async {
            final app = context.read<AppProvider>();
            final ch = await app.startChargement(
              client: client,
              camion: camion,
              chauffeur: chauffeur,
            );
            setState(() {
              _activeId = ch.id;
              _mode = _Mode.session;
            });
          },
        );
      case _Mode.session:
        final app = context.watch<AppProvider>();
        final matches = app.activeChargements.where((c) => c.id == _activeId);
        final ch = matches.isEmpty ? null : matches.first;
        if (ch == null) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => setState(() => _mode = _Mode.list),
          );
          return const SizedBox.shrink();
        }
        return _SessionView(
          chargement: ch,
          onBack: () async {
            await context.read<AppProvider>().pauseChargement(ch.id);
            setState(() => _mode = _Mode.list);
          },
          onFinished: (finishedId) {
            setState(() => _mode = _Mode.list);
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => BonViewerScreen(chargementId: finishedId),
            );
          },
        );
      case _Mode.list:
        return _ListView(
          onNew: () => setState(() => _mode = _Mode.setup),
          onOpen: (id) {
            context.read<AppProvider>().resumeChargement(id);
            setState(() {
              _activeId = id;
              _mode = _Mode.session;
            });
          },
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Liste des chargements actifs / en pause
// ---------------------------------------------------------------------------

class _ListView extends StatelessWidget {
  final VoidCallback onNew;
  final void Function(int id) onOpen;
  const _ListView({required this.onNew, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkOnDark : AppColors.ink;
    final mute = isDark ? AppColors.inkMuteDark : AppColors.inkMute;
    final leaf = isDark ? AppColors.leafOnDark : AppColors.leaf;
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 980;

    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    final active = app.activeChargements;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLandscape)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('ch_title'),
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            color: ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.watch<LanguageProvider>().languageCode == 'ar'
                              ? 'أنشئ أو استأنف شحنة · لا يوجد فقدان للبيانات'
                              : 'Créez ou reprenez une session ',
                          style: TextStyle(
                            fontSize: 20,
                            color: mute,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (active.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: onNew,
                      icon: const Icon(Icons.add, size: 30),
                      label: Text(
                        context.tr('ch_new'),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 20,
                        ),
                      ),
                    ),
                  ],
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.tr('ch_title'),
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.watch<LanguageProvider>().languageCode == 'ar'
                        ? 'أنشئ أو استأنف شحنة · لا يوجد فقدان للبيانات'
                        : 'Créez ou reprenez une session · pas de perte de données',
                    style: TextStyle(
                      fontSize: 20,
                      color: mute,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (active.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: onNew,
                      icon: const Icon(Icons.add, size: 30),
                      label: Text(
                        context.tr('ch_new'),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 22),
                      ),
                    ),
                  ],
                ],
              ),
            const SizedBox(height: 20),
            Expanded(
              child: active.isEmpty
                  ? Center(
                      child: ElevatedButton.icon(
                        onPressed: onNew,
                        icon: const Icon(Icons.add, size: 48),
                        label: Text(
                          context.tr('ch_new'),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 36,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    )
                  : GridView.builder(
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: isWide ? 500 : 700,
                        mainAxisExtent: 300,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: active.length,
                      itemBuilder: (context, i) {
                        final c = active[i];
                        final bbs = app.bigBagsForChargement(c.id);
                        final brut = app.brutFor(bbs);
                        return _SessionCard(
                          chargement: c,
                          bbCount: bbs.length,
                          brut: brut,
                          leaf: leaf,
                          onTap: () => onOpen(c.id),
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

class _SessionCard extends StatelessWidget {
  final Chargement chargement;
  final int bbCount;
  final double brut;
  final Color leaf;
  final VoidCallback onTap;
  const _SessionCard({
    required this.chargement,
    required this.bbCount,
    required this.brut,
    required this.leaf,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkOnDark : AppColors.ink;
    final mute = isDark ? AppColors.inkMuteDark : AppColors.inkMute;
    final card = isDark ? AppColors.cardDark : AppColors.card;
    final sun = isDark ? AppColors.sunOnDark : AppColors.sun;
    final paused = chargement.status == ChargementStatus.pause;
    final fmt = NumberFormat('#,##0', 'fr_FR');

    return Material(
      color: card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 6, color: paused ? sun : leaf),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
              child: Column(
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
                              chargement.bonNumero ?? '—',
                              style: AppTextStyles.monoWeight(
                                18,
                                FontWeight.w700,
                                color: mute,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              chargement.client,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: ink,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: paused
                              ? sun.withValues(alpha: 0.15)
                              : leaf.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          paused ? context.tr('ch_paused').toUpperCase() : (context.watch<LanguageProvider>().languageCode == 'ar' ? 'نشط' : 'ACTIF'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: paused ? sun : leaf,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if ((chargement.camion != null &&
                          chargement.camion!.trim().isNotEmpty) ||
                      (chargement.chauffeur != null &&
                          chargement.chauffeur!.trim().isNotEmpty)) ...[
                    const SizedBox(height: 6),
                    Text(
                      [
                        if (chargement.camion != null &&
                            chargement.camion!.trim().isNotEmpty)
                          chargement.camion!.trim(),
                        if (chargement.chauffeur != null &&
                            chargement.chauffeur!.trim().isNotEmpty)
                          chargement.chauffeur!.trim(),
                      ].join(' · '),
                      style: TextStyle(
                        fontSize: 18,
                        color: mute,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniStat(
                          label: context.tr('stock_total_bb'),
                          value: '$bbCount',
                          color: leaf,
                          mute: mute,
                        ),
                      ),
                      Expanded(
                        child: _MiniStat(
                          label: context.tr('ch_brut'),
                          value: '${fmt.format(brut)} ${context.tr('kg')}',
                          color: ink,
                          mute: mute,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.inkOnDark : AppColors.ink,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          paused ? Icons.play_arrow : Icons.arrow_forward,
                          size: 22,
                          color: isDark ? AppColors.bgDark : Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          paused ? context.tr('ch_reprendre').toUpperCase() : (context.watch<LanguageProvider>().languageCode == 'ar' ? 'متابعة' : 'CONTINUER'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.bgDark : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color mute;
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    required this.mute,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: mute,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.monoWeight(28, FontWeight.w800, color: color),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Setup nouveau chargement
// ---------------------------------------------------------------------------

class _SetupView extends StatefulWidget {
  final VoidCallback onCancel;
  final void Function(String client, String? camion, String? chauffeur) onStart;
  const _SetupView({required this.onCancel, required this.onStart});

  @override
  State<_SetupView> createState() => _SetupViewState();
}

class _SetupViewState extends State<_SetupView> {
  final _clientCtrl = TextEditingController();
  final _camionCtrl = TextEditingController();
  final _chauffeurCtrl = TextEditingController();

  final _camionFocus = FocusNode();
  final _chauffeurFocus = FocusNode();
  bool _showCamionSuggestions = false;
  bool _showChauffeurSuggestions = false;

  @override
  void initState() {
    super.initState();
    _camionFocus.addListener(() {
      setState(() {
        _showCamionSuggestions = _camionFocus.hasFocus;
      });
    });
    _chauffeurFocus.addListener(() {
      setState(() {
        _showChauffeurSuggestions = _chauffeurFocus.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _clientCtrl.dispose();
    _camionCtrl.dispose();
    _chauffeurCtrl.dispose();
    _camionFocus.dispose();
    _chauffeurFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkOnDark : AppColors.ink;
    final mute = isDark ? AppColors.inkMuteDark : AppColors.inkMute;
    final card = isDark ? AppColors.cardDark : AppColors.card;
    final line = isDark ? AppColors.lineDark : AppColors.line;
    final leaf = isDark ? AppColors.leafOnDark : AppColors.leaf;

    // Past clients from all chargements, deduplicated
    final query = _clientCtrl.text.trim().toLowerCase();
    final allClients = {
      ...app.terminatedChargements.map((c) => c.client),
      ...app.activeChargements.map((c) => c.client),
    };
    final pastClients = allClients
        .where((c) => query.isEmpty || c.toLowerCase().contains(query))
        .toList();

    // Autocomplete sources for Camion and Chauffeur
    final queryCamion = _camionCtrl.text.trim().toLowerCase();
    final allCamions = {
      ...app.terminatedChargements.map((c) => c.camion),
      ...app.activeChargements.map((c) => c.camion),
    }.where((c) => c != null && c.isNotEmpty).cast<String>().toList();
    final matchingCamions = allCamions
        .where((c) => queryCamion.isEmpty || c.toLowerCase().contains(queryCamion))
        .toList();

    final queryChauffeur = _chauffeurCtrl.text.trim().toLowerCase();
    final allChauffeurs = {
      ...app.terminatedChargements.map((c) => c.chauffeur),
      ...app.activeChargements.map((c) => c.chauffeur),
    }.where((c) => c != null && c.isNotEmpty).cast<String>().toList();
    final matchingChauffeurs = allChauffeurs
        .where((c) => queryChauffeur.isEmpty || c.toLowerCase().contains(queryChauffeur))
        .toList();

    final isLandscape = MediaQuery.orientationOf(context) == Orientation.landscape;

    Widget buildSuggestionsList(
      List<String> suggestions,
      TextEditingController controller,
      FocusNode focusNode,
    ) {
      if (suggestions.isEmpty) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.only(top: 4),
        constraints: const BoxConstraints(maxHeight: 140),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.card,
          border: Border.all(color: line),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final val = suggestions[index];
            return InkWell(
              onTap: () {
                setState(() {
                  controller.text = val;
                  controller.selection = TextSelection.collapsed(offset: val.length);
                  focusNode.unfocus();
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                child: Text(
                  val,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: ink,
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    // Build responsive form card
    final mainFormCard = Container(
      padding: EdgeInsets.all(isLandscape ? 16 : 20),
      decoration: BoxDecoration(
        color: card,
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLandscape) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Column 1: Client
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${context.tr('ch_client')} *',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: mute,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _clientCtrl,
                        textCapitalization: TextCapitalization.words,
                        inputFormatters: [CapitalizeWordsFormatter()],
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: context.tr('ch_client_ph'),
                          hintStyle: const TextStyle(fontSize: 22),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 14,
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      if (pastClients.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: pastClients
                              .map(
                                (c) => ActionChip(
                                  label: Text(
                                    c,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: leaf,
                                    ),
                                  ),
                                  onPressed: () => setState(() {
                                    _clientCtrl.text = c;
                                    _clientCtrl.selection =
                                        TextSelection.collapsed(offset: c.length);
                                  }),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Column 2: Camion & Chauffeur
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('ch_camion').toUpperCase(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: mute,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _camionCtrl,
                        focusNode: _camionFocus,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: context.tr('ch_camion_ph'),
                          hintStyle: const TextStyle(fontSize: 22),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 14,
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      if (_showCamionSuggestions)
                        buildSuggestionsList(matchingCamions, _camionCtrl, _camionFocus),
                      const SizedBox(height: 12),
                      Text(
                        context.tr('ch_chauffeur').toUpperCase(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: mute,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _chauffeurCtrl,
                        focusNode: _chauffeurFocus,
                        textCapitalization: TextCapitalization.words,
                        inputFormatters: [CapitalizeWordsFormatter()],
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: context.tr('ch_chauffeur_ph'),
                          hintStyle: const TextStyle(fontSize: 22),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 14,
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      if (_showChauffeurSuggestions)
                        buildSuggestionsList(matchingChauffeurs, _chauffeurCtrl, _chauffeurFocus),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              '${context.tr('ch_client')} *',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: mute,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _clientCtrl,
              textCapitalization: TextCapitalization.words,
              inputFormatters: [CapitalizeWordsFormatter()],
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: context.tr('ch_client_ph'),
                hintStyle: const TextStyle(fontSize: 22),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 14,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (pastClients.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: pastClients
                    .map(
                      (c) => ActionChip(
                        label: Text(
                          c,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: leaf,
                          ),
                        ),
                        onPressed: () => setState(() {
                          _clientCtrl.text = c;
                          _clientCtrl.selection =
                              TextSelection.collapsed(offset: c.length);
                        }),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 18),
            Text(
              context.tr('ch_camion').toUpperCase(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: mute,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _camionCtrl,
              focusNode: _camionFocus,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: context.tr('ch_camion_ph'),
                hintStyle: const TextStyle(fontSize: 22),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 14,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (_showCamionSuggestions)
              buildSuggestionsList(matchingCamions, _camionCtrl, _camionFocus),
            const SizedBox(height: 18),
            Text(
              context.tr('ch_chauffeur').toUpperCase(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: mute,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _chauffeurCtrl,
              focusNode: _chauffeurFocus,
              textCapitalization: TextCapitalization.words,
              inputFormatters: [CapitalizeWordsFormatter()],
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: context.tr('ch_chauffeur_ph'),
                hintStyle: const TextStyle(fontSize: 22),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 14,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (_showChauffeurSuggestions)
              buildSuggestionsList(matchingChauffeurs, _chauffeurCtrl, _chauffeurFocus),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: isLandscape ? 64 : 80,
            child: ElevatedButton.icon(
              onPressed: _clientCtrl.text.trim().isEmpty
                  ? null
                  : () => widget.onStart(
                      _clientCtrl.text.trim(),
                      _camionCtrl.text.trim().isEmpty
                          ? null
                          : _camionCtrl.text.trim(),
                      _chauffeurCtrl.text.trim().isEmpty
                          ? null
                          : _chauffeurCtrl.text.trim(),
                    ),
              icon: const Icon(Icons.play_arrow, size: 28),
              label: Text(
                context.tr('ch_start'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('ch_setup'),
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          color: ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.tr('ch_subtitle'),
                        style: TextStyle(
                          fontSize: 20,
                          color: mute,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.close, size: 16),
                  label: Text(context.tr('cancel')),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isLandscape ? 880 : 560),
              child: mainFormCard,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TextInputFormatter to capitalize the first letter of every word
// ---------------------------------------------------------------------------
class CapitalizeWordsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;

    final text = newValue.text;
    final buffer = StringBuffer();
    bool capitalizeNext = true;

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (char == ' ') {
        buffer.write(char);
        capitalizeNext = true;
      } else if (capitalizeNext) {
        buffer.write(char.toUpperCase());
        capitalizeNext = false;
      } else {
        buffer.write(char);
      }
    }

    final formattedText = buffer.toString();
    return newValue.copyWith(
      text: formattedText,
      selection: newValue.selection,
    );
  }
}

// ---------------------------------------------------------------------------
// Session de chargement — interface ultra rapide
// ---------------------------------------------------------------------------

class _SessionView extends StatefulWidget {
  final Chargement chargement;
  final VoidCallback onBack;
  final void Function(int finishedId) onFinished;
  const _SessionView({
    required this.chargement,
    required this.onBack,
    required this.onFinished,
  });

  @override
  State<_SessionView> createState() => _SessionViewState();
}

class _SessionViewState extends State<_SessionView> {
  bool _showAddPad = false;
  String _digits = '000000';

  void _onKeyTap(String digit) {
    setState(() {
      final trimmed = (_digits + digit).substring(1);
      _digits = trimmed.padLeft(6, '0');
    });
  }

  void _onBackspace() {
    setState(() {
      if (_digits == '000000') return;
      _digits = '0${_digits.substring(0, _digits.length - 1)}';
    });
  }

  void _onClear() {
    setState(() {
      _digits = '000000';
    });
  }

  void _toggleAddPad() {
    setState(() {
      _showAddPad = !_showAddPad;
      if (!_showAddPad) {
        _digits = '000000';
      }
    });
  }

  Future<void> _tryAdd(AppProvider app, [String? code]) async {
    final rawCode = code ?? 'BB-$_digits';
    if (rawCode == 'BB-000000' && code == null) return;
    final result = await app.addBigBagToChargement(
      widget.chargement.id,
      rawCode,
    );
    if (!mounted) return;
    switch (result) {
      case AddBBResult.ok:
        showAppToast(context, '${app.normalizeCode(rawCode)} ${context.tr('ch_ajoute')}');
        setState(() {
          _digits = '000000';
        });
        break;
      case AddBBResult.notFound:
        showAppToast(context, context.tr('ch_introuvable'), isError: true);
        break;
      case AddBBResult.alreadyCharge:
        showAppToast(
          context,
          context.tr('ch_deja_charge'),
          isError: true,
        );
        break;
      case AddBBResult.alreadyExpedie:
        showAppToast(context, context.tr('ch_deja_expedie'), isError: true);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final ch = widget.chargement;
    final bbs = app.bigBagsForChargement(ch.id);
    final brut = app.brutFor(bbs);
    final tare = app.tareFor(bbs);
    final net = app.netFor(bbs);
    final fmt = NumberFormat('#,##0', 'fr_FR');

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkOnDark : AppColors.ink;
    final mute = isDark ? AppColors.inkMuteDark : AppColors.inkMute;
    final leaf = isDark ? AppColors.leafOnDark : AppColors.leaf;
    final card = isDark ? AppColors.cardDark : AppColors.card;
    final line = isDark ? AppColors.lineDark : AppColors.line;

    // Memorable high-contrast colors for outdoor usage (sun exposure)
    final box1Bg = isDark ? const Color(0xFF065F46) : const Color(0xFF059669); // Emerald Green
    final box2Bg = isDark ? const Color(0xFF9A3412) : const Color(0xFFEA580C); // Orange
    final box3Bg = isDark ? const Color(0xFF1E3A8A) : const Color(0xFF2563EB); // Royal Blue
    final box4Bg = isDark ? const Color(0xFF881337) : const Color(0xFFBE123C); // Clay/Rose/Red

    final boxTextColor = Colors.white.withValues(alpha: 0.76);
    final boxValueColor = Colors.white;

    final stockSuggestions = app
        .filterBigBags(status: BigBagStatus.stock)
        .where((b) => !bbs.any((loaded) => loaded.id == b.id))
        .toList();

    Widget buildListPanel() {
      final dividerColor = card == AppColors.cardDark ? AppColors.lineDark : AppColors.line;

      return Container(
        decoration: BoxDecoration(
          color: card,
          border: Border.all(color: line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── PINNED: Stock suggestions ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Text(
                stockSuggestions.isEmpty
                    ? context.tr('ch_empty_stock')
                    : '${context.tr('st_stock')} — ${context.tr('prod_suggestions')}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: mute,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            SizedBox(
              height: 130,
              child: stockSuggestions.isEmpty
                  ? Center(
                      child: Text(
                        context.tr('ch_all_added'),
                        style: TextStyle(
                          color: mute,
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      scrollDirection: Axis.horizontal,
                      itemCount: stockSuggestions.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final b = stockSuggestions[i];
                        final isSelected =
                            _digits != '000000' && 'BB-$_digits' == b.code;
                        return _StockSuggestionCard(
                          bb: b,
                          selected: isSelected,
                          leaf: leaf,
                          ink: ink,
                          mute: mute,
                          card: card,
                          line: line,
                          onTap: () => _tryAdd(app, b.code),
                        );
                      },
                    ),
            ),
            Divider(height: 1, color: dividerColor),

            // ── SCROLLABLE: add pad + loaded list ─────────────────────
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // ── Add pad ──────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: _toggleAddPad,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: _showAddPad ? leaf : line,
                                          width: _showAddPad ? 2 : 1),
                                      borderRadius: BorderRadius.circular(12),
                                      color: isDark
                                          ? AppColors.cardDark
                                          : AppColors.card,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.add_box_outlined,
                                            size: 22,
                                            color:
                                                _showAddPad ? leaf : mute),
                                        const SizedBox(width: 10),
                                        if (_showAddPad) ...[
                                          Text(
                                            'BB-',
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                color: ink),
                                          ),
                                          ...List.generate(6, (i) {
                                            final isZero = _digits[i] == '0' &&
                                                !_digits
                                                    .substring(0, i + 1)
                                                    .contains(
                                                        RegExp(r'[1-9]'));
                                            return Text(
                                              _digits[i],
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w800,
                                                color: isZero
                                                    ? mute.withValues(
                                                        alpha: 0.45)
                                                    : ink,
                                                fontFamily: 'monospace',
                                              ),
                                            );
                                          }),
                                        ] else ...[
                                          Text(
                                            context.tr('ch_scan_ph'),
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500,
                                              color: mute,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                height: 58,
                                child: ElevatedButton.icon(
                                  onPressed: (_digits == '000000')
                                      ? null
                                      : () => _tryAdd(app),
                                  icon: const Icon(Icons.add, size: 22),
                                  label: Text(
                                    context.tr('ch_add').toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_showAddPad) ...[
                            const SizedBox(height: 12),
                            BbCodeKeypad(
                              onKeyTap: _onKeyTap,
                              onClear: _onClear,
                              onBackspace: _onBackspace,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                      child: Divider(height: 1, color: dividerColor)),

                  // ── Loaded BB header ──────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.tr('ch_liste').toUpperCase(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: mute,
                              letterSpacing: 0.4,
                            ),
                          ),
                          Text(
                            context.tr('ch_recent_top'),
                            style: TextStyle(
                              fontSize: 16,
                              color: mute,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Loaded BB list ────────────────────────────────────
                  if (bbs.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Text(
                            context.tr('ch_empty_session'),
                            style: TextStyle(
                              fontSize: 22,
                              fontStyle: FontStyle.italic,
                              color: mute,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final idx = bbs.length - 1 - i;
                          final bb = bbs[idx];
                          return Container(
                            margin:
                                const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 36,
                                  child: Text(
                                    '${idx + 1}',
                                    style: AppTextStyles.monoWeight(
                                      18,
                                      FontWeight.w700,
                                      color: mute,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    bb.code,
                                    style: AppTextStyles.monoWeight(
                                      24,
                                      FontWeight.w800,
                                      color: ink,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${fmt.format(bb.poidsBrut)} ${context.tr('kg')}',
                                  style: AppTextStyles.monoWeight(
                                    20,
                                    FontWeight.w600,
                                    color: mute,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                TextButton.icon(
                                  onPressed: () =>
                                      app.removeBigBagFromChargement(
                                          ch.id, bb.id),
                                  icon: const Icon(Icons.delete_outline,
                                      size: 22),
                                  label: const Text(
                                    'Retirer',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: isDark
                                        ? AppColors.clayOnDark
                                        : AppColors.clay,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        childCount: bbs.length,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back, size: 30),
                  padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ch.client,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: ink,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${ch.bonNumero ?? ""} ${ch.camion != null ? "· ${ch.camion}" : ""} ${ch.chauffeur != null ? "· ${ch.chauffeur}" : ""}',
                        style: TextStyle(
                          fontSize: 18,
                          color: mute,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final appProvider = context.read<AppProvider>();
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(context.tr('ch_cancel_confirm_title')),
                        content: Text(
                          context.tr('ch_cancel_confirm_body'),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(context.tr('no')),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: Text(context.tr('ch_confirm_cancel')),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && mounted) {
                      await appProvider.cancelChargement(ch.id);
                      widget.onBack();
                    }
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(
                    context.tr('cancel').toUpperCase(),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    if (ch.status == ChargementStatus.pause) {
                      await app.resumeChargement(ch.id);
                    } else {
                      await app.pauseChargement(ch.id);
                    }
                    widget.onBack();
                  },
                  icon: Icon(
                    ch.status == ChargementStatus.pause
                        ? Icons.play_arrow
                        : Icons.pause,
                    size: 18,
                  ),
                  label: Text(
                    ch.status == ChargementStatus.pause ? context.tr('ch_reprendre').toUpperCase() : context.tr('ch_pause').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: bbs.isEmpty
                      ? null
                      : () async {
                          final finished = await app.finishChargement(ch.id);
                          widget.onFinished(finished.id);
                        },
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(
                    context.tr('ch_terminer').toUpperCase(),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Tot(
                    label: context.tr('ch_nb_bb').toUpperCase(),
                    value: '${bbs.length}',
                    bgColor: box1Bg,
                    textColor: boxTextColor,
                    valueColor: boxValueColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Tot(
                    label: context.tr('ch_brut').toUpperCase(),
                    value: '${fmt.format(brut)} ${context.tr('kg')}',
                    bgColor: box2Bg,
                    textColor: boxTextColor,
                    valueColor: boxValueColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Tot(
                    label: context.tr('ch_tare').toUpperCase(),
                    value: '- ${fmt.format(tare)} ${context.tr('kg')}',
                    bgColor: box3Bg,
                    textColor: boxTextColor,
                    valueColor: boxValueColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Tot(
                    label: context.tr('ch_net').toUpperCase(),
                    value: '${fmt.format(net)} ${context.tr('kg')}',
                    bgColor: box4Bg,
                    textColor: boxTextColor,
                    valueColor: boxValueColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: buildListPanel(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tot extends StatelessWidget {
  final String label;
  final String value;
  final Color bgColor;
  final Color textColor;
  final Color valueColor;

  const _Tot({
    required this.label,
    required this.value,
    required this.bgColor,
    required this.textColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTextStyles.monoWeight(
                28,
                FontWeight.w900,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StockSuggestionCard extends StatelessWidget {
  final BigBag bb;
  final bool selected;
  final Color leaf;
  final Color ink;
  final Color mute;
  final Color card;
  final Color line;
  final VoidCallback onTap;

  const _StockSuggestionCard({
    required this.bb,
    required this.selected,
    required this.leaf,
    required this.ink,
    required this.mute,
    required this.card,
    required this.line,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'fr_FR');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = leaf.withValues(alpha: selected ? 0.18 : 0.08);
    final borderColor = leaf.withValues(alpha: selected ? 1.0 : 0.3);
    final textCodeColor = isDark ? AppColors.leafOnDark : AppColors.leafDark;

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 160,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: borderColor,
              width: selected ? 2.5 : 1.5,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                bb.code,
                style: AppTextStyles.monoWeight(
                  22,
                  FontWeight.w800,
                  color: textCodeColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${fmt.format(bb.poidsBrut)} kg',
                style: AppTextStyles.monoWeight(
                  17,
                  FontWeight.w600,
                  color: textCodeColor.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


