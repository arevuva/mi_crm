import 'package:equatable/equatable.dart';

class PrAsset extends Equatable {
  final int id;
  final int companyId;
  final int? productId;
  final String title;
  final String? note;
  final DateTime createdAt;

  const PrAsset({
    required this.id,
    required this.companyId,
    this.productId,
    required this.title,
    this.note,
    required this.createdAt,
  });

  factory PrAsset.fromMap(Map<String, dynamic> map) => PrAsset(
        id: map['id'] as int,
        companyId: map['company_id'] as int,
        productId: map['product_id'] as int?,
        title: map['title'] as String,
        note: map['note'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'company_id': companyId,
        'product_id': productId,
        'title': title,
        'note': note,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  @override
  List<Object?> get props => [id, companyId, productId, title, note, createdAt];
}
