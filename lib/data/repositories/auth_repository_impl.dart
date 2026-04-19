import '../../domain/entities/user_entity.dart';
import '../../domain/entities/user_credentials.dart';
import '../../domain/repositories/auth_repository.dart';
import '../network/api_client.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _api = ApiClient.instance;

  @override
  Future<UserEntity> login(UserCredentials credentials) async {
    final data = await _api.post(
      '/auth/login/',
      body: {
        'email': credentials.email,
        'password': credentials.password,
      },
    ) as Map<String, dynamic>;

    final userData = data['user'] as Map<String, dynamic>;
    final tokens = data['tokens'] as Map<String, dynamic>;

    // Store tokens securely
    await _api.setTokens(
      access: tokens['access'] as String,
      refresh: tokens['refresh'] as String,
    );

    return UserEntity(
      id: userData['id'].toString(),
      name: userData['name'] ?? '',
      email: userData['email'] ?? '',
    );
  }

  @override
  Future<UserEntity> signUp(UserCredentials credentials) async {
    final data = await _api.post(
      '/auth/register/',
      body: {
        'full_name': credentials.fullName ?? '',
        'email': credentials.email,
        'password': credentials.password,
        'confirm_password': credentials.password, // backend expects it
      },
    ) as Map<String, dynamic>;

    final userData = data['user'] as Map<String, dynamic>;
    final tokens = data['tokens'] as Map<String, dynamic>;

    await _api.setTokens(
      access: tokens['access'] as String,
      refresh: tokens['refresh'] as String,
    );

    return UserEntity(
      id: userData['id'].toString(),
      name: userData['name'] ?? '',
      email: userData['email'] ?? '',
    );
  }

  @override
  Future<void> logout() async {
    final refresh = await _api.getRefreshToken();
    if (refresh != null) {
      try {
        await _api.post('/auth/logout/', body: {'refresh': refresh});
      } catch (_) {
        // Ignore - token might already be invalid
      }
    }
    await _api.clearTokens();
  }
}