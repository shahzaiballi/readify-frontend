import '../../domain/entities/book_entity.dart';
import '../../domain/entities/book_detail_entity.dart';
import '../../domain/entities/user_stats_entity.dart';
import '../../domain/entities/add_book_params.dart';
import '../../domain/entities/chapter_entity.dart';
import '../../domain/entities/summary_entity.dart';
import '../../domain/entities/chunk_entity.dart';
import '../../utils/reading_conversion.dart';
import '../../domain/entities/flashcard_entity.dart';
import '../../domain/entities/today_reading_entity.dart';
import '../../domain/repositories/book_repository.dart';
import '../network/api_client.dart';

class BookRepositoryImpl implements BookRepository {
  final ApiClient _api = ApiClient.instance;

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  BookEntity _bookFromJson(Map<String, dynamic> json) {
    return BookEntity(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      rating: _toDouble(json['rating']),
      readersCount: json['readersCount']?.toString() ?? '0',
      category: json['category'] ?? '',
      hasAudio: _toBool(json['hasAudio']),
      badge: json['badge'] as String?,
    );
  }

  BookDetailEntity _bookDetailFromJson(Map<String, dynamic> json) {
    return BookDetailEntity(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      rating: _toDouble(json['rating']),
      readersCount: json['readersCount']?.toString() ?? '0',
      category: json['category'] ?? '',
      hasAudio: _toBool(json['hasAudio']),
      badge: json['badge'] as String?,
      description: json['description'] ?? '',
      totalChapters: _toInt(json['totalChapters']),
      progressPercent: _toInt(json['progressPercent']),
      daysLeftToFinish: _toInt(json['daysLeftToFinish']),
      pagesLeft: _toInt(json['pagesLeft']),
        flashcardsCount: _toInt(json['flashcardsCount']),
        readPerDayPages: _toInt(json['readPerDayPages']) != 0
          ? _toInt(json['readPerDayPages'])
          : 10,
    );
  }

  ChapterEntity _chapterFromJson(Map<String, dynamic> json) {
    return ChapterEntity(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      chapterNumber: _toInt(json['chapterNumber']),
      durationInMinutes: _toInt(json['durationInMinutes']) == 0
          ? 15
          : _toInt(json['durationInMinutes']),
      pagesCount: json['pagesCount'] != null
          ? _toInt(json['pagesCount'])
          : pagesFromPageRange(json['pageRange']?.toString() ?? ''),
      pageRange: json['pageRange'] ?? '',
      isCompleted: _toBool(json['isCompleted']),
      isActive: _toBool(json['isActive']),
      isLocked: _toBool(json['isLocked']),
      chapterSource: json['chapterSource'] ?? 'manual',
    );
  }

  ChunkEntity _chunkFromJson(Map<String, dynamic> json) {
    return ChunkEntity(
      id: json['id'].toString(),
      text: json['text'] ?? '',
      estimatedMinutes: _toInt(json['estimatedMinutes']) == 0
          ? 2
          : _toInt(json['estimatedMinutes']),
      estimatedPages: json['estimatedPages'] != null
          ? _toInt(json['estimatedPages'])
          : wordsToPages(_toInt(json['wordsCount'])),
      chunkIndex: _toInt(json['chunkIndex']),
      dayNumber: _toInt(json['dayNumber']) == 0 ? 1 : _toInt(json['dayNumber']),
      wordsCount: _toInt(json['wordsCount']),
    );
  }

  SummaryEntity _summaryFromJson(Map<String, dynamic> json) {
    return SummaryEntity(
      id: json['id'].toString(),
      chapterNumber: _toInt(json['chapterNumber']),
      title: json['title'] ?? '',
      summaryContent: json['summaryContent'] ?? '',
      keyTakeaways: List<String>.from(json['keyTakeaways'] ?? []),
      isLocked: _toBool(json['isLocked']),
    );
  }

  FlashcardEntity _flashcardFromJson(Map<String, dynamic> json) {
    return FlashcardEntity(
      id: json['id'].toString(),
      bookId: json['bookId'].toString(),
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
    );
  }

  @override
  Future<List<BookEntity>> getRecommendedBooks() async {
    final data = await _api.get('/api/v1/books/recommended/') as List<dynamic>;
    return data.cast<Map<String, dynamic>>().map(_bookFromJson).toList();
  }

  @override
  Future<List<BookEntity>> getTrendingBooks() async {
    final data = await _api.get('/api/v1/books/trending/') as List<dynamic>;
    return data.cast<Map<String, dynamic>>().map(_bookFromJson).toList();
  }

  @override
  Future<List<BookEntity>> getLibraryBooks() async {
    final data = await _api.get(
      '/api/v1/library/',
      queryParameters: {'status': 'in_progress'},
    ) as List<dynamic>;
    return data.cast<Map<String, dynamic>>().map(_bookFromJson).toList();
  }

  @override
  Future<BookDetailEntity> getBookDetails(String id) async {
    final data = await _api.get('/api/v1/books/$id/') as Map<String, dynamic>;
    return _bookDetailFromJson(data);
  }

  @override
  Future<List<ChapterEntity>> getChapters(String bookId) async {
    final data =
        await _api.get('/api/v1/books/$bookId/chapters/') as List<dynamic>;
    return data.cast<Map<String, dynamic>>().map(_chapterFromJson).toList();
  }

