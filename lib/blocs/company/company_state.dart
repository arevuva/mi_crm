import 'package:equatable/equatable.dart';

import '../../data/models/company.dart';
import '../../data/models/department.dart';
import '../../data/models/employee.dart';
import '../../data/models/position.dart';

class CompanyState extends Equatable {
  final bool loading;
  final Company? company;
  final List<Position> positions;
  final List<Department> departments;
  final List<Employee> employees;
  final String? error;

  const CompanyState({
    required this.loading,
    this.company,
    this.error,
    this.positions = const [],
    this.departments = const [],
    this.employees = const [],
  });

  factory CompanyState.initial() => const CompanyState(
        loading: false,
        positions: [],
        departments: [],
        employees: [],
      );

  CompanyState copyWith({
    bool? loading,
    Company? company,
    List<Position>? positions,
    List<Department>? departments,
    List<Employee>? employees,
    String? error,
  }) {
    return CompanyState(
      loading: loading ?? this.loading,
      company: company ?? this.company,
      positions: positions ?? this.positions,
      departments: departments ?? this.departments,
      employees: employees ?? this.employees,
      error: error,
    );
  }

  @override
  List<Object?> get props => [loading, company, positions, departments, employees, error];
}
