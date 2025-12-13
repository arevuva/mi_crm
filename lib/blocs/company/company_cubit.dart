import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/company.dart';
import '../../data/models/employee.dart';
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
      final employees = await _repository.fetchEmployees(company.id);
      emit(state.copyWith(
        loading: false,
        company: company,
        positions: positions,
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
      final employees = await _repository.fetchEmployees(company.id);
      emit(state.copyWith(
        loading: false,
        company: company,
        positions: positions,
        employees: employees,
      ));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> addPosition(String title, List<String> modules) async {
    if (state.company == null) return;
    emit(state.copyWith(loading: true, error: null));
    try {
      await _repository.addPosition(companyId: state.company!.id, title: title, modules: modules);
      final positions = await _repository.fetchPositions(state.company!.id);
      emit(state.copyWith(loading: false, positions: positions));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> addEmployee({required String name, required int positionId, required EmployeeStatus status}) async {
    if (state.company == null) return;
    emit(state.copyWith(loading: true, error: null));
    try {
      await _repository.addEmployee(
        companyId: state.company!.id,
        name: name,
        positionId: positionId,
        status: status,
      );
      final employees = await _repository.fetchEmployees(state.company!.id);
      emit(state.copyWith(loading: false, employees: employees));
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
