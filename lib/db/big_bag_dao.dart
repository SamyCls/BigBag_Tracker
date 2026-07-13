import 'package:sqflite/sqflite.dart';
import '../models/big_bag.dart';
import 'database_helper.dart';

/// Accès aux données Big Bags (table big_bags).
class BigBagDao {
  final DatabaseHelper _helper;
  BigBagDao([DatabaseHelper? helper])
    : _helper = helper ?? DatabaseHelper.instance;

  Future<Database> get _db async => _helper.database;

  /// Crée un nouveau Big Bag. L'ID/code est auto-généré à partir du
  /// prochain compteur disponible (MAX(id)+1), garantissant BB-000001, etc.
  Future<BigBag> create({
    required double poidsBrut,
    required Quality qualite,
  }) async {
    final db = await _db;
    return db.transaction((txn) async {
      final res = await txn.rawQuery(
        'SELECT COALESCE(MAX(id), 0) + 1 as nextId FROM big_bags',
      );
      final nextId = res.first['nextId'] as int;
      final code = BigBag.padCode(nextId);
      final now = DateTime.now();

      final id = await txn.insert('big_bags', {
        'code': code,
        'poids_brut': poidsBrut,
        'qualite': qualite.dbValue,
        'status': BigBagStatus.stock.dbValue,
        'created_at': now.toIso8601String(),
        'chargement_id': null,
      });

      return BigBag(
        id: id,
        code: code,
        poidsBrut: poidsBrut,
        qualite: qualite,
        status: BigBagStatus.stock,
        createdAt: now,
      );
    });
  }

  /// Renvoie le prochain code prévu (pour affichage avant validation).
  Future<String> peekNextCode() async {
    final db = await _db;
    final res = await db.rawQuery(
      'SELECT COALESCE(MAX(id), 0) + 1 as nextId FROM big_bags',
    );
    final nextId = res.first['nextId'] as int;
    return BigBag.padCode(nextId);
  }

  Future<List<BigBag>> getAll({BigBagStatus? status}) async {
    final db = await _db;
    final rows = await db.query(
      'big_bags',
      where: status != null ? 'status = ?' : null,
      whereArgs: status != null ? [status.dbValue] : null,
      orderBy: 'id DESC',
    );
    return rows.map(BigBag.fromMap).toList();
  }

  Future<BigBag?> getByCode(String code) async {
    final db = await _db;
    final rows = await db.query(
      'big_bags',
      where: 'code = ?',
      whereArgs: [code],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return BigBag.fromMap(rows.first);
  }

  Future<List<BigBag>> getByChargement(int chargementId) async {
    final db = await _db;
    final rows = await db.query(
      'big_bags',
      where: 'chargement_id = ?',
      whereArgs: [chargementId],
      orderBy: 'id ASC',
    );
    return rows.map(BigBag.fromMap).toList();
  }

  Future<void> updateStatus(
    int id,
    BigBagStatus status, {
    int? chargementId,
    bool clearChargementId = false,
  }) async {
    final db = await _db;
    await db.update(
      'big_bags',
      {
        'status': status.dbValue,
        'chargement_id': clearChargementId ? null : chargementId,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Stats globales pour le tableau de Stock.
  Future<Map<String, Object?>> stats() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT
        status,
        COUNT(*) as cnt,
        COALESCE(SUM(poids_brut), 0) as poids
      FROM big_bags GROUP BY status
    ''');
    final result = <String, Object?>{
      'stock_count': 0,
      'stock_poids': 0.0,
      'charge_count': 0,
      'expedie_count': 0,
      'total_count': 0,
    };
    var total = 0;
    for (final r in rows) {
      final status = r['status'] as String;
      final cnt = r['cnt'] as int;
      total += cnt;
      if (status == 'stock') {
        result['stock_count'] = cnt;
        result['stock_poids'] = (r['poids'] as num).toDouble();
      } else if (status == 'charge') {
        result['charge_count'] = cnt;
      } else if (status == 'expedie') {
        result['expedie_count'] = cnt;
      }
    }
    result['total_count'] = total;
    return result;
  }
}
