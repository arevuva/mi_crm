import 'package:shared_preferences/shared_preferences.dart';

import '../local/local_database.dart';
import '../models/user.dart';

class AuthRepository {
  final LocalDatabase _database;

  AuthRepository({LocalDatabase? database}) : _database = database ?? LocalDatabase();

  Future<AppUser> register({required String email, required String password}) async {
    final id = await _database.insertUser(email: email, password: password);
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
    return AppUser.fromMap(map.first);
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