  @override
  Future<List<ChunkEntity>> getChunks(String bookId, String chapterId) async {
    // URL matches the backend route:
    // GET /api/v1/books/{book_id}/chapters/{chapter_id}/chunks/
    final data = await _api.get(
      '/api/v1/books/$bookId/chapters/$chapterId/chunks/',
    ) as List<dynamic>;
    return data.cast<Map<String, dynamic>>().map(_chunkFromJson).toList();
  }

  @override
  Future<List<SummaryEntity>> getChapterSummaries(String bookId) async {
    final data =
        await _api.get('/api/v1/books/$bookId/summaries/') as List<dynamic>;
    return data.cast<Map<String, dynamic>>().map(_summaryFromJson).toList();
  }

  @override
  Future<List<FlashcardEntity>> getFlashcards(String bookId) async {
    final data =
        await _api.get('/api/v1/books/$bookId/flashcards/') as List<dynamic>;
    return data.cast<Map<String, dynamic>>().map(_flashcardFromJson).toList();
  }

  @override
  Future<UserProgressEntity> getCurrentProgress() async {
    final data =
        await _api.get('/api/v1/reading/progress/') as Map<String, dynamic>;
    return UserProgressEntity(
      bookId: data['bookId'].toString(),
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      progressPercent: _toInt(data['progressPercent']),
      // These fields are now returned by the backend
      currentChapterId: data['currentChapterId']?.toString(),
      currentChunkIndex: _toInt(data['currentChunkIndex']),
    );
  }

  @override
  Future<InsightsEntity> getDailyInsights() async {
    final data =
        await _api.get('/api/v1/reading/insights/') as Map<String, dynamic>;
    return InsightsEntity(
      cardsDue: _toInt(data['cardsDue']),
      readTodayPages: _toInt(data['readTodayPages']),
      dayStreak: _toInt(data['dayStreak']),
    );
  }

  @override
  Future<void> addBook(AddBookParams params) async {
    final searchResults = await _api.get(
      '/api/v1/books/',
      queryParameters: {'search': params.title},
    ) as List<dynamic>;

    if (searchResults.isEmpty) {
      throw ApiException(
        'Book "${params.title}" not found in the catalog.',
        statusCode: 404,
      );
    }

    final bookId = searchResults.first['id'].toString();
    await _api.post('/api/v1/library/', body: {'book_id': bookId});
  }

  /// Records a reading session on the backend.
  /// Called by [ReadingSessionController] every time the user advances a chunk.
  Future<void> recordReadingSession({
    required String bookId,
    required String chapterId,
    required int chunkIndex,
    required int durationSeconds,
    required int chunksCompleted,
  }) async {
    await _api.post(
      '/api/v1/reading/session/',
      body: {
        'book_id': bookId,
        'chapter_id': chapterId,
        'chunk_index': chunkIndex,
        'duration_seconds': durationSeconds,
        'chunks_completed': chunksCompleted,
      },
    );
  }

  @override
  Future<TodayReadingEntity> getTodayReading(String bookId) async {
    final data =
        await _api.get('/api/v1/books/$bookId/today/') as Map<String, dynamic>;

    final chaptersRaw = (data['chapters'] as List<dynamic>? ?? []);
    final chapters = chaptersRaw.map((chJson) {
      final ch = chJson as Map<String, dynamic>;
      final chunksRaw = (ch['chunks'] as List<dynamic>? ?? []);
      final chunks = chunksRaw.map((ckJson) {
        final ck = ckJson as Map<String, dynamic>;
        return TodayChunkEntity(
          id: ck['id'].toString(),
          text: ck['text'] ?? '',
          chunkIndex: _toInt(ck['chunkIndex']),
          pageNumber: _toInt(ck['pageNumber']),
          wordsCount: _toInt(ck['wordsCount']),
        );
      }).toList();
      return TodayChapterEntity(
        id: ch['id'].toString(),
        number: _toInt(ch['number']),
        title: ch['title'] ?? '',
        chunks: chunks,
      );
    }).toList();

    return TodayReadingEntity(
      dayNumber: _toInt(data['dayNumber']),
      totalDays: _toInt(data['totalDays']),
      daysRemaining: _toInt(data['daysRemaining']),
      progressPercent: _toInt(data['progressPercent']),
      projectedFinishDate: data['projectedFinishDate']?.toString() ?? '',
      pagesPerDay: _toInt(data['pagesPerDay']),
      totalPages: _toInt(data['totalPages']),
      pagesReadSoFar: _toInt(data['pagesReadSoFar']),
      todayPageStart: _toInt(data['todayPageStart']),
      todayPageEnd: _toInt(data['todayPageEnd']),
      isTodayComplete: _toBool(data['isTodayComplete']),
      isBookComplete: _toBool(data['isBookComplete']),
      chapters: chapters,
    );
  }

  @override
  Future<TodayCompleteResult> completeTodayReading(
      String bookId, int durationSeconds) async {
    final data = await _api.post(
      '/api/v1/books/$bookId/today/complete/',
      body: {
        'duration_seconds': durationSeconds,
      },
    ) as Map<String, dynamic>;

    return TodayCompleteResult(
      progressPercent: _toInt(data['progressPercent']),
      pagesReadToday: _toInt(data['pagesReadToday']),
      totalPagesRead: _toInt(data['totalPagesRead']),
      totalPages: _toInt(data['totalPages']),
      nextDayNumber: _toInt(data['nextDayNumber']),
      totalDays: _toInt(data['totalDays']),
      daysRemaining: _toInt(data['daysRemaining']),
      milestone: data['milestone'] as String?,
      isBookComplete: _toBool(data['isBookComplete']),
    );
  }
}