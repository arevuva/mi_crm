import '../local/local_database.dart';
import '../models/company.dart';
import '../models/department.dart';
import '../models/employee.dart';
import '../models/position.dart';

class CompanyRepository {
  final LocalDatabase _db;

  CompanyRepository({LocalDatabase? database}) : _db = database ?? LocalDatabase();

  Future<Company?> fetchCompany() async {
    final map = await _db.fetchCompany();
    if (map == null) return null;
    return Company.fromMap(map);
  }

  Future<Company> createCompany(String name) async {
    final id = await _db.createCompany(name);
    return Company(id: id, name: name, createdAt: DateTime.now());
  }

  Future<Company> renameCompany(int companyId, String name, DateTime createdAt) async {
    await _db.updateCompanyName(id: companyId, name: name);
    return Company(id: companyId, name: name, createdAt: createdAt);
  }

  Future<List<Position>> fetchPositions(int companyId) async {
    final rows = await _db.fetchPositions(companyId);
    return rows.map(Position.fromMap).toList();
  }

  Future<List<Department>> fetchDepartments(int companyId) async {
    final rows = await _db.fetchDepartments(companyId);
    return rows.map(Department.fromMap).toList();
  }

  Future<Department> addDepartment({required int companyId, required String title}) async {
    final id = await _db.addDepartment(companyId: companyId, title: title);
    return Department(id: id, companyId: companyId, title: title, headEmployeeId: null);
  }

  Future<void> deleteDepartment(int id) => _db.deleteDepartment(id);

  Future<Position> addPosition({
    required int companyId,
    required String title,
    required List<String> modules,
    bool isHead = false,
    Map<String, List<String>> submodules = const {},
  }) async {
    final id = await _db.addPosition(
      companyId: companyId,
      title: title,
      modules: modules,
      isHead: isHead,
      submodules: submodules,
    );
    return Position(
      id: id,
      companyId: companyId,
      title: title,
      modules: modules,
      isHead: isHead,
      submodules: submodules,
    );
  }

  Future<void> updatePosition(Position position) async {
    await _db.updatePosition(
      id: position.id,
      title: position.title,
      modules: position.modules,
      isHead: position.isHead,
      submodules: position.submodules,
    );
  }

  Future<void> deletePosition(int id) => _db.deletePosition(id);

  Future<List<Employee>> fetchEmployees(int companyId) async {
    final rows = await _db.fetchEmployees(companyId);
    return rows.map(Employee.fromMap).toList();
  }

  Future<Employee?> fetchEmployeeByEmail(String email) async {
    final row = await _db.fetchEmployeeByEmail(email);
    if (row == null) return null;
    return Employee.fromMap(row);
  }

  Future<Employee> addEmployee({
    required int companyId,
    required String email,
    required String name,
    required int positionId,
    required int departmentId,
    required EmployeeStatus status,
    bool setAsHead = false,
  }) async {
    final id = await _db.addEmployee(
      companyId: companyId,
      email: email,
      name: name,
      positionId: positionId,
      departmentId: departmentId,
      status: status.name,
    );
    if (setAsHead) {
      await _db.setDepartmentHeadIfEmpty(departmentId: departmentId, headEmployeeId: id);
    }
    return Employee(
      id: id,
      companyId: companyId,
      positionId: positionId,
      departmentId: departmentId,
      email: email,
      name: name,
      status: status,
    );
  }

  Future<void> updateEmployeeStatus(int employeeId, EmployeeStatus status) async {
    await _db.updateEmployeeStatus(employeeId, status.name);
  }

  Future<void> updateEmployee(Employee employee) async {
    await _db.updateEmployee(
      id: employee.id,
      email: employee.email,
      name: employee.name,
      positionId: employee.positionId,
      departmentId: employee.departmentId ?? 0,
      status: employee.status.name,
    );
  }

  Future<void> deleteEmployee(int id) => _db.deleteEmployee(id);
}
