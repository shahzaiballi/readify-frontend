import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/post_entity.dart';
import '../../../../domain/entities/reply_entity.dart';
import '../../../../data/repositories/discussion_repository_impl.dart';
import 'discussion_controller.dart';

// ── Post Detail Provider ──────────────────────────────────────────────────────

final postDetailProvider =
    FutureProvider.family.autoDispose<PostEntity, String>((ref, postId) {
  final repo = ref.watch(discussionRepositoryProvider);
  return repo.getPostDetails(postId);
});

// ── Reply Controller ──────────────────────────────────────────────────────────

class ReplyController
    extends AutoDisposeFamilyAsyncNotifier<List<ReplyEntity>, String> {
  @override
  FutureOr<List<ReplyEntity>> build(String arg) async {
    final repo = ref.watch(discussionRepositoryProvider);
    return repo.getReplies(arg);
  }

  /// Adds a reply — sends to API first, then updates UI on success
  Future<void> addReply(String content) async {
    if (content.trim().isEmpty) return;

    final currentReplies = state.valueOrNull ?? [];

    // Optimistic update — show reply immediately
    final optimisticReply = ReplyEntity(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      userName: 'You',
      userAvatarUrl: 'https://i.pravatar.cc/150?u=current_user',
      timeAgo: 'Just now',
      content: content,
      likesCount: 0,
    );

    state = AsyncData([...currentReplies, optimisticReply]);

    try {
      // Send to backend
      final newReply = await ref
          .read(discussionRepositoryImplProvider)
          .createReply(postId: arg, content: content);

      // Replace optimistic reply with real one from server
      final updated = state.valueOrNull ?? [];
      state = AsyncData(
        updated
            .where((r) => r.id != optimisticReply.id)
            .toList()
          ..add(newReply),
      );
    } catch (e) {
      // Roll back optimistic update on failure
      state = AsyncData(currentReplies);
      rethrow;
    }
  }

  /// Toggles like on a reply in the list
  Future<void> toggleReplyLike(String replyId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    try {
      final result = await ref
          .read(discussionRepositoryImplProvider)
          .toggleReplyLike(replyId);

      state = AsyncData(
        current.map((reply) {
          if (reply.id != replyId) return reply;
          return ReplyEntity(
            id: reply.id,
            userName: reply.userName,
            userAvatarUrl: reply.userAvatarUrl,
            timeAgo: reply.timeAgo,
            content: reply.content,
            likesCount: result['likesCount'] as int,
          );
        }).toList(),
      );
    } catch (_) {
      // Silent fail
    }
  }
}

final replyControllerProvider = AsyncNotifierProvider.autoDispose
    .family<ReplyController, List<ReplyEntity>, String>(
  ReplyController.new,
);