import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../data/network/api_client.dart';
import '../../../domain/entities/user_credentials.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../core/navigation/app_router.dart';

// ── Repository Provider ───────────────────────────────────────────────────────
// Switched from MockAuthRepository to the real implementation.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

// ── Auth Controller ───────────────────────────────────────────────────────────
final authControllerProvider =
    AsyncNotifierProvider<AuthController, UserEntity?>(() {
  return AuthController();
});

class AuthController extends AsyncNotifier<UserEntity?> {
  late AuthRepository _repository;

  @override
  FutureOr<UserEntity?> build() async {
    _repository = ref.watch(authRepositoryProvider);

    // Check if a valid access token exists on app start.
    // If yes, we consider the user logged in without hitting the network.
    // The token will refresh automatically on the first real API call if expired.
    final hasToken = await ApiClient.instance.hasValidToken();
    if (hasToken) {
      // Optionally fetch the user profile here.
      // For now we return a minimal entity — the profile page loads its own data.
      return const UserEntity(id: 'cached', name: '', email: '');
    }
    return null; // Not logged in
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final user = await _repository.login(
        UserCredentials(email: email, password: password),
      );
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> signUp(String fullName, String email, String password) async {
    state = const AsyncLoading();
    try {
      final user = await _repository.signUp(
        UserCredentials(
          fullName: fullName,
          email: email,
          password: password,
        ),
      );
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setBool('needsProfileSetup', true);
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    try {
      await _repository.logout();
      state = const AsyncData(null);
    } catch (e) {
      // Even if logout API fails, clear local state and tokens
      await ApiClient.instance.clearTokens();
      state = const AsyncData(null);
    }
  }

  // Called by the router/global error handler when an AuthException is caught.
  // Forces the user back to the login screen.
  void forceLogout() {
    ApiClient.instance.clearTokens();
    state = const AsyncData(null);
  }
}

