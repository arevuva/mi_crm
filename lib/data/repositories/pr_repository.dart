import '../local/local_database.dart';
import '../models/pr_asset.dart';
import '../models/smm_post.dart';

class PrRepository {
  final LocalDatabase _db;

  PrRepository({LocalDatabase? database}) : _db = database ?? LocalDatabase();

  Future<PrAsset> addAsset({
    required int companyId,
    required String title,
    String? note,
    int? productId,
  }) async {
    final id = await _db.addPrAsset(
      companyId: companyId,
      title: title,
      note: note,
      productId: productId,
    );

    return PrAsset(
      id: id,
      companyId: companyId,
      productId: productId,
      title: title,
      note: note,
      createdAt: DateTime.now(),
    );
  }

  Future<List<PrAsset>> fetchAssets(int companyId) async {
    final rows = await _db.fetchPrAssets(companyId);
    return rows.map(PrAsset.fromMap).toList();
  }

  Future<SmmPost> addPost({
    required int companyId,
    required String channel,
    required String message,
    String status = 'draft',
    int? productId,
  }) async {
    final id = await _db.addSmmPost(
      companyId: companyId,
      channel: channel,
      message: message,
      status: status,
      productId: productId,
    );

    return SmmPost(
      id: id,
      companyId: companyId,
      productId: productId,
      channel: channel,
      message: message,
      status: status,
      createdAt: DateTime.now(),
    );
  }

  Future<List<SmmPost>> fetchPosts(int companyId) async {
    final rows = await _db.fetchSmmPosts(companyId);
    return rows.map(SmmPost.fromMap).toList();
  }
}
