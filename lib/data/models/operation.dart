import 'package:equatable/equatable.dart';

enum OperationType { sale, purchase, expense }

class Operation extends Equatable {
  final int? id;
  final OperationType type;
  final double amount;
  final String description;
  final List<int> ownerIds;
  final DateTime createdAt;

  const Operation({
    this.id,
    required this.type,
    required this.amount,
    required this.description,
    this.ownerIds = const [],
    required this.createdAt,
  });

  Operation copyWith({
    int? id,
    OperationType? type,
    double? amount,
    String? description,
    List<int>? ownerIds,
    DateTime? createdAt,
  }) {
    return Operation(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      ownerIds: ownerIds ?? this.ownerIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'amount': amount,
      'description': description,
      'owner_ids': ownerIds.join(','),
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Operation.fromMap(Map<String, dynamic> map) {
    final rawOwners = map['owner_ids'] as String?;
    final owners = (rawOwners ?? '')
        .split(',')
        .where((e) => e.trim().isNotEmpty)
        .map((e) => int.tryParse(e) ?? 0)
        .where((e) => e > 0)
        .toList();
    return Operation(
      id: map['id'] as int?,
      type: OperationType.values
          .firstWhere((element) => element.name == map['type'] as String),
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String,
      ownerIds: owners,
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  @override
  List<Object?> get props => [id, type, amount, description, ownerIds, createdAt];
}
