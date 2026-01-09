import 'package:equatable/equatable.dart';

class SmmPost extends Equatable {
  final int id;
  final int companyId;
  final int? productId;
  final String channel;
  final String message;
  final String status;
  final DateTime createdAt;

  const SmmPost({
    required this.id,
    required this.companyId,
    this.productId,
    required this.channel,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  factory SmmPost.fromMap(Map<String, dynamic> map) => SmmPost(
        id: map['id'] as int,
        companyId: map['company_id'] as int,
        productId: map['product_id'] as int?,
        channel: map['channel'] as String,
        message: map['message'] as String,
        status: map['status'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'company_id': companyId,
        'product_id': productId,
        'channel': channel,
        'message': message,
        'status': status,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  @override
  List<Object?> get props => [id, companyId, productId, channel, message, status, createdAt];
}
