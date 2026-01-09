import '../local/local_database.dart';
import '../models/employee_message.dart';

class EmployeeCommunicationRepository {
  final LocalDatabase _db;

  EmployeeCommunicationRepository({LocalDatabase? database}) : _db = database ?? LocalDatabase();

  Future<List<EmployeeMessage>> fetchConversation(int employeeAId, int employeeBId) async {
    final rows = await _db.fetchEmployeeMessages(employeeAId: employeeAId, employeeBId: employeeBId);
    return rows.map(EmployeeMessage.fromMap).toList();
  }

  Future<EmployeeMessage> sendMessage({
    required int senderId,
    required int receiverId,
    required String text,
    EmployeeMessageKind kind = EmployeeMessageKind.message,
    String? urgency,
    DateTime? dueDate,
    String status = 'open',
    String? comment,
  }) async {
    final id = await _db.addEmployeeMessage(
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      kind: kind == EmployeeMessageKind.task ? 'task' : 'message',
      urgency: urgency,
      dueDate: dueDate,
      status: status,
      comment: comment,
    );
    return EmployeeMessage(
      id: id,
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      createdAt: DateTime.now(),
      kind: kind,
      urgency: urgency,
      dueDate: dueDate,
      status: status,
      comment: comment,
    );
  }

  Future<void> updateTask({
    required int taskId,
    String? status,
    String? comment,
  }) {
    return _db.updateEmployeeMessage(taskId: taskId, status: status, comment: comment);
  }

  Future<List<EmployeeMessage>> fetchTasksForReceivers(List<int> receiverIds) async {
    final rows = await _db.fetchEmployeeTasks(receiverIds);
    return rows.map(EmployeeMessage.fromMap).toList();
  }
}
