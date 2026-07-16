import 'package:sqflite/sqflite.dart';
import '../models/chargement.dart';
import 'database_helper.dart';

/// Accès aux données Chargements (table chargements).
class ChargementDao {
  final DatabaseHelper _helper;
  ChargementDao([DatabaseHelper? helper])
    : _helper = helper ?? DatabaseHelper.instance;

  Future<Database> get _db async => _helper.database;

  Future<Chargement> create({
    required String client,
    String? camion,
    String? chauffeur,
  }) async {
    final db = await _db;
    final now = DateTime.now();
    final id = await db.insert('chargements', {
      'client': client,
      'camion': camion,
      'chauffeur': chauffeur,
      'status': ChargementStatus.actif.dbValue,
      'created_at': now.toIso8601String(),
      'closed_at': null,
      'bon_numero': null,
    });
    return Chargement(
      id: id,
      client: client,
      camion: camion,
      chauffeur: chauffeur,
      status: ChargementStatus.actif,
      createdAt: now,
    );
  }

  Future<List<Chargement>> getActiveOrPaused() async {
    final db = await _db;
    final rows = await db.query(
      'chargements',
      where: 'status IN (?, ?)',
      whereArgs: [
        ChargementStatus.actif.dbValue,
        ChargementStatus.pause.dbValue,
      ],
      orderBy: 'id DESC',
    );
    return rows.map(Chargement.fromMap).toList();
  }

  Future<List<Chargement>> getTerminated() async {
    final db = await _db;
    final rows = await db.query(
      'chargements',
      where: 'status = ?',
      whereArgs: [ChargementStatus.termine.dbValue],
      orderBy: 'id DESC',
    );
    return rows.map(Chargement.fromMap).toList();
  }

  Future<Chargement?> getById(int id) async {
    final db = await _db;
    final rows = await db.query(
      'chargements',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Chargement.fromMap(rows.first);
  }

  Future<void> setStatus(int id, ChargementStatus status) async {
    final db = await _db;
    await db.update(
      'chargements',
      {'status': status.dbValue},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Termine un chargement : status=termine, closed_at=now, bon_numero généré
  /// à partir du prochain numéro (MAX+1 sur les chargements déjà terminés).
  Future<Chargement> finish(int id) async {
    final db = await _db;
    return db.transaction((txn) async {
      final res = await txn.rawQuery(
        "SELECT COUNT(*) as cnt FROM chargements WHERE status = 'termine'",
      );
      final cnt = res.first['cnt'] as int;
      final bonNumero = Chargement.padBon(cnt + 1);
      final closedAt = DateTime.now();

      await txn.update(
        'chargements',
        {
          'status': ChargementStatus.termine.dbValue,
          'closed_at': closedAt.toIso8601String(),
          'bon_numero': bonNumero,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      final rows = await txn.query(
        'chargements',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      return Chargement.fromMap(rows.first);
    });
  }

  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete('chargements', where: 'id = ?', whereArgs: [id]);
  }
}
