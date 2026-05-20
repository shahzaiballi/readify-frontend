class ReadingPlanEntity {
  final int pagesPerDay;
  final int daysPerWeek;
  final String preferredTime;
  final String readingMode;

  const ReadingPlanEntity({
    this.pagesPerDay = 10,
    this.daysPerWeek = 5,
    this.preferredTime = 'Evening',
    this.readingMode = 'deep',
  });

  ReadingPlanEntity copyWith({
    int? pagesPerDay,
    int? daysPerWeek,
    String? preferredTime,
    String? readingMode,
  }) {
    return ReadingPlanEntity(
      pagesPerDay: pagesPerDay ?? this.pagesPerDay,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      preferredTime: preferredTime ?? this.preferredTime,
      readingMode: readingMode ?? this.readingMode,
    );
  }
}

