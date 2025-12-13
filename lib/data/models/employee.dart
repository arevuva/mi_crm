import 'package:equatable/equatable.dart';

enum EmployeeStatus { onsite, commute, remote, home }

class Employee extends Equatable {
  final int id;
  final int companyId;
  final int positionId;
  final String name;
  final EmployeeStatus status;

  const Employee({
    required this.id,
    required this.companyId,
    required this.positionId,
    required this.name,
    required this.status,
  });

  factory Employee.fromMap(Map<String, dynamic> map) {
    final statusRaw = map['status'] as String? ?? EmployeeStatus.home.name;
    return Employee(
      id: map['id'] as int,
      companyId: map['company_id'] as int,
      positionId: map['position_id'] as int,
      name: map['name'] as String,
      status: EmployeeStatus.values.firstWhere(
        (e) => e.name == statusRaw,
        orElse: () => EmployeeStatus.home,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'company_id': companyId,
        'position_id': positionId,
        'name': name,
        'status': status.name,
      };

  Employee copyWith({EmployeeStatus? status}) => Employee(
        id: id,
        companyId: companyId,
        positionId: positionId,
        name: name,
        status: status ?? this.status,
      );

  @override
  List<Object?> get props => [id, companyId, positionId, name, status];
}
