import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/profile_repository_impl.dart';
import '../../../domain/entities/user_profile_entity.dart';
import '../../../domain/repositories/profile_repository.dart';

// ── Repository Provider ───────────────────────────────────────────────────────

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl();
});

// Keep a separate reference for extra methods (changePassword, updateProfile)
final profileRepositoryImplProvider = Provider<ProfileRepositoryImpl>((ref) {
  return ProfileRepositoryImpl();
});

// ── Profile Controller ────────────────────────────────────────────────────────

class ProfileController extends AsyncNotifier<UserProfileEntity> {
  @override
  FutureOr<UserProfileEntity> build() async {
    final repo = ref.watch(profileRepositoryProvider);
    return repo.getUserProfile();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).getUserProfile(),
    );
  }
}

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, UserProfileEntity>(
  ProfileController.new,
);

// ── Settings Providers (local state — no API) ─────────────────────────────────

final notificationsEnabledProvider = StateProvider<bool>((ref) => true);
final darkModeEnabledProvider = StateProvider<bool>((ref) => true);