// lib/presentation/community/controllers/community_controller.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/community_entity.dart';
import '../../../data/repositories/community_repository_impl.dart';

// ── Repository ────────────────────────────────────────────────────────────────

final communityRepositoryProvider = Provider<CommunityRepositoryImpl>((ref) {
  return CommunityRepositoryImpl();
});

// ── Tab / Filter State ────────────────────────────────────────────────────────

/// 0 = General, 1 = Book Groups
final communityTabProvider = StateProvider<int>((ref) => 0);

/// Sub-filter: 0 = Public, 1 = My Communities, 2 = Private
final communitySubFilterProvider = StateProvider<int>((ref) => 0);

/// Search query for community discovery
final communitySearchProvider = StateProvider<String>((ref) => '');

// ── Public Communities ────────────────────────────────────────────────────────

final publicCommunitiesProvider = FutureProvider.autoDispose
    .family<List<CommunityEntity>, String>((ref, type) async {
  final repo = ref.watch(communityRepositoryProvider);
  final search = ref.watch(communitySearchProvider);
  return repo.getPublicCommunities(type: type, search: search);
});

// ── Book-specific communities ─────────────────────────────────────────────────

final bookCommunitiesProvider = FutureProvider.autoDispose
    .family<List<CommunityEntity>, String>((ref, bookId) async {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.getPublicCommunities(type: 'book', bookId: bookId);
});

// ── My Communities ────────────────────────────────────────────────────────────

final myCommunitiesProvider = FutureProvider.autoDispose<List<CommunityEntity>>((ref) async {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.getMyCommunities();
});

final myPrivateCommunitiesProvider = FutureProvider.autoDispose<List<CommunityEntity>>((ref) async {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.getMyPrivateCommunities();
});

// ── Buddy Suggestions ─────────────────────────────────────────────────────────

final buddySuggestionsProvider = FutureProvider.autoDispose<List<CommunityEntity>>((ref) async {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.getBuddySuggestions();
});

// ── Community Detail ──────────────────────────────────────────────────────────

final communityDetailProvider = FutureProvider.autoDispose
    .family<CommunityEntity, String>((ref, id) async {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.getCommunityDetail(id);
});

// ── Community Members ─────────────────────────────────────────────────────────

final communityMembersProvider = FutureProvider.autoDispose
    .family<List<CommunityMemberEntity>, String>((ref, id) async {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.getMembers(id);
});

// ── Messages Controller ───────────────────────────────────────────────────────

class MessagesState {
  final List<MessageEntity> messages;
  final bool isLoading;
  final bool isSending;
  final String? error;
  final MessageEntity? replyingTo;

  const MessagesState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
    this.replyingTo,
  });

  MessagesState copyWith({
    List<MessageEntity>? messages,
    bool? isLoading,
    bool? isSending,
    String? error,
    MessageEntity? replyingTo,
    bool clearReply = false,
  }) {
    return MessagesState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: error ?? this.error,
      replyingTo: clearReply ? null : (replyingTo ?? this.replyingTo),
    );
  }
}

class MessagesController extends AutoDisposeFamilyNotifier<MessagesState, String> {
  Timer? _pollTimer;

  @override
  MessagesState build(String arg) {
    ref.onDispose(() => _pollTimer?.cancel());
    _loadMessages();
    _startPolling();
    return const MessagesState(isLoading: true);
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadMessages(silent: true);
    });
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true);
    }
    try {
      final repo = ref.read(communityRepositoryProvider);
      final msgs = await repo.getMessages(arg);
      state = state.copyWith(messages: msgs, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    state = state.copyWith(isSending: true);

    final replyId = state.replyingTo?.id;

    try {
      final repo = ref.read(communityRepositoryProvider);
      final msg = await repo.sendMessage(arg, content.trim(), replyToId: replyId);
      state = state.copyWith(
        messages: [...state.messages, msg],
        isSending: false,
        clearReply: true,
      );
    } catch (e) {
      state = state.copyWith(isSending: false, error: e.toString());
    }
  }

  void setReplyingTo(MessageEntity? message) {
    state = state.copyWith(replyingTo: message, clearReply: message == null);
  }

  Future<void> toggleReaction(String messageId, String emoji) async {
    try {
      final repo = ref.read(communityRepositoryProvider);
      await repo.toggleReaction(messageId, emoji);
      await _loadMessages(silent: true);
    } catch (_) {}
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      final repo = ref.read(communityRepositoryProvider);
      await repo.deleteMessage(messageId);
      state = state.copyWith(
        messages: state.messages
            .map((m) => m.id == messageId
                ? MessageEntity(
                    id: m.id,
                    senderId: m.senderId,
                    senderName: m.senderName,
                    senderAvatarUrl: m.senderAvatarUrl,
                    content: 'This message was deleted.',
                    reactions: const [],
                    isDeleted: true,
                    isMine: m.isMine,
                    timeLabel: m.timeLabel,
                    createdAt: m.createdAt,
                  )
                : m)
            .toList(),
      );
    } catch (_) {}
  }

  Future<void> refresh() => _loadMessages();
}

final messagesControllerProvider = NotifierProvider.autoDispose
    .family<MessagesController, MessagesState, String>(
  MessagesController.new,
);

// ── Community Action Controller ───────────────────────────────────────────────
// NOT autoDispose so state persists across modal open/close

class CommunityActionState {
  final bool isLoading;
  final String? error;
  final CommunityEntity? createdCommunity;

  const CommunityActionState({
    this.isLoading = false,
    this.error,
    this.createdCommunity,
  });

  CommunityActionState copyWith({
    bool? isLoading,
    String? error,
    CommunityEntity? createdCommunity,
    bool clearCreated = false,
  }) {
    return CommunityActionState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      createdCommunity: clearCreated ? null : (createdCommunity ?? this.createdCommunity),
    );
  }
}

class CommunityActionController extends Notifier<CommunityActionState> {
  @override
  CommunityActionState build() => const CommunityActionState();

  void reset() {
    state = const CommunityActionState();
  }

  Future<CommunityEntity?> createCommunity(CreateCommunityParams params) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(communityRepositoryProvider);
      final community = await repo.createCommunity(params);
      state = state.copyWith(isLoading: false, createdCommunity: community);
      // Invalidate all community lists
      ref.invalidate(myCommunitiesProvider);
      ref.invalidate(myPrivateCommunitiesProvider);
      ref.invalidate(publicCommunitiesProvider('general'));
      ref.invalidate(publicCommunitiesProvider('book'));
      return community;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<bool> joinCommunity(String communityId) async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = ref.read(communityRepositoryProvider);
      await repo.joinCommunity(communityId);
      ref.invalidate(myCommunitiesProvider);
      ref.invalidate(publicCommunitiesProvider('general'));
      ref.invalidate(publicCommunitiesProvider('book'));
      ref.invalidate(communityDetailProvider(communityId));
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> leaveCommunity(String communityId) async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = ref.read(communityRepositoryProvider);
      await repo.leaveCommunity(communityId);
      ref.invalidate(myCommunitiesProvider);
      ref.invalidate(communityDetailProvider(communityId));
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<CommunityEntity?> joinByInvite(String token) async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = ref.read(communityRepositoryProvider);
      final community = await repo.joinByInvite(token);
      ref.invalidate(myCommunitiesProvider);
      ref.invalidate(myPrivateCommunitiesProvider);
      state = state.copyWith(isLoading: false);
      return community;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }
}

final communityActionProvider =
    NotifierProvider<CommunityActionController, CommunityActionState>(
  CommunityActionController.new,
);