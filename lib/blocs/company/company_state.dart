import 'package:equatable/equatable.dart';

import '../../data/models/company.dart';
import '../../data/models/employee.dart';
import '../../data/models/position.dart';

class CompanyState extends Equatable {
  final bool loading;
  final Company? company;
  final List<Position> positions;
  final List<Employee> employees;
  final String? error;

  const CompanyState({
    required this.loading,
    this.company,
    this.error,
    this.positions = const [],
    this.employees = const [],
  });

  factory CompanyState.initial() => const CompanyState(loading: false, positions: [], employees: []);

  CompanyState copyWith({
    bool? loading,
    Company? company,
    List<Position>? positions,
    List<Employee>? employees,
    String? error,
  }) {
    return CompanyState(
      loading: loading ?? this.loading,
      company: company ?? this.company,
      positions: positions ?? this.positions,
      employees: employees ?? this.employees,
      error: error,
    );
  }

  @override
  List<Object?> get props => [loading, company, positions, employees, error];
}
