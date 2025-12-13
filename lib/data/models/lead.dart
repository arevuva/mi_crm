import 'package:equatable/equatable.dart';

class Lead extends Equatable {
  final int id;
  final int companyId;
  final String name;
  final String contact;
  final String status;
  final int? productId;

  const Lead({
    required this.id,
    required this.companyId,
    required this.name,
    required this.contact,
    required this.status,
    this.productId,
  });

  factory Lead.fromMap(Map<String, dynamic> map) => Lead(
        id: map['id'] as int,
        companyId: map['company_id'] as int,
        name: map['name'] as String,
        contact: map['contact'] as String,
        status: map['status'] as String,
        productId: map['product_id'] as int?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'company_id': companyId,
        'name': name,
        'contact': contact,
        'status': status,
        'product_id': productId,
      };

  @override
  List<Object?> get props => [id, companyId, name, contact, status, productId];
}
