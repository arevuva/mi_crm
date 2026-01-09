import 'package:equatable/equatable.dart';

class Company extends Equatable {
  final int id;
  final String name;
  final DateTime createdAt;

  const Company({required this.id, required this.name, required this.createdAt});

  factory Company.fromMap(Map<String, dynamic> map) {
    return Company(
      id: map['id'] as int,
      name: map['name'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  @override
  List<Object?> get props => [id, name, createdAt];
}
