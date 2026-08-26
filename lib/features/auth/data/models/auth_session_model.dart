import '../../domain/entities/auth_session.dart';
import 'auth_user_model.dart';

class AuthSessionModel extends AuthSession {
  const AuthSessionModel({
    required super.accessToken,
    required super.refreshToken,
    required super.tokenType,
    required super.expiresIn,
    required super.sessionExpiresAt,
    required super.user,
  });

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    return AuthSessionModel(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String?,
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      expiresIn: json['expiresIn'] as int? ?? 0,
      sessionExpiresAt: DateTime.parse(json['sessionExpiresAt'] as String),
      user: AuthUserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
