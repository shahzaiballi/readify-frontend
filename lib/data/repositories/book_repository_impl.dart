import '../../domain/entities/book_entity.dart';
import '../../domain/entities/book_detail_entity.dart';
import '../../domain/entities/user_stats_entity.dart';
import '../../domain/entities/add_book_params.dart';
import '../../domain/entities/chapter_entity.dart';
import '../../domain/entities/summary_entity.dart';
import '../../domain/entities/chunk_entity.dart';
import '../../domain/entities/flashcard_entity.dart';
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
      readPerDayMinutes: _toInt(json['readPerDayMinutes']) == 0
          ? 45
          : _toInt(json['readPerDayMinutes']),
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
      pageRange: json['pageRange'] ?? '',
      isCompleted: _toBool(json['isCompleted']),
      isActive: _toBool(json['isActive']),
      isLocked: _toBool(json['isLocked']),
    );
  }

  ChunkEntity _chunkFromJson(Map<String, dynamic> json) {
    return ChunkEntity(
      id: json['id'].toString(),
      text: json['text'] ?? '',
      estimatedMinutes: _toInt(json['estimatedMinutes']) == 0
          ? 2
          : _toInt(json['estimatedMinutes']),
      chunkIndex: _toInt(json['chunkIndex']),
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
    final data = await _api.get('/api/v1/books/$bookId/chapters/') as List<dynamic>;
    return data.cast<Map<String, dynamic>>().map(_chapterFromJson).toList();
  }

  @override
  Future<List<ChunkEntity>> getChunks(String bookId, String chapterId) async {
    final data = await _api.get('/api/v1/books/$bookId/chapters/$chapterId/chunks/') as List<dynamic>;
    return data.cast<Map<String, dynamic>>().map(_chunkFromJson).toList();
  }

  @override
  Future<List<SummaryEntity>> getChapterSummaries(String bookId) async {
    final data = await _api.get('/api/v1/books/$bookId/summaries/') as List<dynamic>;
    return data.cast<Map<String, dynamic>>().map(_summaryFromJson).toList();
  }

  @override
  Future<List<FlashcardEntity>> getFlashcards(String bookId) async {
    final data = await _api.get('/api/v1/books/$bookId/flashcards/') as List<dynamic>;
    return data.cast<Map<String, dynamic>>().map(_flashcardFromJson).toList();
  }

  @override
  Future<UserProgressEntity> getCurrentProgress() async {
    final data = await _api.get('/api/v1/reading/progress/') as Map<String, dynamic>;
    return UserProgressEntity(
      bookId: data['bookId'].toString(),
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      progressPercent: _toInt(data['progressPercent']),
    );
  }

  @override
  Future<InsightsEntity> getDailyInsights() async {
    final data = await _api.get('/api/v1/reading/insights/') as Map<String, dynamic>;
    return InsightsEntity(
      cardsDue: _toInt(data['cardsDue']),
      readTodayMinutes: _toInt(data['readTodayMinutes']),
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
}