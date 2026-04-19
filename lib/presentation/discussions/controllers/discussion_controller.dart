import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/post_entity.dart';
import '../../../../domain/repositories/discussion_repository.dart';
import '../../../../data/repositories/discussion_repository_impl.dart';

// ── Repository Provider ───────────────────────────────────────────────────────

final discussionRepositoryProvider = Provider<DiscussionRepository>((ref) {
  return DiscussionRepositoryImpl();
});

final discussionRepositoryImplProvider =
    Provider<DiscussionRepositoryImpl>((ref) {
  return DiscussionRepositoryImpl();
});

// ── Filter Provider ───────────────────────────────────────────────────────────

final discussionFilterProvider = StateProvider<String>((ref) => 'All');

// ── Posts Controller ──────────────────────────────────────────────────────────

class DiscussionController
    extends AutoDisposeAsyncNotifier<List<PostEntity>> {
  @override
  FutureOr<List<PostEntity>> build() async {
    // Re-fetch whenever the filter changes
    final filter = ref.watch(discussionFilterProvider);
    final repo = ref.watch(discussionRepositoryProvider);
    return repo.getPosts(filter: filter);
  }

  /// Called after NewDiscussionPage creates a post — refreshes the feed
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      final filter = ref.read(discussionFilterProvider);
      return ref.read(discussionRepositoryProvider).getPosts(filter: filter);
    });
  }

  /// Optimistically toggles like on a post in the list
  Future<void> toggleLike(String postId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    try {
      final result = await ref
          .read(discussionRepositoryImplProvider)
          .togglePostLike(postId);

      // Update just the affected post in the list
      state = AsyncData(
        current.map((post) {
          if (post.id != postId) return post;
          return PostEntity(
            id: post.id,
            userName: post.userName,
            userAvatarUrl: post.userAvatarUrl,
            timeAgo: post.timeAgo,
            chapterTag: post.chapterTag,
            title: post.title,
            contentSnippet: post.contentSnippet,
            likesCount: result['likesCount'] as int,
            commentsCount: post.commentsCount,
            bookId: post.bookId,
          );
        }).toList(),
      );
    } catch (_) {
      // Silent fail — don't disrupt the feed on a like error
    }
  }
}

final discussionControllerProvider =
    AsyncNotifierProvider.autoDispose<DiscussionController, List<PostEntity>>(
  DiscussionController.new,
);