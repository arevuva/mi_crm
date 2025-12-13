import 'package:equatable/equatable.dart';

enum OperationType { sale, purchase, expense }

class Operation extends Equatable {
  final int? id;
  final OperationType type;
  final double amount;
  final String description;
  final DateTime createdAt;

  const Operation({
    this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.createdAt,
  });

  Operation copyWith({
    int? id,
    OperationType? type,
    double? amount,
    String? description,
    DateTime? createdAt,
  }) {
    return Operation(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'amount': amount,
      'description': description,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Operation.fromMap(Map<String, dynamic> map) {
    return Operation(
      id: map['id'] as int?,
      type: OperationType.values
          .firstWhere((element) => element.name == map['type'] as String),
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String,
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  @override
  List<Object?> get props => [id, type, amount, description, createdAt];
}
