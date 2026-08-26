import '../../domain/entities/auth_user.dart';

class AuthUserModel extends AuthUser {
  const AuthUserModel({
    required super.id,
    required super.email,
    required super.firstName,
    required super.lastName,
    required super.fullName,
    required super.status,
    required super.roles,
    required super.permissions,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    return AuthUserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      status: json['status'] as String? ?? '',
      roles: (json['roles'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      permissions: (json['permissions'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }
}
