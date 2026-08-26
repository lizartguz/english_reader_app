import 'package:equatable/equatable.dart';

import 'auth_user.dart';

/// Sesión emitida por login o refresh.
class AuthSession extends Equatable {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.sessionExpiresAt,
    required this.user,
  });

  final String accessToken;
  final String? refreshToken;
  final String tokenType;
  final int expiresIn;
  final DateTime sessionExpiresAt;
  final AuthUser user;

  @override
  List<Object?> get props => [
    accessToken,
    refreshToken,
    tokenType,
    expiresIn,
    sessionExpiresAt,
    user,
  ];
}
