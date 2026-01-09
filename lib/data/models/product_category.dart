import 'package:equatable/equatable.dart';

class ProductCategory extends Equatable {
  final int id;
  final int companyId;
  final String title;

  const ProductCategory({required this.id, required this.companyId, required this.title});

  factory ProductCategory.fromMap(Map<String, dynamic> map) {
    return ProductCategory(
      id: map['id'] as int,
      companyId: map['company_id'] as int,
      title: map['title'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'company_id': companyId,
        'title': title,
      };

  @override
  List<Object?> get props => [id, companyId, title];
}
