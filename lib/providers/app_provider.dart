import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/big_bag_dao.dart';
import '../db/chargement_dao.dart';
import '../db/database_helper.dart';
import '../models/big_bag.dart';
import '../models/chargement.dart';

/// Résultat d'une tentative d'ajout de Big Bag à un chargement.
enum AddBBResult { ok, notFound, alreadyCharge, alreadyExpedie }

/// Provider central de l'application : orchestre les DAO, maintient
/// l'état en mémoire (liste des Big Bags, chargements) et expose la
/// logique métier (création BB, gestion chargement, calcul tare/net,
/// génération bon d'expédition).
class AppProvider extends ChangeNotifier {
  final BigBagDao _bbDao;
  final ChargementDao _chDao;

  AppProvider({BigBagDao? bbDao, ChargementDao? chDao})
    : _bbDao = bbDao ?? BigBagDao(),
      _chDao = chDao ?? ChargementDao();

  bool _loading = true;
  bool get loading => _loading;

  List<BigBag> _bigBags = [];
  List<BigBag> get bigBags => _bigBags;

  List<Chargement> _activeChargements = [];
  List<Chargement> get activeChargements => _activeChargements;

  List<Chargement> _terminatedChargements = [];
  List<Chargement> get terminatedChargements => _terminatedChargements;

  String _nextBBCode = 'BB-000001';
  String get nextBBCode => _nextBBCode;

