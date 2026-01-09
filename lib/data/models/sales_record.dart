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
  final List<int> ownerIds;
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
    this.ownerIds = const [],
  });

  factory SalesRecord.fromMap(Map<String, dynamic> map) => SalesRecord(
        id: map['id'] as int,
        companyId: map['company_id'] as int,
        productId: map['product_id'] as int?,
        ownerIds: ((map['owner_ids'] as String?) ?? '')
            .split(',')
            .where((e) => e.trim().isNotEmpty)
            .map((e) => int.tryParse(e) ?? 0)
            .where((e) => e > 0)
            .toList(),
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
        'owner_ids': ownerIds.join(','),
        'type': type.name,
        'quantity': quantity,
        'amount': amount,
        'note': note,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  @override
  List<Object?> get props =>
      [id, companyId, productId, ownerIds, type, quantity, amount, note, createdAt];
}
