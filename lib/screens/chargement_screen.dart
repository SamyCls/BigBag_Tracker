import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chargement.dart';
import '../models/big_bag.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/numeric_keypad.dart';
import '../utils/toast.dart';
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
    final isWide = width >= 700;

    final isLandscape = MediaQuery.orientationOf(context) == Orientation.landscape;

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
                          'Chargement camion',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            color: ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Créez ou reprenez une session · pas de perte de données',
                          style: TextStyle(fontSize: 20, color: mute, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  if (active.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: onNew,
                      icon: const Icon(Icons.add, size: 30),
                      label: const Text('NOUVEAU CHARGEMENT', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
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
                    'Chargement camion',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Créez ou reprenez une session · pas de perte de données',
                    style: TextStyle(fontSize: 20, color: mute, fontWeight: FontWeight.w500),
                  ),
                  if (active.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: onNew,
                      icon: const Icon(Icons.add, size: 30),
                      label: const Text('NOUVEAU CHARGEMENT', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
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
                        label: const Text(
                          'NOUVEAU CHARGEMENT',
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
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
                          paused ? 'EN PAUSE' : 'ACTIF',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: paused ? sun : leaf,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${chargement.camion ?? "—"} · ${chargement.chauffeur ?? "—"}',
                    style: TextStyle(fontSize: 18, color: mute, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniStat(
                          label: 'BIG BAGS',
                          value: '$bbCount',
                          color: leaf,
                          mute: mute,
                        ),
                      ),
                      Expanded(
                        child: _MiniStat(
                          label: 'POIDS BRUT',
                          value: '${fmt.format(brut)} kg',
                          color: ink,
                          mute: mute,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onTap,
                      icon: Icon(
                        paused ? Icons.play_arrow : Icons.arrow_forward,
                        size: 22,
                      ),
                      label: Text(
                        paused ? 'REPRENDRE' : 'CONTINUER',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? AppColors.inkOnDark
                            : AppColors.ink,
                        foregroundColor: isDark
                            ? AppColors.bgDark
                            : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
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

  @override
  void dispose() {
    _clientCtrl.dispose();
    _camionCtrl.dispose();
    _chauffeurCtrl.dispose();
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

    // Past clients from terminated chargements, deduplicated
    final query = _clientCtrl.text.trim().toLowerCase();
    final pastClients = app.terminatedChargements
        .map((c) => c.client)
        .toSet()
        .where((c) => query.isNotEmpty && c.toLowerCase().contains(query))
        .toList();

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
                        'Nouveau chargement',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          color: ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Renseignez le client (le reste est optionnel)',
                        style: TextStyle(fontSize: 20, color: mute, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Annuler'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: card,
                  border: Border.all(color: line),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CLIENT *',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: mute,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _clientCtrl,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                        hintText: 'Nom du client',
                        hintStyle: TextStyle(fontSize: 22),
                        contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 14),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    if (pastClients.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: pastClients.map((c) => ActionChip(
                          avatar: Icon(Icons.history, size: 20, color: leaf),
                          label: Text(
                            c,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: leaf),
                          ),
                          onPressed: () => setState(() {
                            _clientCtrl.text = c;
                            _clientCtrl.selection = TextSelection.collapsed(offset: c.length);
                          }),
                        )).toList(),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Text(
                      'CAMION (OPTIONNEL)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: mute,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _camionCtrl,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                        hintText: 'Immatriculation',
                        hintStyle: TextStyle(fontSize: 22),
                        contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 14),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'CHAUFFEUR (OPTIONNEL)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: mute,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _chauffeurCtrl,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                        hintText: 'Nom du chauffeur',
                        hintStyle: TextStyle(fontSize: 22),
                        contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 14),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 80,
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
                        label: const Text(
                          'DÉMARRER',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
  String _input = '';

  Future<void> _tryAdd(AppProvider app) async {
    if (_input.isEmpty) return;
    final result = await app.addBigBagToChargement(
      widget.chargement.id,
      _input,
    );
    if (!mounted) return;
    switch (result) {
      case AddBBResult.ok:
        showAppToast(context, '${app.normalizeCode(_input)} ajouté');
        setState(() => _input = '');
        break;
      case AddBBResult.notFound:
        showAppToast(context, 'Big Bag introuvable', isError: true);
        break;
      case AddBBResult.alreadyCharge:
        showAppToast(
          context,
          'Déjà chargé dans un autre camion',
          isError: true,
        );
        break;
      case AddBBResult.alreadyExpedie:
        showAppToast(context, 'Ce Big Bag est déjà expédié', isError: true);
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

    final preview = _input.isEmpty ? null : app.normalizeCode(_input);
    final width = MediaQuery.of(context).size.width;
    final isWide = MediaQuery.orientationOf(context) == Orientation.landscape && width >= 700;

    // Stock bags not yet loaded into this chargement → suggestion cards
    final stockSuggestions = app
        .filterBigBags(status: BigBagStatus.stock)
        .where((b) => !bbs.any((loaded) => loaded.id == b.id))
        .toList();

    // ── Add panel: preview + keypad only (no suggestions here) ─────────
    final addPanel = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AJOUTER BIG BAG',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: mute,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: leaf, width: 2),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              preview ?? 'BB-______',
              style: AppTextStyles.monoWeight(
                52,
                FontWeight.w800,
                color: preview == null ? mute.withValues(alpha: 0.5) : ink,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // keypad fills ALL remaining space
          Expanded(
            child: NumericKeypad(
              expand: true,
              onDigit: (d) => setState(() {
                if (_input.length < 6) _input += d;
              }),
              onClear: () => setState(() => _input = ''),
              onBackspace: () => setState(() {
                if (_input.isNotEmpty)
                  _input = _input.substring(0, _input.length - 1);
              }),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 70,
            child: ElevatedButton.icon(
              onPressed: _input.isEmpty ? null : () => _tryAdd(app),
              icon: const Icon(Icons.add, size: 28),
              label: const Text('AJOUTER', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );

    // ── List panel: suggestions at top, added bags below ────────────────
    final listPanel = Container(
      decoration: BoxDecoration(
        color: card,
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // suggestions row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Text(
              stockSuggestions.isEmpty
                  ? 'AUCUN SAC EN STOCK'
                  : 'EN STOCK — appuyez pour sélectionner',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: mute,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 110,
            child: stockSuggestions.isEmpty
                ? Center(
                    child: Text(
                      'Tous les sacs ont été ajoutés',
                      style: TextStyle(color: mute, fontSize: 16, fontStyle: FontStyle.italic),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: stockSuggestions.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final b = stockSuggestions[i];
                      final isSelected = _input == b.id.toString();
                      return _StockSuggestionCard(
                        bb: b,
                        selected: isSelected,
                        leaf: leaf,
                        ink: ink,
                        mute: mute,
                        card: card,
                        line: line,
                        onTap: () => setState(() =>
                            _input = isSelected ? '' : b.id.toString()),
                      );
                    },
                  ),
          ),
          Divider(height: 1, color: card == AppColors.cardDark ? AppColors.lineDark : AppColors.line),
          // header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'BIG BAGS CHARGÉS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: mute,
                    letterSpacing: 0.4,
                  ),
                ),
                Text(
                  'Plus récent en haut',
                  style: TextStyle(fontSize: 16, color: mute, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Expanded(
            child: bbs.isEmpty
                ? Center(
                    child: Text(
                      'Ajoutez votre premier Big Bag',
                      style: TextStyle(
                        fontSize: 22,
                        fontStyle: FontStyle.italic,
                        color: mute,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    itemCount: bbs.length,
                    itemBuilder: (context, i) {
                      final idx = bbs.length - 1 - i;
                      final bb = bbs[idx];
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
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
                              '${fmt.format(bb.poidsBrut)} kg',
                              style: AppTextStyles.monoWeight(
                                20,
                                FontWeight.w600,
                                color: mute,
                              ),
                            ),
                            const SizedBox(width: 10),
                            TextButton.icon(
                              onPressed: () =>
                                  app.removeBigBagFromChargement(ch.id, bb.id),
                              icon: const Icon(Icons.delete_outline, size: 22),
                              label: const Text(
                                'Retirer',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: isDark
                                    ? AppColors.clayOnDark
                                    : AppColors.clay,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );

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
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 4),
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
                        style: TextStyle(fontSize: 18, color: mute, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await app.pauseChargement(ch.id);
                    widget.onBack();
                  },
                  icon: const Icon(Icons.pause, size: 22),
                  label: const Text('PAUSE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: bbs.isEmpty
                      ? null
                      : () async {
                          final finished = await app.finishChargement(ch.id);
                          widget.onFinished(finished.id);
                        },
                  icon: const Icon(Icons.check, size: 24),
                  label: const Text('TERMINER', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isWide ? 4 : 2,
              childAspectRatio: isWide ? 1.8 : 2.2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _Tot(label: 'NB BIG BAGS', value: '${bbs.length}'),
                _Tot(label: 'POIDS BRUT', value: '${fmt.format(brut)} kg'),
                _Tot(
                  label: 'TARE (3kg × BB)',
                  value: '− ${fmt.format(tare)}',
                  color: isDark ? AppColors.sunOnDark : AppColors.sun,
                ),
                _Tot(
                  label: 'POIDS NET',
                  value: '${fmt.format(net)} kg',
                  filled: true,
                  leaf: leaf,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 4, child: addPanel),
                        const SizedBox(width: 16),
                        Expanded(flex: 5, child: listPanel),
                      ],
                    )
                  : Column(
                      children: [
                        Expanded(flex: 5, child: addPanel),
                        const SizedBox(height: 12),
                        Expanded(flex: 5, child: listPanel),
                      ],
                    ),
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
  final Color? color;
  final bool filled;
  final Color? leaf;
  const _Tot({
    required this.label,
    required this.value,
    this.color,
    this.filled = false,
    this.leaf,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.cardDark : AppColors.card;
    final line = isDark ? AppColors.lineDark : AppColors.line;
    final ink = isDark ? AppColors.inkOnDark : AppColors.ink;
    final mute = isDark ? AppColors.inkMuteDark : AppColors.inkMute;
    final leafColor = leaf ?? (isDark ? AppColors.leafOnDark : AppColors.leaf);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: filled ? leafColor : card,
        border: filled ? null : Border.all(color: line),
        borderRadius: BorderRadius.circular(12),
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
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: filled ? Colors.white70 : mute,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTextStyles.monoWeight(
                26,
                FontWeight.w800,
                color: filled ? Colors.white : (color ?? ink),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stock suggestion card — tappable, shows BB code + weight + quality
// ---------------------------------------------------------------------------

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
    final leafTint = leaf.withValues(alpha: 0.12);

    return Material(
      color: selected ? leafTint : card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 160,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? leaf : line,
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
                  color: selected ? leaf : ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${fmt.format(bb.poidsBrut)} kg',
                style: AppTextStyles.monoWeight(
                  17,
                  FontWeight.w600,
                  color: mute,
                ),
              ),
              Text(
                bb.qualite.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? leaf : mute,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
