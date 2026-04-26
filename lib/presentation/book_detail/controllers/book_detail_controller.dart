import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/book_detail_entity.dart';
import '../../home/controllers/home_controller.dart';
import '../../../core/providers/progress_refresh_provider.dart';

// FutureProvider requiring an ID to fetch details.
// Watches [pr3t24NpUrJMNunMMASmhAM953bFGeLXzN7] so progress % shown on the
// book detail page updates automatically after reading sessions.
final bookDetailProvider = FutureProvider.family<BookDetailEntity, String>((ref, id) {
  // Real-time update: refetch book details when reading progress changes.
  ref.watch(pr3t24NpUrJMNunMMASmhAM953bFGeLXzN7);
  final repo = ref.watch(bookRepositoryProvider);
  return repo.getBookDetails(id);
});