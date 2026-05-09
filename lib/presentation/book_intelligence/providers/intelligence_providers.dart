import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/network/api_client.dart';

// ── Models ───────────────────────────────────────────────────────────────────

class IntelligenceStatus {
  final String status;
  final String? bookType;
  final String? complexityLevel;
  final bool embeddingsBuilt;
  final bool briefReady;
  final int chaptersCount;

  IntelligenceStatus({
    required this.status,
    this.bookType,
    this.complexityLevel,
    required this.embeddingsBuilt,
    required this.briefReady,
    required this.chaptersCount,
  });

  factory IntelligenceStatus.fromJson(Map<String, dynamic> json) {
    return IntelligenceStatus(
      status: json['status'] ?? 'not_started',
      bookType: json['book_type'],
      complexityLevel: json['complexity_level'],
      embeddingsBuilt: json['embeddings_built'] ?? false,
      briefReady: json['brief_ready'] ?? false,
      chaptersCount: json['chapters_count'] ?? 0,
    );
  }
}

class BookBrief {
  final String whatItsAbout;
  final String whoItsFor;
  final String coreArgument;
  final List<String> top5Ideas;
  final String verdict;

  BookBrief.fromJson(Map<String, dynamic> json)
      : whatItsAbout = json['what_its_about'] ?? '',
        whoItsFor = json['who_its_for'] ?? '',
        coreArgument = json['core_argument'] ?? '',
        top5Ideas = List<String>.from(json['top_5_ideas'] ?? []),
        verdict = json['verdict'] ?? '';
}

class AIChapter {
  final String id;
  final int chapterNumber;
  final String title;
  final String pageRangeDisplay;
  final String chapterHook;

  AIChapter.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        chapterNumber = json['chapter_number'],
        title = json['title'] ?? '',
        pageRangeDisplay = json['page_range_display'] ?? '',
        chapterHook = json['chapter_hook'] ?? '';
}

class QAMessage {
  final String id;
  final String question;
  final String answer;

  QAMessage.fromJson(Map<String, dynamic> json)
      : id = json['id'] ?? '',
        question = json['question'] ?? '',
        answer = json['answer'] ?? '';
}

class DailyInsights {
  final String morningHook;
  final String middayConcept;
  final String afternoonStory;
  final String eveningRecap;

  DailyInsights.fromJson(Map<String, dynamic> json)
      : morningHook = json['morning_hook'] ?? '',
        middayConcept = json['midday_concept'] ?? '',
        afternoonStory = json['afternoon_story'] ?? '',
        eveningRecap = json['evening_recap'] ?? '';
}

// ── Providers ────────────────────────────────────────────────────────────────

final intelligenceStatusProvider = FutureProvider.family<IntelligenceStatus, String>((ref, bookId) async {
  final res = await ApiClient.instance.get('/api/v1/intelligence/books/$bookId/status/');
  return IntelligenceStatus.fromJson(res);
});

final triggerAnalysisProvider = FutureProvider.family<void, String>((ref, bookId) async {
  await ApiClient.instance.post('/api/v1/intelligence/books/$bookId/analyze/');
  // Invalidate status after triggering
  ref.invalidate(intelligenceStatusProvider(bookId));
});

final bookBriefProvider = FutureProvider.family<BookBrief?, String>((ref, bookId) async {
  final res = await ApiClient.instance.get('/api/v1/intelligence/books/$bookId/brief/');
  if (res['ready'] == true) {
    return BookBrief.fromJson(res['brief']);
  }
  return null; // Not ready yet
});

final aiChaptersProvider = FutureProvider.family<List<AIChapter>, String>((ref, bookId) async {
  final res = await ApiClient.instance.get('/api/v1/intelligence/books/$bookId/chapters/');
  return (res as List).map((e) => AIChapter.fromJson(e)).toList();
});

class ChapterModeRequest {
  final String bookId;
  final String chapterId;
  final String mode;
  ChapterModeRequest(this.bookId, this.chapterId, this.mode);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChapterModeRequest &&
          other.bookId == bookId &&
          other.chapterId == chapterId &&
          other.mode == mode;

  @override
  int get hashCode => Object.hash(bookId, chapterId, mode);
}

final chapterModeProvider = FutureProvider.family<Map<String, dynamic>?, ChapterModeRequest>((ref, req) async {
  final res = await ApiClient.instance.get(
      '/api/v1/intelligence/books/${req.bookId}/chapters/${req.chapterId}/summary/?mode=${req.mode}');
  if (res['ready'] == true) {
    return res['content'];
  }
  return null; // Not ready yet
});

final qaHistoryProvider = FutureProvider.family<List<QAMessage>, String>((ref, bookId) async {
  final res = await ApiClient.instance.get('/api/v1/intelligence/books/$bookId/qa/history/');
  final messages = res['messages'] as List?;
  if (messages == null) return [];
  return messages.map((e) => QAMessage.fromJson(e)).toList();
});

final dailyInsightsProvider = FutureProvider.family<DailyInsights?, String>((ref, bookId) async {
  final res = await ApiClient.instance.get('/api/v1/intelligence/books/$bookId/notifications/today/');
  if (res['ready'] == true) {
    return DailyInsights.fromJson(res['notifications']);
  }
  return null;
});
