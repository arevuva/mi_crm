import 'dart:convert';

import 'package:equatable/equatable.dart';

class Position extends Equatable {
  final int id;
  final int companyId;
  final String title;
  final List<String> modules;
  final bool isHead;
  final Map<String, List<String>> submodules;

  const Position({
    required this.id,
    required this.companyId,
    required this.title,
    required this.modules,
    this.isHead = false,
    this.submodules = const {},
  });

  factory Position.fromMap(Map<String, dynamic> map) {
    final rawSubmodules = map['submodules'] as String?;
    Map<String, List<String>> parsedSubmodules = {};
    if (rawSubmodules != null && rawSubmodules.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawSubmodules) as Map<String, dynamic>;
        parsedSubmodules = decoded.map(
          (key, value) => MapEntry(
            key,
            (value as List<dynamic>).map((e) => e.toString()).toList(),
          ),
        );
      } catch (_) {
        parsedSubmodules = {};
      }
    }

    return Position(
      id: map['id'] as int,
      companyId: map['company_id'] as int,
      title: map['title'] as String,
      modules: (map['modules'] as String?)?.split(',').where((e) => e.isNotEmpty).toList() ?? [],
      isHead: (map['is_head'] as int? ?? 0) == 1,
      submodules: parsedSubmodules,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'company_id': companyId,
        'title': title,
        'modules': modules.join(','),
        'is_head': isHead ? 1 : 0,
        'submodules': jsonEncode(submodules),
      };

  Position copyWith({
    String? title,
    List<String>? modules,
    bool? isHead,
    Map<String, List<String>>? submodules,
  }) {
    return Position(
      id: id,
      companyId: companyId,
      title: title ?? this.title,
      modules: modules ?? this.modules,
      isHead: isHead ?? this.isHead,
      submodules: submodules ?? this.submodules,
    );
  }

  @override
  List<Object?> get props => [id, companyId, title, modules, isHead, submodules];
}
