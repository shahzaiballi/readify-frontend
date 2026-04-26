class UserProgressEntity {
  final String bookId;
  final String title;
  final String author;
  final String imageUrl;
  final int progressPercent;

  /// The chapter the user was last reading.
  /// Null when the user hasn't started yet — the UI should fall back to
  /// the first chapter of the book.
  final String? currentChapterId;

  /// The chunk index within [currentChapterId] to resume from.
  final int currentChunkIndex;

  const UserProgressEntity({
    required this.bookId,
    required this.title,
    required this.author,
    required this.imageUrl,
    required this.progressPercent,
    this.currentChapterId,
    this.currentChunkIndex = 0,
  });
}

class InsightsEntity {
  final int cardsDue;
  final int readTodayMinutes;
  final int dayStreak;

  const InsightsEntity({
    required this.cardsDue,
    required this.readTodayMinutes,
    required this.dayStreak,
  });
}