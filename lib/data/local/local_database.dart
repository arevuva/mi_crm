import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

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
      version: 1,
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
}
