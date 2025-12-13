import '../local/local_database.dart';
import '../models/operation.dart';

class OperationRepository {
  final LocalDatabase _database;

  OperationRepository({LocalDatabase? database})
      : _database = database ?? LocalDatabase();

  Future<List<Operation>> loadOperations() => _database.fetchOperations();

  Future<Operation> addOperation(Operation operation) async {
    final id = await _database.insertOperation(operation);
    return operation.copyWith(id: id);
  }
}
