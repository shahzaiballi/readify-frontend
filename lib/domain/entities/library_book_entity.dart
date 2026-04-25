import 'book_entity.dart';

enum LibraryStatus {
  inProgress,
  completed,
  notStarted,
}

class LibraryBookEntity extends BookEntity {
  final double progressPercent;
  final bool isFavorite;
  final LibraryStatus status;

  const LibraryBookEntity({
    required super.id,
    required super.title,
    required super.author,
    required super.imageUrl,
    required super.rating,
    required super.readersCount,
    required super.category,
    super.hasAudio,
    super.badge,
    this.progressPercent = 0.0,
    this.isFavorite = false,
    this.status = LibraryStatus.notStarted,
  });

  @override
  LibraryBookEntity copyWith({
    String? id,
    String? title,
    String? author,
    String? imageUrl,
    double? rating,
    String? readersCount,
    String? category,
    bool? hasAudio,
    String? badge,
    double? progressPercent,
    bool? isFavorite,
    LibraryStatus? status,
  }) {
    return LibraryBookEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      readersCount: readersCount ?? this.readersCount,
      category: category ?? this.category,
      hasAudio: hasAudio ?? this.hasAudio,
      badge: badge ?? this.badge,
      progressPercent: progressPercent ?? this.progressPercent,
      isFavorite: isFavorite ?? this.isFavorite,
      status: status ?? this.status,
    );
  }
}