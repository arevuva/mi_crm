import 'package:equatable/equatable.dart';

enum EmployeeMessageKind { message, task }

class EmployeeMessage extends Equatable {
  final int id;
  final int senderId;
  final int receiverId;
  final String text;
  final DateTime createdAt;
  final EmployeeMessageKind kind;
  final String? urgency;
  final DateTime? dueDate;
  final String status;
  final String? comment;

  const EmployeeMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.createdAt,
    required this.kind,
    this.urgency,
    this.dueDate,
    this.status = 'open',
    this.comment,
  });

  factory EmployeeMessage.fromMap(Map<String, dynamic> map) {
    return EmployeeMessage(
      id: map['id'] as int,
      senderId: map['sender_id'] as int,
      receiverId: map['receiver_id'] as int,
      text: map['text'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      kind: (map['kind'] as String? ?? 'message') == 'task'
          ? EmployeeMessageKind.task
          : EmployeeMessageKind.message,
      urgency: map['urgency'] as String?,
      dueDate: map['due_date'] == null ? null : DateTime.fromMillisecondsSinceEpoch(map['due_date'] as int),
      status: map['status'] as String? ?? 'open',
      comment: map['comment'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'sender_id': senderId,
        'receiver_id': receiverId,
        'text': text,
        'created_at': createdAt.millisecondsSinceEpoch,
        'kind': kind == EmployeeMessageKind.task ? 'task' : 'message',
        'urgency': urgency,
        'due_date': dueDate?.millisecondsSinceEpoch,
        'status': status,
        'comment': comment,
      };

  @override
  List<Object?> get props => [id, senderId, receiverId, text, createdAt, kind, urgency, dueDate, status, comment];
}
