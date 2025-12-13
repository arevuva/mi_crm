import '../local/local_database.dart';
import '../models/lead.dart';
import '../models/product.dart';
import '../models/product_category.dart';
import '../models/sales_record.dart';

class SalesRepository {
  final LocalDatabase _db;

  SalesRepository({LocalDatabase? database}) : _db = database ?? LocalDatabase();

  Future<List<ProductCategory>> fetchCategories(int companyId) async {
    final rows = await _db.fetchCategories(companyId);
    return rows.map(ProductCategory.fromMap).toList();
  }

  Future<ProductCategory> addCategory({required int companyId, required String title}) async {
    final id = await _db.addCategory(companyId: companyId, title: title);
    return ProductCategory(id: id, companyId: companyId, title: title);
  }

  Future<List<Product>> fetchProducts(int companyId) async {
    final rows = await _db.fetchProducts(companyId);
    return rows.map(Product.fromMap).toList();
  }

  Future<Product> addProduct({
    required int companyId,
    required int categoryId,
    required String title,
    required double price,
    required int stock,
  }) async {
    final id = await _db.addProduct(
      companyId: companyId,
      categoryId: categoryId,
      title: title,
      price: price,
      stock: stock,
    );
    return Product(
      id: id,
      companyId: companyId,
      categoryId: categoryId,
      title: title,
      price: price,
      stock: stock,
      reserved: 0,
    );
  }

  Future<void> reserveProduct(int productId, int reserved) async {
    await _db.updateProductReservation(productId, reserved);
  }

  Future<void> updatePrice(int productId, double price) async {
    await _db.updateProductPrice(productId, price);
  }

  Future<List<Lead>> fetchLeads(int companyId) async {
    final rows = await _db.fetchLeads(companyId);
    return rows.map(Lead.fromMap).toList();
  }

  Future<Lead> addLead({
    required int companyId,
    required String name,
    required String contact,
    required String status,
    int? productId,
  }) async {
    final id = await _db.addLead(
      companyId: companyId,
      name: name,
      contact: contact,
      status: status,
      productId: productId,
    );
    return Lead(
      id: id,
      companyId: companyId,
      name: name,
      contact: contact,
      status: status,
      productId: productId,
    );
  }

  Future<List<SalesRecord>> fetchSalesRecords(int companyId) async {
    final rows = await _db.fetchSalesRecords(companyId);
    return rows.map(SalesRecord.fromMap).toList();
  }

  Future<SalesRecord> addRecord({
    required int companyId,
    required SalesRecordType type,
    required int quantity,
    required double amount,
    String? note,
    int? productId,
  }) async {
    final id = await _db.addSalesRecord(
      companyId: companyId,
      type: type.name,
      quantity: quantity,
      amount: amount,
      note: note,
      productId: productId,
    );

    return SalesRecord(
      id: id,
      companyId: companyId,
      type: type,
      quantity: quantity,
      amount: amount,
      note: note,
      productId: productId,
      createdAt: DateTime.now(),
    );
  }
}
