class ReadingPlanEntity {
  final int dailyMinutes;
  final int daysPerWeek;
  final String preferredTime;
  final String readingMode;

  const ReadingPlanEntity({
    this.dailyMinutes = 30,
    this.daysPerWeek = 5,
    this.preferredTime = 'Evening',
    this.readingMode = 'deep',
  });

  ReadingPlanEntity copyWith({
    int? dailyMinutes,
    int? daysPerWeek,
    String? preferredTime,
    String? readingMode,
  }) {
    return ReadingPlanEntity(
      dailyMinutes: dailyMinutes ?? this.dailyMinutes,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      preferredTime: preferredTime ?? this.preferredTime,
      readingMode: readingMode ?? this.readingMode,
    );
  }
}

