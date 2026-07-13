import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chargement.dart';
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

    final active = app.activeChargements;

    return SafeArea(
      child: Padding(
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
                        'Chargement camion',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Créez ou reprenez une session · pas de perte de données',
                        style: TextStyle(fontSize: 13, color: mute),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onNew,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('NOUVEAU CHARGEMENT'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: active.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Aucun chargement en cours',
                            style: TextStyle(
                              fontSize: 18,
                              fontStyle: FontStyle.italic,
                              color: mute,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: onNew,
                            icon: const Icon(Icons.add),
                            label: const Text('NOUVEAU CHARGEMENT'),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: isWide ? 420 : 600,
                        mainAxisExtent: 210,
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
                                13,
                                FontWeight.w700,
                                color: mute,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              chargement.client,
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
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
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: paused ? sun : leaf,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${chargement.camion ?? "—"} · ${chargement.chauffeur ?? "—"}',
                    style: TextStyle(fontSize: 12, color: mute),
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
                        size: 16,
                      ),
                      label: Text(paused ? 'REPRENDRE' : 'CONTINUER'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? AppColors.inkOnDark
                            : AppColors.ink,
                        foregroundColor: isDark
                            ? AppColors.bgDark
                            : Colors.white,
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
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: mute,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.monoWeight(20, FontWeight.w800, color: color),
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

  static const _suggestions = [
    'Plastimed SARL',
    'EuroPET Milano',
    'Recyclor Barcelona',
    'Green Loop DE',
  ];

  @override
  void dispose() {
    _clientCtrl.dispose();
    _camionCtrl.dispose();
    _chauffeurCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkOnDark : AppColors.ink;
    final mute = isDark ? AppColors.inkMuteDark : AppColors.inkMute;
    final card = isDark ? AppColors.cardDark : AppColors.card;
    final line = isDark ? AppColors.lineDark : AppColors.line;

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
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Renseignez le client (le reste est optionnel)',
                        style: TextStyle(fontSize: 13, color: mute),
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
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: mute,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _clientCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Nom du client',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _suggestions
                          .map(
                            (c) => ActionChip(
                              label: Text(
                                c,
                                style: const TextStyle(fontSize: 12),
                              ),
                              onPressed: () =>
                                  setState(() => _clientCtrl.text = c),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'CAMION (OPTIONNEL)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: mute,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _camionCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Immatriculation',
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'CHAUFFEUR (OPTIONNEL)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: mute,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _chauffeurCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Nom du chauffeur',
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
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
                        icon: const Icon(Icons.play_arrow, size: 22),
                        label: const Text(
                          'DÉMARRER',
                          style: TextStyle(fontSize: 16),
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
    final isWide = width >= 800;

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
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: mute,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              border: Border.all(color: leaf, width: 2),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              preview ?? 'BB-______',
              style: AppTextStyles.monoWeight(
                36,
                FontWeight.w800,
                color: preview == null ? mute.withValues(alpha: 0.5) : ink,
              ),
            ),
          ),
          const SizedBox(height: 12),
          NumericKeypad(
            onDigit: (d) => setState(() {
              if (_input.length < 6) _input += d;
            }),
            onClear: () => setState(() => _input = ''),
            onBackspace: () => setState(() {
              if (_input.isNotEmpty)
                _input = _input.substring(0, _input.length - 1);
            }),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _input.isEmpty ? null : () => _tryAdd(app),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('AJOUTER'),
            ),
          ),
        ],
      ),
    );

    final listPanel = Container(
      decoration: BoxDecoration(
        color: card,
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'BIG BAGS CHARGÉS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: mute,
                    letterSpacing: 0.4,
                  ),
                ),
                Text(
                  'Plus récent en haut',
                  style: TextStyle(fontSize: 11, color: mute),
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
                        fontSize: 16,
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
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 26,
                              child: Text(
                                '${idx + 1}',
                                style: AppTextStyles.monoWeight(
                                  11,
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
                                  15,
                                  FontWeight.w800,
                                  color: ink,
                                ),
                              ),
                            ),
                            Text(
                              '${fmt.format(bb.poidsBrut)} kg',
                              style: AppTextStyles.monoWeight(
                                13,
                                FontWeight.w600,
                                color: mute,
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () =>
                                  app.removeBigBagFromChargement(ch.id, bb.id),
                              icon: const Icon(Icons.delete_outline, size: 14),
                              label: const Text(
                                'Retirer',
                                style: TextStyle(fontSize: 12),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: isDark
                                    ? AppColors.clayOnDark
                                    : AppColors.clay,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
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
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: ink,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${ch.bonNumero ?? ""} ${ch.camion != null ? "· ${ch.camion}" : ""} ${ch.chauffeur != null ? "· ${ch.chauffeur}" : ""}',
                        style: TextStyle(fontSize: 12, color: mute),
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
                  icon: const Icon(Icons.pause, size: 16),
                  label: const Text('PAUSE'),
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
                  label: const Text('TERMINER'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              childAspectRatio: 1.7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
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
                        addPanel,
                        const SizedBox(height: 12),
                        Expanded(child: listPanel),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: filled ? Colors.white70 : mute,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.monoWeight(
              18,
              FontWeight.w800,
              color: filled ? Colors.white : (color ?? ink),
            ),
          ),
        ],
      ),
    );
  }
}
