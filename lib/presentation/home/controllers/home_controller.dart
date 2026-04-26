import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:readify_app/data/repositories/book_repository_impl.dart';
import 'package:readify_app/domain/entities/book_entity.dart';
import 'package:readify_app/domain/entities/user_stats_entity.dart';
import 'package:readify_app/domain/repositories/book_repository.dart';
import '../../../core/providers/progress_refresh_provider.dart';

// ── Repository Provider ──────────────────────────────────────────────────────
final bookRepositoryProvider = Provider<BookRepository>((ref) {
  return BookRepositoryImpl();
});

// ── Home Screen Providers ─────────────────────────────────────────────────────
// Each provider watches [pr3t24NpUrJMNunMMASmhAM953bFGeLXzN7] so that when the
// trigger increments (after every chunk advance), providers automatically
// refetch their data — giving real-time updates on Home and Library pages.

final currentProgressProvider = FutureProvider<UserProgressEntity>((ref) {
  // Watch the refresh trigger — any increment causes this provider to refetch.
  ref.watch(pr3t24NpUrJMNunMMASmhAM953bFGeLXzN7);
  final repo = ref.watch(bookRepositoryProvider);
  return repo.getCurrentProgress();
});

final insightsProvider = FutureProvider<InsightsEntity>((ref) {
  // Watch the refresh trigger for real-time insights updates.
  ref.watch(pr3t24NpUrJMNunMMASmhAM953bFGeLXzN7);
  final repo = ref.watch(bookRepositoryProvider);
  return repo.getDailyInsights();
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
  // Watch the refresh trigger so the home screen library section updates
  // when reading progress changes.
  ref.watch(pr3t24NpUrJMNunMMASmhAM953bFGeLXzN7);
  final repo = ref.watch(bookRepositoryProvider);
  return repo.getLibraryBooks();
});