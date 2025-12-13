import 'package:equatable/equatable.dart';

class AccountingEntry extends Equatable {
  final int id;
  final int companyId;
  final String targetType;
  final int targetId;
  final double delta;
  final String note;
  final DateTime createdAt;

  const AccountingEntry({
    required this.id,
    required this.companyId,
    required this.targetType,
    required this.targetId,
    required this.delta,
    required this.note,
    required this.createdAt,
  });

  factory AccountingEntry.fromMap(Map<String, dynamic> map) => AccountingEntry(
        id: map['id'] as int,
        companyId: map['company_id'] as int,
        targetType: map['target_type'] as String,
        targetId: map['target_id'] as int,
        delta: (map['delta'] as num).toDouble(),
        note: map['note'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'company_id': companyId,
        'target_type': targetType,
        'target_id': targetId,
        'delta': delta,
        'note': note,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  @override
  List<Object?> get props => [id, companyId, targetType, targetId, delta, note, createdAt];
}
