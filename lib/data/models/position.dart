import 'package:equatable/equatable.dart';

class Position extends Equatable {
  final int id;
  final int companyId;
  final String title;
  final List<String> modules;

  const Position({
    required this.id,
    required this.companyId,
    required this.title,
    required this.modules,
  });

  factory Position.fromMap(Map<String, dynamic> map) {
    return Position(
      id: map['id'] as int,
      companyId: map['company_id'] as int,
      title: map['title'] as String,
      modules: (map['modules'] as String?)?.split(',').where((e) => e.isNotEmpty).toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'company_id': companyId,
        'title': title,
        'modules': modules.join(','),
      };

  @override
  List<Object?> get props => [id, companyId, title, modules];
}
