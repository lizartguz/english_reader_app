import 'package:equatable/equatable.dart';

/// Usuario autenticado devuelto por la API.
class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.status,
    required this.roles,
    required this.permissions,
  });

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String fullName;
  final String status;
  final List<String> roles;
  final List<String> permissions;

  @override
  List<Object?> get props => [
    id,
    email,
    firstName,
    lastName,
    fullName,
    status,
    roles,
    permissions,
  ];
}
