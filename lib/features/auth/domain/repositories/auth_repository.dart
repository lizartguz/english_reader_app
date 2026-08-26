import '../entities/auth_session.dart';
import '../entities/auth_user.dart';

abstract class AuthRepository {
  Future<AuthSession> login({required String email, required String password});

  Future<AuthUser?> verifySession();

  Future<void> logout();

  Future<bool> hasLocalSession();
}
