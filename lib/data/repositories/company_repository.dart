import '../local/local_database.dart';
import '../models/company.dart';
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

  Future<List<Position>> fetchPositions(int companyId) async {
    final rows = await _db.fetchPositions(companyId);
    return rows.map(Position.fromMap).toList();
  }

  Future<Position> addPosition({required int companyId, required String title, required List<String> modules}) async {
    final id = await _db.addPosition(companyId: companyId, title: title, modules: modules);
    return Position(id: id, companyId: companyId, title: title, modules: modules);
  }

  Future<List<Employee>> fetchEmployees(int companyId) async {
    final rows = await _db.fetchEmployees(companyId);
    return rows.map(Employee.fromMap).toList();
  }

  Future<Employee> addEmployee({
    required int companyId,
    required String name,
    required int positionId,
    required EmployeeStatus status,
  }) async {
    final id = await _db.addEmployee(
      companyId: companyId,
      name: name,
      positionId: positionId,
      status: status.name,
    );
    return Employee(
      id: id,
      companyId: companyId,
      positionId: positionId,
      name: name,
      status: status,
    );
  }

  Future<void> updateEmployeeStatus(int employeeId, EmployeeStatus status) async {
    await _db.updateEmployeeStatus(employeeId, status.name);
  }
}