  // Cache des Big Bags par chargement pour l'écran de session / bon.
  final Map<int, List<BigBag>> _bbByChargement = {};

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    await _reloadAll();
    _loading = false;
    notifyListeners();
  }

  Future<void> _reloadAll() async {
    _bigBags = await _bbDao.getAll();
    _activeChargements = await _chDao.getActiveOrPaused();
    _terminatedChargements = await _chDao.getTerminated();
    _nextBBCode = await _bbDao.peekNextCode();
    _bbByChargement.clear();
  }

  Future<void> refresh() async {
    await _reloadAll();
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Production
  // ---------------------------------------------------------------------

  /// Crée un Big Bag : seul poids brut + qualité (optionnelle) sont saisis.
  /// ID, date/heure et statut "EN STOCK" sont générés automatiquement.
  Future<BigBag> createBigBag({
    required double poidsBrut,
    Quality qualite = Quality.clair,
  }) async {
    final bb = await _bbDao.create(poidsBrut: poidsBrut, qualite: qualite);
    _bigBags.insert(0, bb);
    _nextBBCode = BigBag.padCode(bb.id + 1);
    notifyListeners();
    return bb;
  }

  List<BigBag> recentBigBags({int limit = 8}) => _bigBags.take(limit).toList();

  Future<void> updateBigBagWeight(int id, double newWeight) async {
    await _bbDao.updateWeight(id, newWeight);
    final idx = _bigBags.indexWhere((b) => b.id == id);
    if (idx != -1) {
      _bigBags[idx] = _bigBags[idx].copyWith(poidsBrut: newWeight);
      for (final list in _bbByChargement.values) {
        final cacheIdx = list.indexWhere((b) => b.id == id);
        if (cacheIdx != -1) {
          list[cacheIdx] = list[cacheIdx].copyWith(poidsBrut: newWeight);
        }
      }
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Stock
  // ---------------------------------------------------------------------

  int get stockCount =>
      _bigBags.where((b) => b.status == BigBagStatus.stock).length;
  int get chargeCount =>
      _bigBags.where((b) => b.status == BigBagStatus.charge).length;
  int get expedieCount =>
      _bigBags.where((b) => b.status == BigBagStatus.expedie).length;
  double get stockPoidsTotal => _bigBags
      .where((b) => b.status == BigBagStatus.stock)
      .fold(0.0, (s, b) => s + b.poidsBrut);

  List<BigBag> filterBigBags({BigBagStatus? status, String search = ''}) {
    var list = _bigBags;
    if (status != null) list = list.where((b) => b.status == status).toList();
    if (search.isNotEmpty) {
      final q = search.toLowerCase();
      list = list.where((b) => b.code.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  Future<void> deleteBigBag(int id) async {
    await _bbDao.delete(id);
    _bigBags.removeWhere((b) => b.id == id);
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Chargement
  // ---------------------------------------------------------------------

  int get activeSessionsCount => _activeChargements.length;

  Future<Chargement> startChargement({
    required String client,
    String? camion,
    String? chauffeur,
  }) async {
    final ch = await _chDao.create(
      client: client,
      camion: camion,
      chauffeur: chauffeur,
    );
    _activeChargements.insert(0, ch);
    _bbByChargement[ch.id] = [];
    notifyListeners();
    return ch;
  }

  /// Big Bags actuellement chargés dans une session donnée (triés par ajout).
  List<BigBag> bigBagsForChargement(int chargementId) {
    return _bbByChargement[chargementId] ??
        (_bbByChargement[chargementId] =
            _bigBags.where((b) => b.chargementId == chargementId).toList()
              ..sort((a, b) => a.id.compareTo(b.id)));
  }

  double brutFor(List<BigBag> list) =>
      list.fold(0.0, (s, b) => s + b.poidsBrut);
  int tareFor(List<BigBag> list) => list.length * BigBag.tareKg;
  double netFor(List<BigBag> list) => brutFor(list) - tareFor(list);

  /// Normalise une saisie utilisateur (ex: "12" ou "bb-12") en code complet.
  String normalizeCode(String raw) {
    var v = raw.trim().toUpperCase();
    if (RegExp(r'^\d+$').hasMatch(v)) {
      return BigBag.padCode(int.parse(v));
    }
    if (!v.startsWith('BB-')) {
      v = 'BB-$v';
    }
    return v;
  }

  /// Ajoute un Big Bag à un chargement, avec vérification anti-duplication :
  /// bloque si déjà chargé ou déjà expédié.
  Future<AddBBResult> addBigBagToChargement(
    int chargementId,
    String rawCode,
  ) async {
    final code = normalizeCode(rawCode);
    final bb = await _bbDao.getByCode(code);
    if (bb == null) return AddBBResult.notFound;
    if (bb.status == BigBagStatus.expedie) return AddBBResult.alreadyExpedie;
    if (bb.status == BigBagStatus.charge) return AddBBResult.alreadyCharge;

    final updated = bb.copyWith(
      status: BigBagStatus.charge,
      chargementId: chargementId,
    );
    final idx = _bigBags.indexWhere((b) => b.id == bb.id);
    if (idx != -1) _bigBags[idx] = updated;

    final list = _bbByChargement[chargementId] ?? [];
    list.add(updated);
    _bbByChargement[chargementId] = list;

    notifyListeners();

    await _bbDao.updateStatus(
      bb.id,
      BigBagStatus.charge,
      chargementId: chargementId,
    );

    return AddBBResult.ok;
  }

  /// Retire un Big Bag d'un chargement en cours (remet en stock).
  Future<void> removeBigBagFromChargement(int chargementId, int bbId) async {
    final idx = _bigBags.indexWhere((b) => b.id == bbId);
    if (idx != -1) {
      _bigBags[idx] = _bigBags[idx].copyWith(
        status: BigBagStatus.stock,
        clearChargementId: true,
      );
    }
    _bbByChargement[chargementId]?.removeWhere((b) => b.id == bbId);

    notifyListeners();

    await _bbDao.updateStatus(
      bbId,
      BigBagStatus.stock,
      clearChargementId: true,
    );
  }

  /// Annule un chargement : remet tous les Big Bags en stock et supprime la session.
  Future<void> cancelChargement(int id) async {
    final bbs = bigBagsForChargement(id);
    for (final bb in bbs) {
      await _bbDao.updateStatus(bb.id, BigBagStatus.stock, clearChargementId: true);
      final idx = _bigBags.indexWhere((b) => b.id == bb.id);
      if (idx != -1) {
        _bigBags[idx] = _bigBags[idx].copyWith(
          status: BigBagStatus.stock,
          clearChargementId: true,
        );
      }
    }
    _bbByChargement.remove(id);
    _activeChargements.removeWhere((c) => c.id == id);
    notifyListeners();
    await _chDao.delete(id);
  }

  Future<void> pauseChargement(int id) async {
    _updateChargementInList(
      id,
      (c) => c.copyWith(status: ChargementStatus.pause),
    );
    notifyListeners();
    await _chDao.setStatus(id, ChargementStatus.pause);
  }

  Future<void> resumeChargement(int id) async {
    _updateChargementInList(
      id,
      (c) => c.copyWith(status: ChargementStatus.actif),
    );
    notifyListeners();
    await _chDao.setStatus(id, ChargementStatus.actif);
  }

  void _updateChargementInList(int id, Chargement Function(Chargement) update) {
    final idx = _activeChargements.indexWhere((c) => c.id == id);
    if (idx != -1) _activeChargements[idx] = update(_activeChargements[idx]);
  }

  /// Termine un chargement : génère le bon d'expédition, marque tous les
  /// Big Bags de la session comme EXPÉDIÉ.
  Future<Chargement> finishChargement(int id) async {
    final bbs = bigBagsForChargement(id);
    for (final bb in bbs) {
      await _bbDao.updateStatus(bb.id, BigBagStatus.expedie, chargementId: id);
      final idx = _bigBags.indexWhere((b) => b.id == bb.id);
      if (idx != -1) {
        _bigBags[idx] = _bigBags[idx].copyWith(status: BigBagStatus.expedie);
      }
    }
    _bbByChargement[id] = bbs
        .map((b) => b.copyWith(status: BigBagStatus.expedie))
        .toList();

    final finished = await _chDao.finish(id);
    _activeChargements.removeWhere((c) => c.id == id);
    _terminatedChargements.insert(0, finished);

    notifyListeners();
    return finished;
  }

  // ---------------------------------------------------------------------
  // Historique
  // ---------------------------------------------------------------------

  Future<List<BigBag>> bigBagsForBon(int chargementId) async {
    if (_bbByChargement.containsKey(chargementId)) {
      return _bbByChargement[chargementId]!;
    }
    final list = await _bbDao.getByChargement(chargementId);
    _bbByChargement[chargementId] = list;
    return list;
  }

  // ---------------------------------------------------------------------
  // Réglages
  // ---------------------------------------------------------------------

  Future<void> resetAllData({bool resetSequence = false}) async {
    await DatabaseHelper.instance.resetAll();
    if (resetSequence) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_big_bag_id');
    }
    _bbByChargement.clear();
    await _reloadAll();
    notifyListeners();
  }
}
