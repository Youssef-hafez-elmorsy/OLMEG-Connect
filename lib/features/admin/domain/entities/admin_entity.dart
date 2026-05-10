import 'package:equatable/equatable.dart';

class AdminEntity extends Equatable {
  final String id;
  final String userId;
  final String role;
  final List<String> permissions;
  final DateTime createdAt;

  const AdminEntity({
    required this.id,
    required this.userId,
    required this.role,
    required this.permissions,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        role,
        permissions,
        createdAt,
      ];
}
