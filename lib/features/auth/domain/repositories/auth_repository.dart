import '../entities/auth_session.dart';
import '../entities/auth_user.dart';

abstract class AuthRepository {
  Future<AuthSession> login({required String email, required String password});

  Future<String> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  });

  Future<String> requestPasswordReset(String email);

  Future<String> resetPassword({
    required String token,
    required String password,
  });

  Future<AuthUser?> verifySession();

  Future<void> logout();

  Future<bool> hasLocalSession();
}
