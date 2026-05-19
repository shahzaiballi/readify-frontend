import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/reading_plan_entity.dart';
import '../../../../core/navigation/app_router.dart';

class ReadingPlanController extends Notifier<ReadingPlanEntity> {
  static const _keyDailyMinutes = 'rp_daily_minutes';
  static const _keyDaysPerWeek = 'rp_days_per_week';
  static const _keyPreferredTime = 'rp_preferred_time';
  static const _keyReadingMode = 'rp_reading_mode';

  @override
  ReadingPlanEntity build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return ReadingPlanEntity(
      dailyMinutes: prefs.getInt(_keyDailyMinutes) ?? 30,
      daysPerWeek: prefs.getInt(_keyDaysPerWeek) ?? 5,
      preferredTime: prefs.getString(_keyPreferredTime) ?? 'Evening',
      readingMode: prefs.getString(_keyReadingMode) ?? 'deep',
    );
  }

  Future<void> updatePlan({
    int? dailyMinutes,
    int? daysPerWeek,
    String? preferredTime,
    String? readingMode,
  }) async {
    state = state.copyWith(
      dailyMinutes: dailyMinutes,
      daysPerWeek: daysPerWeek,
      preferredTime: preferredTime,
      readingMode: readingMode,
    );
    final prefs = ref.read(sharedPreferencesProvider);
    await Future.wait([
      prefs.setInt(_keyDailyMinutes, state.dailyMinutes),
      prefs.setInt(_keyDaysPerWeek, state.daysPerWeek),
      prefs.setString(_keyPreferredTime, state.preferredTime),
      prefs.setString(_keyReadingMode, state.readingMode),
    ]);
  }
}

final readingPlanProvider = NotifierProvider<ReadingPlanController, ReadingPlanEntity>(
  ReadingPlanController.new,
);

