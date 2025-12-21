import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/company.dart';
import '../../data/models/employee.dart';
import '../../data/models/position.dart';
import '../../data/repositories/company_repository.dart';
import 'company_state.dart';

class CompanyCubit extends Cubit<CompanyState> {
  final CompanyRepository _repository;

  CompanyCubit({required CompanyRepository repository})
      : _repository = repository,
        super(CompanyState.initial());

  Future<void> load() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final company = await _repository.fetchCompany();
      if (company == null) {
        emit(state.copyWith(loading: false, company: null));
        return;
      }
      final positions = await _repository.fetchPositions(company.id);
      final departments = await _repository.fetchDepartments(company.id);
      final employees = await _repository.fetchEmployees(company.id);
      emit(state.copyWith(
        loading: false,
        company: company,
        positions: positions,
        departments: departments,
        employees: employees,
      ));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> createCompany(String name) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final company = await _repository.createCompany(name);
      final positions = await _repository.fetchPositions(company.id);
      final departments = await _repository.fetchDepartments(company.id);
      final employees = await _repository.fetchEmployees(company.id);
      emit(state.copyWith(
        loading: false,
        company: company,
        positions: positions,
        departments: departments,
        employees: employees,
      ));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> renameCompany(String name) async {
    if (state.company == null) return;
    emit(state.copyWith(loading: true, error: null));
    try {
      final updated = await _repository.renameCompany(state.company!.id, name, state.company!.createdAt);
      emit(state.copyWith(loading: false, company: updated, error: null));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> addPosition(
    String title,
    List<String> modules, {
    bool isHead = false,
    Map<String, List<String>> submodules = const {},
  }) async {
    if (state.company == null) return;
    emit(state.copyWith(loading: true, error: null));
    try {
      await _repository.addPosition(
        companyId: state.company!.id,
        title: title,
        modules: modules,
        isHead: isHead,
        submodules: submodules,
      );
      final positions = await _repository.fetchPositions(state.company!.id);
      emit(state.copyWith(loading: false, positions: positions));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> deletePosition(Position position) async {
    final hasEmployees = state.employees.any((e) => e.positionId == position.id);
    if (hasEmployees) {
      emit(state.copyWith(error: 'Нельзя удалить должность, пока к ней привязаны сотрудники.'));
      return;
    }
    emit(state.copyWith(loading: true, error: null));
    try {
      await _repository.deletePosition(position.id);
      final positions = await _repository.fetchPositions(state.company!.id);
      emit(state.copyWith(loading: false, positions: positions, error: null));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> addDepartment(String title) async {
    if (state.company == null) return;
    emit(state.copyWith(loading: true, error: null));
    try {
      await _repository.addDepartment(companyId: state.company!.id, title: title);
      final departments = await _repository.fetchDepartments(state.company!.id);
      emit(state.copyWith(loading: false, departments: departments));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> deleteDepartment(int departmentId, {required Map<int, int> employeeReassignments}) async {
    if (state.company == null) return;
    final employeesInDepartment = state.employees.where((e) => e.departmentId == departmentId).toList();
    if (employeesInDepartment.isNotEmpty) {
      final missingAssignment = employeesInDepartment.any((e) => employeeReassignments[e.id] == null);
      if (missingAssignment) {
        emit(state.copyWith(error: 'Укажите новый отдел для каждого сотрудника.'));
        return;
      }
      // Ensure head uniqueness when moving managers.
      for (final employee in employeesInDepartment) {
        final targetDepartmentId = employeeReassignments[employee.id];
        if (targetDepartmentId == null || targetDepartmentId == departmentId) {
          emit(state.copyWith(error: 'Нужно выбрать другой отдел для переноса сотрудников.'));
          return;
        }
        final position = state.positions.firstWhere((p) => p.id == employee.positionId);
        if (position.isHead) {
          final hasHeadInTarget = state.employees.any(
            (other) =>
                other.id != employee.id &&
                other.departmentId == targetDepartmentId &&
                state.positions.any((p) => p.id == other.positionId && p.isHead),
          );
          final movingHeadsToTarget = employeesInDepartment.where((e) {
            if (e.id == employee.id) return false;
            final pos = state.positions.firstWhere((p) => p.id == e.positionId);
            return pos.isHead && employeeReassignments[e.id] == targetDepartmentId;
          }).isNotEmpty;
          if (hasHeadInTarget || movingHeadsToTarget) {
            emit(state.copyWith(error: 'В выбранном отделе уже есть руководитель.'));
            return;
          }
        }
      }
    }

    emit(state.copyWith(loading: true, error: null));
    try {
      for (final employee in employeesInDepartment) {
        final targetDepartmentId = employeeReassignments[employee.id];
        if (targetDepartmentId != null) {
          await _repository.updateEmployee(employee.copyWith(departmentId: targetDepartmentId));
        }
      }
      await _repository.deleteDepartment(departmentId);
      final departments = await _repository.fetchDepartments(state.company!.id);
      final employees = await _repository.fetchEmployees(state.company!.id);
      emit(state.copyWith(loading: false, departments: departments, employees: employees, error: null));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> updatePositionEntry(Position position) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      await _repository.updatePosition(position);
      final positions = await _repository.fetchPositions(state.company!.id);
      emit(state.copyWith(loading: false, positions: positions));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> updateEmployeeEntry(Employee employee) async {
    if (state.company == null) return;
    final newPosition = state.positions.firstWhere((p) => p.id == employee.positionId);
    if (newPosition.isHead) {
      final hasHead = state.employees.any(
        (e) =>
            e.id != employee.id &&
            e.departmentId == employee.departmentId &&
            state.positions.any((p) => p.id == e.positionId && p.isHead),
      );
      if (hasHead) {
        emit(state.copyWith(loading: false, error: 'В отделе уже есть Глава отдела. Выберите другую должность.'));
        return;
      }
    }
    emit(state.copyWith(loading: true, error: null));
    try {
      await _repository.updateEmployee(employee);
      final employees = await _repository.fetchEmployees(state.company!.id);
      emit(state.copyWith(loading: false, employees: employees));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> addEmployee({
    required String email,
    required String name,
    required int positionId,
    required int departmentId,
    required EmployeeStatus status,
  }) async {
    if (state.company == null) return;
    final position = state.positions.firstWhere((p) => p.id == positionId);
    if (position.isHead) {
      final hasHead = state.employees.any(
        (e) => e.departmentId == departmentId && state.positions.any((p) => p.id == e.positionId && p.isHead),
      );
      if (hasHead) {
        emit(state.copyWith(loading: false, error: 'В отделе уже есть Глава отдела. Выберите другую должность.'));
        return;
      }
    }
    emit(state.copyWith(loading: true, error: null));
    try {
      await _repository.addEmployee(
        companyId: state.company!.id,
        email: email,
        name: name,
        positionId: positionId,
        departmentId: departmentId,
        status: status,
        setAsHead: position.isHead,
      );
      final employees = await _repository.fetchEmployees(state.company!.id);
      final departments = await _repository.fetchDepartments(state.company!.id);
      emit(state.copyWith(loading: false, employees: employees, departments: departments));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> deleteEmployee(int employeeId) async {
    if (state.company == null) return;
    emit(state.copyWith(loading: true, error: null));
    try {
      await _repository.deleteEmployee(employeeId);
      final employees = await _repository.fetchEmployees(state.company!.id);
      final departments = await _repository.fetchDepartments(state.company!.id);
      emit(state.copyWith(loading: false, employees: employees, departments: departments, error: null));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> updateStatus(int employeeId, EmployeeStatus status) async {
    if (state.company == null) return;
    emit(state.copyWith(loading: true, error: null));
    try {
      await _repository.updateEmployeeStatus(employeeId, status);
      final employees = await _repository.fetchEmployees(state.company!.id);
      emit(state.copyWith(loading: false, employees: employees));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }
}
