import 'package:equatable/equatable.dart';

enum DocumentType { receipt, act, consumable, contract }

class DocumentEntry extends Equatable {
  final int id;
  final int companyId;
  final DocumentType type;
  final String title;
  final String? note;
  final int? productId;
  final DateTime createdAt;

  const DocumentEntry({
    required this.id,
    required this.companyId,
    required this.type,
    required this.title,
    required this.createdAt,
    this.note,
    this.productId,
  });

  factory DocumentEntry.fromMap(Map<String, dynamic> map) => DocumentEntry(
        id: map['id'] as int,
        companyId: map['company_id'] as int,
        productId: map['product_id'] as int?,
        type: DocumentType.values.firstWhere(
          (e) => e.name == map['type'] as String,
          orElse: () => DocumentType.receipt,
        ),
        title: map['title'] as String,
        note: map['note'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'company_id': companyId,
        'product_id': productId,
        'type': type.name,
        'title': title,
        'note': note,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  @override
  List<Object?> get props => [id, companyId, productId, type, title, note, createdAt];
}
