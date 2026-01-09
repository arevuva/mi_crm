import '../../data/models/employee.dart';

String statusLabel(EmployeeStatus status) {
  switch (status) {
    case EmployeeStatus.onsite:
      return 'На работе';
    case EmployeeStatus.commute:
      return 'В пути';
    case EmployeeStatus.remote:
      return 'Удалённо';
    case EmployeeStatus.home:
      return 'Дома';
  }
}
