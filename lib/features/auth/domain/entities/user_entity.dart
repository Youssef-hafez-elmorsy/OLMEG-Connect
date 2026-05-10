import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final String role;
  final DateTime createdAt;

  bool get isAdmin => role == 'admin';

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    this.role = 'user',
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, email, name, photoUrl, role, createdAt];
}
