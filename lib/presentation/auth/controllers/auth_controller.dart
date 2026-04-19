import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../domain/entities/user_credentials.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/repositories/auth_repository.dart';

// Provide the repository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

// Provides the AuthController AsyncNotifier
final authControllerProvider = AsyncNotifierProvider<AuthController, UserEntity?>(() {
  return AuthController();
});

class AuthController extends AsyncNotifier<UserEntity?> {
  late AuthRepository _repository;

  @override
  FutureOr<UserEntity?> build() {
    _repository = ref.watch(authRepositoryProvider);
    return null; // Return null representing an unauthenticated state initially
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final user = await _repository.login(UserCredentials(email: email, password: password));
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> signUp(String fullName, String email, String password) async {
    state = const AsyncLoading();
    try {
      final user = await _repository.signUp(UserCredentials(
        fullName: fullName, 
        email: email, 
        password: password,
      ));
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
     } catch (e, st) {
       state = AsyncError(e, st);
     }
  }
}
