import 'package:shared_preferences/shared_preferences.dart';

import '../local/local_database.dart';
import '../models/user.dart';

class AuthRepository {
  final LocalDatabase _database;

  AuthRepository({LocalDatabase? database}) : _database = database ?? LocalDatabase();

  Future<AppUser> register({required String email, required String password}) async {
    final employeeMap = await _database.fetchEmployeeByEmail(email);
    if (employeeMap == null) {
      throw Exception('Email не зарегистрирован администратором');
    }
    if (employeeMap['user_id'] != null) {
      throw Exception('Для этой почты уже есть аккаунт');
    }

    final id = await _database.insertUser(email: email, password: password);
    await _database.attachUserToEmployee(employeeId: employeeMap['id'] as int, userId: id);
    final user = AppUser(id: id, email: email);
    await _cacheUserId(id);
    return user;
  }

  Future<AppUser> login({required String email, required String password}) async {
    final map = await _database.getUserByEmail(email);
    if (map == null) {
      throw Exception('Пользователь не найден');
    }
    if (map['password'] != password) {
      throw Exception('Неверный пароль');
    }
    final user = AppUser(id: map['id'] as int, email: map['email'] as String);

    final employeeMap = await _database.fetchEmployeeByEmail(email);
    if (employeeMap == null) {
      throw Exception('Email не зарегистрирован администратором');
    }
    final boundUserId = employeeMap['user_id'] as int?;
    if (boundUserId != null && boundUserId != user.id) {
      throw Exception('Аккаунт для этой почты привязан к другому пользователю');
    }
    if (boundUserId == null) {
      await _database.attachUserToEmployee(employeeId: employeeMap['id'] as int, userId: user.id);
    }
    await _cacheUserId(user.id);
    return user;
  }

  Future<AppUser?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('user_id');
    if (id == null) return null;
    final map = await _database.database.then((db) => db.query(
          'users',
          where: 'id = ?',
          whereArgs: [id],
          limit: 1,
        ));
    if (map.isEmpty) return null;
    final user = AppUser.fromMap(map.first);
    final employeeMap = await _database.fetchEmployeeByEmail(user.email);
    if (employeeMap == null) return null;
    final boundUserId = employeeMap['user_id'] as int?;
    if (boundUserId != null && boundUserId != user.id) return null;
    if (boundUserId == null) {
      await _database.attachUserToEmployee(employeeId: employeeMap['id'] as int, userId: user.id);
    }
    return user;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
  }

  Future<void> _cacheUserId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', id);
  }
}
