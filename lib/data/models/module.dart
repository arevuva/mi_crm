import 'package:equatable/equatable.dart';

class CRMModule extends Equatable {
  final String id;
  final String title;
  final String description;
  final bool enabled;
  final int sortOrder;

  const CRMModule({
    required this.id,
    required this.title,
    required this.description,
    required this.enabled,
    required this.sortOrder,
  });

  CRMModule copyWith({
    String? title,
    String? description,
    bool? enabled,
    int? sortOrder,
  }) {
    return CRMModule(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      enabled: enabled ?? this.enabled,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  factory CRMModule.fromMap(Map<String, dynamic> map) {
    return CRMModule(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      enabled: (map['enabled'] as int) == 1,
      sortOrder: (map['sort_order'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'enabled': enabled ? 1 : 0,
      'sort_order': sortOrder,
    };
  }

  static List<CRMModule> get defaultModules => const [
        CRMModule(
          id: 'sales',
          title: 'Продажи',
          description: 'Управление сделками, оплатами и приходом средств.',
          enabled: true,
          sortOrder: 0,
        ),
        CRMModule(
          id: 'docs',
          title: 'Документация',
          description: 'Хранение и контроль договоров, актов и файлов.',
          enabled: true,
          sortOrder: 1,
        ),
        CRMModule(
          id: 'pr_smm',
          title: 'PR/SMM',
          description: 'Планирование кампаний, контент-календарь и аналитика.',
          enabled: true,
          sortOrder: 2,
        ),
        CRMModule(
          id: 'hr',
          title: 'Управление персоналом',
          description: 'Вакансии, онбординг и процессы для сотрудников.',
          enabled: true,
          sortOrder: 3,
        ),
        CRMModule(
          id: 'finance',
          title: 'Бухгалтерия',
          description: 'Учет расходов, налогов и финансовой отчетности.',
          enabled: true,
          sortOrder: 4,
        ),
      ];

  @override
  List<Object?> get props => [id, title, description, enabled, sortOrder];
}
