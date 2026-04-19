import '../../domain/entities/user_profile_entity.dart';
import '../../domain/entities/achievement_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../network/api_client.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ApiClient _api = ApiClient.instance;

  // ── Get Full Profile ──────────────────────────────────────────────────
  @override
  Future<UserProfileEntity> getUserProfile() async {
    final data = await _api.get('/auth/profile/');
    return _parseProfile(data);
  }

  // ── Update Profile ────────────────────────────────────────────────────
  Future<UserProfileEntity> updateProfile({
    String? fullName,
    String? avatarUrl,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['full_name'] = fullName;
    if (avatarUrl != null) body['avatar_url'] = avatarUrl;

    final data = await _api.patch('/auth/profile/', body: body);
    return _parseProfile(data);
  }

  // ── Change Password ───────────────────────────────────────────────────
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _api.post(
      '/auth/change-password/',
      body: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'confirm_password': newPassword,
      },
    );
  }

  // ── Preferences (stored locally — no backend needed) ─────────────────
  @override
  Future<void> updateNotificationPreference(bool enabled) async {
    // Stored in SharedPreferences locally — no API call needed
    // The notification service handles the actual scheduling
  }

  @override
  Future<void> updateDarkModePreference(bool enabled) async {
    // Stored locally — theme is a client-side concern
  }

  // ── Parser ────────────────────────────────────────────────────────────
  UserProfileEntity _parseProfile(Map<String, dynamic> data) {
    final rawAchievements = data['achievements'] as List? ?? [];

    final achievements = rawAchievements.map((a) {
      return AchievementEntity(
        id: a['id'].toString(),
        title: a['title'] ?? '',
        description: a['description'] ?? '',
        iconCode: a['iconCode'] ?? 'trophy',
        isUnlocked: a['isUnlocked'] ?? false,
      );
    }).toList();

    return UserProfileEntity(
      id: data['id'].toString(),
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      avatarUrl: data['avatarUrl'] ?? 'https://i.pravatar.cc/150?u=default',
      booksRead: data['booksRead'] ?? 0,
      totalPages: data['totalPages'] ?? 0,
      currentStreak: data['currentStreak'] ?? 0,
      isAvidReader: data['isAvidReader'] ?? false,
      achievements: achievements,
    );
  }
}