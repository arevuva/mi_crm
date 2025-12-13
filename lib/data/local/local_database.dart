import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/module.dart';
import '../models/operation.dart';

class LocalDatabase {
  static final LocalDatabase _instance = LocalDatabase._internal();
  factory LocalDatabase() => _instance;
  LocalDatabase._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final path = join(docsDir.path, 'mi_crm.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE,
            password TEXT
          );
        ''');

        await db.execute('''
          CREATE TABLE operations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT,
            amount REAL,
            description TEXT,
            created_at INTEGER
          );
        ''');

        await _createModulesTable(db);
        await _seedModules(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createModulesTable(db);
          await _seedModules(db);
        }
      },
    );
  }

  Future<int> insertUser({required String email, required String password}) async {
    final db = await database;
    return db.insert(
      'users',
      {'email': email, 'password': password},
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return maps.first;
  }

  Future<List<Operation>> fetchOperations() async {
    final db = await database;
    final maps = await db.query('operations', orderBy: 'created_at DESC');
    return maps.map(Operation.fromMap).toList();
  }

  Future<int> insertOperation(Operation operation) async {
    final db = await database;
    return db.insert('operations', operation.toMap());
  }

  Future<void> clear() async {
    final db = await database;
    await db.delete('operations');
    await db.delete('users');
  }

  Future<List<CRMModule>> fetchModules() async {
    final db = await database;
    final maps = await db.query('modules', orderBy: 'sort_order ASC');
    return maps.map(CRMModule.fromMap).toList();
  }

  Future<void> updateModule(CRMModule module) async {
    final db = await database;
    await db.update(
      'modules',
      module.toMap(),
      where: 'id = ?',
      whereArgs: [module.id],
    );
  }

  Future<void> _createModulesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS modules (
        id TEXT PRIMARY KEY,
        title TEXT,
        description TEXT,
        enabled INTEGER,
        sort_order INTEGER
      );
    ''');
  }

  Future<void> _seedModules(Database db) async {
    final defaults = CRMModule.defaultModules;
    for (var i = 0; i < defaults.length; i++) {
      final module = defaults[i];
      await db.insert(
        'modules',
        module.copyWith(sortOrder: i).toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }
}
