class ChunkEntity {
  final String id;
  final String text;
  final int estimatedMinutes;
  final int chunkIndex;
  final int dayNumber;
  final int wordsCount;

  const ChunkEntity({
    required this.id,
    required this.text,
    required this.estimatedMinutes,
    required this.chunkIndex,
    this.dayNumber = 1,
    this.wordsCount = 0,
  });

  ChunkEntity copyWith({
    String? id,
    String? text,
    int? estimatedMinutes,
    int? chunkIndex,
    int? dayNumber,
    int? wordsCount,
  }) {
    return ChunkEntity(
      id: id ?? this.id,
      text: text ?? this.text,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      chunkIndex: chunkIndex ?? this.chunkIndex,
      dayNumber: dayNumber ?? this.dayNumber,
      wordsCount: wordsCount ?? this.wordsCount,
    );
  }
}

