class TodayChunkEntity {
  final String id;
  final String text;
  final int chunkIndex;
  final int pageNumber;
  final int wordsCount;

  const TodayChunkEntity({
    required this.id,
    required this.text,
    required this.chunkIndex,
    required this.pageNumber,
    this.wordsCount = 0,
  });
}

class TodayChapterEntity {
  final String id;
  final int number;
  final String title;
  final List<TodayChunkEntity> chunks;

  const TodayChapterEntity({
    required this.id,
    required this.number,
    required this.title,
    required this.chunks,
  });
}

class TodayReadingEntity {
  final int dayNumber;
  final int totalDays;
  final int daysRemaining;
  final int progressPercent;
  final String projectedFinishDate;
  final int pagesPerDay;
  final int totalPages;
  final int pagesReadSoFar;
  final int todayPageStart;
  final int todayPageEnd;
  final bool isTodayComplete;
  final bool isBookComplete;
  final List<TodayChapterEntity> chapters;

  const TodayReadingEntity({
    required this.dayNumber,
    required this.totalDays,
    required this.daysRemaining,
    required this.progressPercent,
    required this.projectedFinishDate,
    required this.pagesPerDay,
    required this.totalPages,
    required this.pagesReadSoFar,
    required this.todayPageStart,
    required this.todayPageEnd,
    required this.isTodayComplete,
    required this.isBookComplete,
    required this.chapters,
  });

  List<TodayChunkEntity> get allChunks =>
      chapters.expand((c) => c.chunks).toList();

  int get todayPageCount => todayPageEnd - todayPageStart + 1;
}

class TodaySummaryItem {
  final int chapterNumber;
  final String chapterTitle;
  final String mode;
  final String summaryContent;
  final List<String> keyTakeaways;

  const TodaySummaryItem({
    required this.chapterNumber,
    required this.chapterTitle,
    required this.mode,
    required this.summaryContent,
    required this.keyTakeaways,
  });
}

class TodaySummaryResult {
  final String status;
  final String readingMode;
  final List<TodaySummaryItem> summaries;

  const TodaySummaryResult({
    required this.status,
    required this.readingMode,
    required this.summaries,
  });

  bool get isGenerating => status == 'generating';
  bool get isReady => status == 'ready';
}

class TodayCompleteResult {
  final int progressPercent;
  final int pagesReadToday;
  final int totalPagesRead;
  final int totalPages;
  final int nextDayNumber;
  final int totalDays;
  final int daysRemaining;
  final String? milestone;
  final bool isBookComplete;

  const TodayCompleteResult({
    required this.progressPercent,
    required this.pagesReadToday,
    required this.totalPagesRead,
    required this.totalPages,
    required this.nextDayNumber,
    required this.totalDays,
    required this.daysRemaining,
    this.milestone,
    required this.isBookComplete,
  });
}
