import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/chapter_entity.dart';
import '../../home/controllers/home_controller.dart';
import '../../../core/providers/progress_refresh_provider.dart';

// FutureProvider requiring book ID to fetch the respective chapters.
// Watches [pr3t24NpUrJMNunMMASmhAM953bFGeLXzN7] so chapter completion status
// (isCompleted, isActive) refreshes in real time after reading sessions.
final chapterListProvider = FutureProvider.family<List<ChapterEntity>, String>((ref, bookId) {
  // Real-time update: refetch chapter list when reading progress changes.
  ref.watch(pr3t24NpUrJMNunMMASmhAM953bFGeLXzN7);
  final repo = ref.watch(bookRepositoryProvider);
  return repo.getChapters(bookId);
});