import '../local/local_database.dart';
import '../models/accounting_entry.dart';

class AccountingRepository {
  final LocalDatabase _db;

  AccountingRepository({LocalDatabase? database}) : _db = database ?? LocalDatabase();

  Future<AccountingEntry> addEntry({
    required int companyId,
    required String targetType,
    required int targetId,
    required double delta,
    required String note,
  }) async {
    final id = await _db.addAccountingEntry(
      companyId: companyId,
      targetType: targetType,
      targetId: targetId,
      delta: delta,
      note: note,
    );

    return AccountingEntry(
      id: id,
      companyId: companyId,
      targetType: targetType,
      targetId: targetId,
      delta: delta,
      note: note,
      createdAt: DateTime.now(),
    );
  }

  Future<List<AccountingEntry>> fetchEntries(int companyId) async {
    final rows = await _db.fetchAccountingEntries(companyId);
    return rows.map(AccountingEntry.fromMap).toList();
  }
}
