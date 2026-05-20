import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:readify_app/data/repositories/book_repository_impl.dart';
import 'package:readify_app/domain/entities/book_entity.dart';
import 'package:readify_app/domain/entities/user_stats_entity.dart';
import 'package:readify_app/domain/repositories/book_repository.dart';
import '../../../core/providers/progress_refresh_provider.dart';
import '../../../data/network/api_client.dart';

// ── Repository Provider ──────────────────────────────────────────────────────
final bookRepositoryProvider = Provider<BookRepository>((ref) {
  return BookRepositoryImpl();
});

// ── Home Screen Providers ─────────────────────────────────────────────────────

/// Returns the user's currently reading progress.
/// Returns null (no error) when the user has no book in progress yet,
/// so the home screen can show an empty state instead of an error card.
final currentProgressProvider = FutureProvider<UserProgressEntity?>((ref) async {
  ref.watch(progressRefreshProvider);
  final repo = ref.watch(bookRepositoryProvider);
  try {
    return await repo.getCurrentProgress();
  } on ApiException catch (e) {
    // 404 means no book in progress — not an error, just no data
    if (e.statusCode == 404) return null;
    rethrow;
  } catch (_) {
    rethrow;
  }
});

/// Returns today's reading insights.
/// Never throws — returns zeros when the user has no reading history.
final insightsProvider = FutureProvider<InsightsEntity>((ref) async {
  ref.watch(progressRefreshProvider);
  final repo = ref.watch(bookRepositoryProvider);
  try {
    return await repo.getDailyInsights();
  } catch (_) {
    // Return zeros so the UI always renders something meaningful
    return const InsightsEntity(
      cardsDue: 0,
      readTodayPages: 0,
      dayStreak: 0,
    );
  }
});

final recommendedBooksProvider = FutureProvider<List<BookEntity>>((ref) {
  final repo = ref.watch(bookRepositoryProvider);
  return repo.getRecommendedBooks();
});

final trendingBooksProvider = FutureProvider<List<BookEntity>>((ref) {
  final repo = ref.watch(bookRepositoryProvider);
  return repo.getTrendingBooks();
});

final libraryBooksProvider = FutureProvider<List<BookEntity>>((ref) {
  ref.watch(progressRefreshProvider);
  final repo = ref.watch(bookRepositoryProvider);
  return repo.getLibraryBooks();
});