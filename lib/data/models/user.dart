import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  final int id;
  final String email;

  const AppUser({required this.id, required this.email});

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as int,
      email: map['email'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
    };
  }

  @override
  List<Object?> get props => [id, email];
}
