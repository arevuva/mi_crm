import 'package:equatable/equatable.dart';

enum EmployeeStatus { onsite, commute, remote, home }

class Employee extends Equatable {
  final int id;
  final int companyId;
  final int positionId;
  final int? departmentId;
  final String email;
  final String name;
  final EmployeeStatus status;
  final int? userId;

  const Employee({
    required this.id,
    required this.companyId,
    required this.positionId,
    required this.departmentId,
    required this.email,
    required this.name,
    required this.status,
    this.userId,
  });

  factory Employee.fromMap(Map<String, dynamic> map) {
    final statusRaw = map['status'] as String? ?? EmployeeStatus.home.name;
    return Employee(
      id: map['id'] as int,
      companyId: map['company_id'] as int,
      positionId: map['position_id'] as int,
      departmentId: map['department_id'] as int?,
      email: map['email'] as String,
      name: map['name'] as String,
      status: EmployeeStatus.values.firstWhere(
        (e) => e.name == statusRaw,
        orElse: () => EmployeeStatus.home,
      ),
      userId: map['user_id'] as int?,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'company_id': companyId,
        'position_id': positionId,
        'department_id': departmentId,
        'email': email,
        'name': name,
        'status': status.name,
        'user_id': userId,
      };

  Employee copyWith({EmployeeStatus? status, int? userId, int? departmentId}) => Employee(
        id: id,
        companyId: companyId,
        positionId: positionId,
        departmentId: departmentId ?? this.departmentId,
        email: email,
        name: name,
        status: status ?? this.status,
        userId: userId ?? this.userId,
      );

  @override
  List<Object?> get props => [id, companyId, positionId, departmentId, email, name, status, userId];
}
