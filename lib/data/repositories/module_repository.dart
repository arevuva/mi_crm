import '../local/local_database.dart';
import '../models/module.dart';

class ModuleRepository {
  final LocalDatabase _database;

  ModuleRepository({LocalDatabase? database}) : _database = database ?? LocalDatabase();

  Future<List<CRMModule>> fetchModules() => _database.fetchModules();

  Future<void> toggleModule(CRMModule module, bool enabled) async {
    await _database.updateModule(module.copyWith(enabled: enabled));
  }

  Future<void> updateModule(CRMModule module) async {
    await _database.updateModule(module);
  }
}
