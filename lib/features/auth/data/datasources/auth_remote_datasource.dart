import '../../../../core/network/api_client.dart';
import '../models/auth_session_model.dart';
import '../models/auth_user_model.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<AuthSessionModel> login(Map<String, dynamic> payload) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/login',
      data: payload,
    );
    return AuthSessionModel.fromJson(response.data!);
  }

  Future<AuthUserModel> verifySession() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/auth/verify-session',
    );
    final data = response.data!;
    return AuthUserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> logout(Map<String, dynamic> payload) async {
    await _apiClient.post<Map<String, dynamic>>('/auth/logout', data: payload);
  }
}
