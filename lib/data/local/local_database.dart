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
      version: 5,
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
            owner_ids TEXT,
            created_at INTEGER
          );
        ''');

        await _createModulesTable(db);
        await _seedModules(db);
        await _createCompanyTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createModulesTable(db);
          await _seedModules(db);
        }
        if (oldVersion < 3) {
          await _createCompanyTables(db);
        }
        if (oldVersion < 4) {
          await _upgradeEmployeesWithEmail(db);
        }
        if (oldVersion < 5) {
          await db.execute('ALTER TABLE operations ADD COLUMN owner_ids TEXT');
          await db.execute('ALTER TABLE sales_records ADD COLUMN owner_ids TEXT');
          await db.execute('ALTER TABLE documents ADD COLUMN owner_ids TEXT');
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

  Future<void> _createCompanyTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS companies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        created_at INTEGER
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS positions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        company_id INTEGER,
        title TEXT,
        modules TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS employees (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        company_id INTEGER,
        email TEXT UNIQUE,
        name TEXT,
        position_id INTEGER,
        status TEXT,
        user_id INTEGER
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS product_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        company_id INTEGER,
        title TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        company_id INTEGER,
        category_id INTEGER,
        title TEXT,
        price REAL,
        stock INTEGER,
        reserved INTEGER
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS leads (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        company_id INTEGER,
        name TEXT,
        contact TEXT,
        status TEXT,
        product_id INTEGER
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sales_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        company_id INTEGER,
        product_id INTEGER,
        type TEXT,
        quantity INTEGER,
        amount REAL,
        note TEXT,
        created_at INTEGER
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        company_id INTEGER,
        product_id INTEGER,
        type TEXT,
        title TEXT,
        note TEXT,
        created_at INTEGER
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS pr_assets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER,
        company_id INTEGER,
        title TEXT,
        note TEXT,
        created_at INTEGER
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS smm_posts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        company_id INTEGER,
        product_id INTEGER,
        channel TEXT,
        message TEXT,
        status TEXT,
        created_at INTEGER
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS accounting_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        company_id INTEGER,
        target_type TEXT,
        target_id INTEGER,
        delta REAL,
        note TEXT,
        created_at INTEGER
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

  Future<int> createCompany(String name) async {
    final db = await database;
    return db.insert('companies', {
      'name': name,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<Map<String, dynamic>?> fetchCompany() async {
    final db = await database;
    final rows = await db.query('companies', limit: 1, orderBy: 'id ASC');
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<int> addPosition({required int companyId, required String title, required List<String> modules}) async {
    final db = await database;
    return db.insert('positions', {
      'company_id': companyId,
      'title': title,
      'modules': modules.join(','),
    });
  }

  Future<List<Map<String, dynamic>>> fetchPositions(int companyId) async {
    final db = await database;
    return db.query('positions', where: 'company_id = ?', whereArgs: [companyId], orderBy: 'id DESC');
  }

  Future<int> addEmployee({
    required int companyId,
    required String email,
    required String name,
    required int positionId,
    required String status,
  }) async {
    final db = await database;
    return db.insert('employees', {
      'company_id': companyId,
      'email': email,
      'name': name,
      'position_id': positionId,
      'status': status,
    });
  }

  Future<List<Map<String, dynamic>>> fetchEmployees(int companyId) async {
    final db = await database;
    return db.query('employees', where: 'company_id = ?', whereArgs: [companyId], orderBy: 'id DESC');
  }

  Future<Map<String, dynamic>?> fetchEmployeeByEmail(String email) async {
    final db = await database;
    final rows = await db.query(
      'employees',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<void> attachUserToEmployee({required int employeeId, required int userId}) async {
    final db = await database;
    await db.update('employees', {'user_id': userId}, where: 'id = ?', whereArgs: [employeeId]);
  }

  Future<void> updateEmployeeStatus(int employeeId, String status) async {
    final db = await database;
    await db.update('employees', {'status': status}, where: 'id = ?', whereArgs: [employeeId]);
  }

  Future<int> addCategory({required int companyId, required String title}) async {
    final db = await database;
    return db.insert('product_categories', {
      'company_id': companyId,
      'title': title,
    });
  }

  Future<List<Map<String, dynamic>>> fetchCategories(int companyId) async {
    final db = await database;
    return db.query('product_categories', where: 'company_id = ?', whereArgs: [companyId], orderBy: 'id DESC');
  }

  Future<int> addProduct({
    required int companyId,
    required int categoryId,
    required String title,
    required double price,
    required int stock,
    int reserved = 0,
  }) async {
    final db = await database;
    return db.insert('products', {
      'company_id': companyId,
      'category_id': categoryId,
      'title': title,
      'price': price,
      'stock': stock,
      'reserved': reserved,
    });
  }

  Future<void> updateProductReservation(int productId, int reserved) async {
    final db = await database;
    await db.update('products', {'reserved': reserved}, where: 'id = ?', whereArgs: [productId]);
  }

  Future<void> updateProductPrice(int productId, double price) async {
    final db = await database;
    await db.update('products', {'price': price}, where: 'id = ?', whereArgs: [productId]);
  }

  Future<List<Map<String, dynamic>>> fetchProducts(int companyId) async {
    final db = await database;
    return db.query('products', where: 'company_id = ?', whereArgs: [companyId], orderBy: 'id DESC');
  }

  Future<int> addLead({
    required int companyId,
    required String name,
    required String contact,
    required String status,
    int? productId,
  }) async {
    final db = await database;
    return db.insert('leads', {
      'company_id': companyId,
      'name': name,
      'contact': contact,
      'status': status,
      'product_id': productId,
    });
  }

  Future<List<Map<String, dynamic>>> fetchLeads(int companyId) async {
    final db = await database;
    return db.query('leads', where: 'company_id = ?', whereArgs: [companyId], orderBy: 'id DESC');
  }

  Future<int> addSalesRecord({
    required int companyId,
    required String type,
    required int quantity,
    required double amount,
    String? note,
    int? productId,
    String? ownerIds,
  }) async {
    final db = await database;
    return db.insert('sales_records', {
      'company_id': companyId,
      'product_id': productId,
      'type': type,
      'quantity': quantity,
      'amount': amount,
      'note': note,
      'owner_ids': ownerIds,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String, dynamic>>> fetchSalesRecords(int companyId) async {
    final db = await database;
    return db.query('sales_records', where: 'company_id = ?', whereArgs: [companyId], orderBy: 'created_at DESC');
  }

  Future<int> addDocument({
    required int companyId,
    required String type,
    required String title,
    String? note,
    int? productId,
    String? ownerIds,
  }) async {
    final db = await database;
    return db.insert('documents', {
      'company_id': companyId,
      'product_id': productId,
      'type': type,
      'title': title,
      'note': note,
      'owner_ids': ownerIds,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String, dynamic>>> fetchDocuments(int companyId) async {
    final db = await database;
    return db.query('documents', where: 'company_id = ?', whereArgs: [companyId], orderBy: 'created_at DESC');
  }

  Future<int> addPrAsset({
    required int companyId,
    required String title,
    String? note,
    int? productId,
  }) async {
    final db = await database;
    return db.insert('pr_assets', {
      'company_id': companyId,
      'product_id': productId,
      'title': title,
      'note': note,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String, dynamic>>> fetchPrAssets(int companyId) async {
    final db = await database;
    return db.query('pr_assets', where: 'company_id = ?', whereArgs: [companyId], orderBy: 'created_at DESC');
  }

  Future<int> addSmmPost({
    required int companyId,
    required String channel,
    required String message,
    String status = 'draft',
    int? productId,
  }) async {
    final db = await database;
    return db.insert('smm_posts', {
      'company_id': companyId,
      'product_id': productId,
      'channel': channel,
      'message': message,
      'status': status,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String, dynamic>>> fetchSmmPosts(int companyId) async {
    final db = await database;
    return db.query('smm_posts', where: 'company_id = ?', whereArgs: [companyId], orderBy: 'created_at DESC');
  }

  Future<int> addAccountingEntry({
    required int companyId,
    required String targetType,
    required int targetId,
    required double delta,
    required String note,
  }) async {
    final db = await database;
    return db.insert('accounting_entries', {
      'company_id': companyId,
      'target_type': targetType,
      'target_id': targetId,
      'delta': delta,
      'note': note,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String, dynamic>>> fetchAccountingEntries(int companyId) async {
    final db = await database;
    return db.query('accounting_entries', where: 'company_id = ?', whereArgs: [companyId], orderBy: 'created_at DESC');
  }

  Future<void> _upgradeEmployeesWithEmail(Database db) async {
    final existingColumns = await db.rawQuery('PRAGMA table_info(employees);');
    final hasEmail = existingColumns.any((row) => row['name'] == 'email');
    if (!hasEmail) {
      await db.execute('ALTER TABLE employees ADD COLUMN email TEXT;');
      await db.execute('ALTER TABLE employees ADD COLUMN user_id INTEGER;');
      await db.execute("UPDATE employees SET email = 'user_' || id || '@placeholder.local' WHERE email IS NULL OR email = '';");
      await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_employees_email ON employees(email);');
    }
  }
}
