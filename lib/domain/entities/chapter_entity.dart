class ChapterEntity {
  final String id;
  final String title;
  final int chapterNumber;
  final int durationInMinutes;
  final int pagesCount;
  final String pageRange;
  final bool isCompleted;
  final bool isActive; // Identifies the currently reading chapter
  final bool isLocked;
  final String chapterSource;

  const ChapterEntity({
    required this.id,
    required this.title,
    required this.chapterNumber,
    required this.durationInMinutes,
    this.pagesCount = 0,
    required this.pageRange,
    this.isCompleted = false,
    this.isActive = false,
    this.isLocked = false,
    this.chapterSource = 'manual',
  });

  ChapterEntity copyWith({
    String? id,
    String? title,
    int? chapterNumber,
    int? durationInMinutes,
    int? pagesCount,
    String? pageRange,
    bool? isCompleted,
    bool? isActive,
    bool? isLocked,
    String? chapterSource,
  }) {
    return ChapterEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      durationInMinutes: durationInMinutes ?? this.durationInMinutes,
      pagesCount: pagesCount ?? this.pagesCount,
      pageRange: pageRange ?? this.pageRange,
      isCompleted: isCompleted ?? this.isCompleted,
      isActive: isActive ?? this.isActive,
      isLocked: isLocked ?? this.isLocked,
      chapterSource: chapterSource ?? this.chapterSource,
    );
  }
}

