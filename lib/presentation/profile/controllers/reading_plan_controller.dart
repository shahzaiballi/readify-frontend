import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../domain/entities/reading_plan_entity.dart';

class ReadingPlanController extends Notifier<ReadingPlanEntity> {
  static const _keyDailyMinutes = 'rp_daily_minutes';
  static const _keyDaysPerWeek = 'rp_days_per_week';
  static const _keyPreferredTime = 'rp_preferred_time';
  static const _keyReadingMode = 'rp_reading_mode';

  @override
  ReadingPlanEntity build() {
    _loadFromPrefs();
    return const ReadingPlanEntity();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    state = ReadingPlanEntity(
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
    final prefs = await SharedPreferences.getInstance();
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

