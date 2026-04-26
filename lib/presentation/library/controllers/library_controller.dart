import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/library_repository_impl.dart';
import '../../../domain/entities/library_book_entity.dart';
import '../../../domain/repositories/library_repository.dart';
import '../../../core/providers/progress_refresh_provider.dart';
import 'library_state_provider.dart';

// ── Repository Provider ───────────────────────────────────────────────────────
final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return LibraryRepositoryImpl();
});

// Expose the impl directly for methods not on the abstract interface
final libraryImplProvider = Provider<LibraryRepositoryImpl>((ref) {
  return LibraryRepositoryImpl();
});

// ── Filter State ──────────────────────────────────────────────────────────────
// 0 = All, 1 = Favorites, 2 = In Progress, 3 = Completed
final libraryFilterProvider = StateProvider<int>((ref) => 0);

// ── Raw Library List (from API) ───────────────────────────────────────────────
// Watches [pr3t24NpUrJMNunMMASmhAM953bFGeLXzN7] so the library automatically
// refetches when reading progress is updated from the chunked reading screen.
final rawLibraryProvider = FutureProvider<List<LibraryBookEntity>>((ref) {
  // Real-time update: refetch whenever reading progress changes.
  ref.watch(pr3t24NpUrJMNunMMASmhAM953bFGeLXzN7);
  final repo = ref.watch(libraryRepositoryProvider);
  return repo.getUserLibrary();
});

// ── Filtered Library (applies UI-level filters + soft deletes) ───────────────
final filteredLibraryProvider = FutureProvider<List<LibraryBookEntity>>((ref) async {
  final allBooks = await ref.watch(rawLibraryProvider.future);
  final filterIndex = ref.watch(libraryFilterProvider);
  final favoriteIds = ref.watch(favoriteBooksProvider);
  final deletedIds = ref.watch(deletedBooksProvider);

  // Apply soft deletes and merge local favorite toggles (optimistic UI)
  var activeBooks = allBooks
      .where((book) => !deletedIds.contains(book.id))
      .map((book) => book.copyWith(
            isFavorite: favoriteIds.contains(book.id) || book.isFavorite,
          ))
      .toList();

  switch (filterIndex) {
    case 1:
      return activeBooks
          .where((b) => b.isFavorite || favoriteIds.contains(b.id))
          .toList();
    case 2:
      return activeBooks
          .where((b) => b.status == LibraryStatus.inProgress)
          .toList();
    case 3:
      return activeBooks
          .where((b) => b.status == LibraryStatus.completed)
          .toList();
    case 0:
    default:
      return activeBooks;
  }
});