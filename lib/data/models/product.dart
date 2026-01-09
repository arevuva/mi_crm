import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final int id;
  final int companyId;
  final int categoryId;
  final String title;
  final double price;
  final int stock;
  final int reserved;

  const Product({
    required this.id,
    required this.companyId,
    required this.categoryId,
    required this.title,
    required this.price,
    required this.stock,
    required this.reserved,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int,
      companyId: map['company_id'] as int,
      categoryId: map['category_id'] as int,
      title: map['title'] as String,
      price: (map['price'] as num).toDouble(),
      stock: (map['stock'] as int?) ?? 0,
      reserved: (map['reserved'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'company_id': companyId,
        'category_id': categoryId,
        'title': title,
        'price': price,
        'stock': stock,
        'reserved': reserved,
      };

  Product copyWith({double? price, int? stock, int? reserved}) => Product(
        id: id,
        companyId: companyId,
        categoryId: categoryId,
        title: title,
        price: price ?? this.price,
        stock: stock ?? this.stock,
        reserved: reserved ?? this.reserved,
      );

  @override
  List<Object?> get props => [id, companyId, categoryId, title, price, stock, reserved];
}
