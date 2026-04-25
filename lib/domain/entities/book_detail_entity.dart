import 'book_entity.dart';

class BookDetailEntity extends BookEntity {
  final String description;
  final int totalChapters;
  final int progressPercent;
  final int daysLeftToFinish;
  final int pagesLeft;
  final int flashcardsCount;
  final int readPerDayMinutes;

  const BookDetailEntity({
    required super.id,
    required super.title,
    required super.author,
    required super.imageUrl,
    required super.rating,
    required super.readersCount,
    required super.category,
    super.hasAudio,
    super.badge,
    required this.description,
    required this.totalChapters,
    required this.progressPercent ,
    required this.daysLeftToFinish,
    required this.pagesLeft,
    required this.flashcardsCount,
    required this.readPerDayMinutes,
  });
}