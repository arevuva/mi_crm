import '../local/local_database.dart';
import '../models/document_entry.dart';

class DocumentRepository {
  final LocalDatabase _db;

  DocumentRepository({LocalDatabase? database}) : _db = database ?? LocalDatabase();

  Future<DocumentEntry> addDocument({
    required int companyId,
    required DocumentType type,
    required String title,
    String? note,
    int? productId,
  }) async {
    final id = await _db.addDocument(
      companyId: companyId,
      type: type.name,
      title: title,
      note: note,
      productId: productId,
    );

    return DocumentEntry(
      id: id,
      companyId: companyId,
      type: type,
      title: title,
      note: note,
      productId: productId,
      createdAt: DateTime.now(),
    );
  }

  Future<List<DocumentEntry>> fetchDocuments(int companyId) async {
    final rows = await _db.fetchDocuments(companyId);
    return rows.map(DocumentEntry.fromMap).toList();
  }
}
