import 'package:equatable/equatable.dart';

enum SalesRecordType { sale, income, reservation }

class SalesRecord extends Equatable {
  final int id;
  final int companyId;
  final SalesRecordType type;
  final int quantity;
  final double amount;
  final String? note;
  final int? productId;
  final DateTime createdAt;

  const SalesRecord({
    required this.id,
    required this.companyId,
    required this.type,
    required this.quantity,
    required this.amount,
    required this.createdAt,
    this.note,
    this.productId,
  });

  factory SalesRecord.fromMap(Map<String, dynamic> map) => SalesRecord(
        id: map['id'] as int,
        companyId: map['company_id'] as int,
        productId: map['product_id'] as int?,
        type: SalesRecordType.values.firstWhere(
          (e) => e.name == map['type'] as String,
          orElse: () => SalesRecordType.sale,
        ),
        quantity: map['quantity'] as int,
        amount: (map['amount'] as num).toDouble(),
        note: map['note'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'company_id': companyId,
        'product_id': productId,
        'type': type.name,
        'quantity': quantity,
        'amount': amount,
        'note': note,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  @override
  List<Object?> get props => [id, companyId, productId, type, quantity, amount, note, createdAt];
}
