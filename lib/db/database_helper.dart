import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Gère l'ouverture et la migration de la base SQLite (sqflite).
/// Fonctionne aussi bien sur Android (sqflite natif) que sur Web
/// (sqflite_common_ffi_web + sqlite3.wasm), permettant l'usage hors-ligne.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'big_bag_manager.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    DatabaseFactory factory;
    String path;

    if (kIsWeb) {
      factory = databaseFactoryFfiWeb;
      path = _dbName;
    } else {
      factory = databaseFactory;
      // On desktop/mobile, use the default app documents directory via sqflite's
      // own path resolution when available; fall back to plain filename.
      try {
        final dbPath = await getDatabasesPathSafe();
        path = p.join(dbPath, _dbName);
      } catch (_) {
        path = _dbName;
      }
    }

    return factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  Future<String> getDatabasesPathSafe() async {
    return await getDatabasesPath();
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE big_bags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        poids_brut REAL NOT NULL,
        qualite TEXT,
        status TEXT NOT NULL DEFAULT 'stock',
        created_at TEXT NOT NULL,
        chargement_id INTEGER
      );
    ''');

    await db.execute('''
      CREATE TABLE chargements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client TEXT NOT NULL,
        camion TEXT,
        chauffeur TEXT,
        status TEXT NOT NULL DEFAULT 'actif',
        created_at TEXT NOT NULL,
        closed_at TEXT,
        bon_numero TEXT
      );
    ''');

    await db.execute('CREATE INDEX idx_bb_status ON big_bags(status);');
    await db.execute(
      'CREATE INDEX idx_bb_chargement ON big_bags(chargement_id);',
    );
    await db.execute('CREATE INDEX idx_ch_status ON chargements(status);');

    debugPrint('[DB] Tables created (big_bags, chargements)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Réservé pour futures migrations.
  }

  /// Réinitialise toutes les données (utilisé depuis Réglages).
  Future<void> resetAll() async {
    final db = await database;
    await db.delete('big_bags');
    await db.delete('chargements');
  }
}
