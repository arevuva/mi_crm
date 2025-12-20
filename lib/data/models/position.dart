import 'package:equatable/equatable.dart';

class Position extends Equatable {
  final int id;
  final int companyId;
  final String title;
  final List<String> modules;
  final bool isHead;

  const Position({
    required this.id,
    required this.companyId,
    required this.title,
    required this.modules,
    this.isHead = false,
  });

  factory Position.fromMap(Map<String, dynamic> map) {
    return Position(
      id: map['id'] as int,
      companyId: map['company_id'] as int,
      title: map['title'] as String,
      modules: (map['modules'] as String?)?.split(',').where((e) => e.isNotEmpty).toList() ?? [],
      isHead: (map['is_head'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'company_id': companyId,
        'title': title,
        'modules': modules.join(','),
        'is_head': isHead ? 1 : 0,
      };

  @override
  List<Object?> get props => [id, companyId, title, modules, isHead];
}
