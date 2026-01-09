import 'package:equatable/equatable.dart';

class Department extends Equatable {
  final int id;
  final int companyId;
  final String title;
  final int? headEmployeeId;

  const Department({
    required this.id,
    required this.companyId,
    required this.title,
    this.headEmployeeId,
  });

  factory Department.fromMap(Map<String, dynamic> map) {
    return Department(
      id: map['id'] as int,
      companyId: map['company_id'] as int,
      title: map['title'] as String,
      headEmployeeId: map['head_employee_id'] as int?,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'company_id': companyId,
        'title': title,
        'head_employee_id': headEmployeeId,
      };

  Department copyWith({int? headEmployeeId}) => Department(
        id: id,
        companyId: companyId,
        title: title,
        headEmployeeId: headEmployeeId ?? this.headEmployeeId,
      );

  @override
  List<Object?> get props => [id, companyId, title, headEmployeeId];
}
