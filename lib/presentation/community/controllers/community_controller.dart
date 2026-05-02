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

/// Search query for community discovery
final communitySearchProvider = StateProvider<String>((ref) => '');

// ── Public Communities (General + Book tabs) ──────────────────────────────────

final publicCommunitiesProvider = FutureProvider.autoDispose
    .family<List<CommunityEntity>, String>((ref, type) async {
  final repo = ref.watch(communityRepositoryProvider);
  final search = ref.watch(communitySearchProvider);
  return repo.getPublicCommunities(type: type, search: search);
});

// ── Book-specific communities (for a given bookId) ────────────────────────────

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

// ── Community Members Provider ──────────────────────────────────────────────

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
      // Refresh to get updated counts
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

// ── Join / Leave Controller ───────────────────────────────────────────────────

class CommunityActionController extends StateNotifier<AsyncValue<void>> {
  final CommunityRepositoryImpl _repo;
  final Ref _ref;

  CommunityActionController(this._repo, this._ref) : super(const AsyncData(null));

  Future<bool> join(String communityId) async {
    state = const AsyncLoading();
    try {
      await _repo.joinCommunity(communityId);
      _ref.invalidate(myCommunitiesProvider);
      _ref.invalidate(publicCommunitiesProvider('general'));
      _ref.invalidate(publicCommunitiesProvider('book'));
      _ref.invalidate(communityDetailProvider(communityId));
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> leave(String communityId) async {
    state = const AsyncLoading();
    try {
      await _repo.leaveCommunity(communityId);
      _ref.invalidate(myCommunitiesProvider);
      _ref.invalidate(communityDetailProvider(communityId));
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  // Backwards-compatible wrappers expected by UI
  Future<bool> joinCommunity(String communityId) => join(communityId);
  Future<bool> leaveCommunity(String communityId) => leave(communityId);

  Future<CommunityEntity?> joinByInvite(String token) async {
    state = const AsyncLoading();
    try {
      final community = await _repo.joinByInvite(token);
      _ref.invalidate(myCommunitiesProvider);
      _ref.invalidate(myPrivateCommunitiesProvider);
      state = const AsyncData(null);
      return community;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<CommunityEntity?> createCommunity(CreateCommunityParams params) async {
    state = const AsyncLoading();
    try {
      final repo = _repo;
      final community = await repo.createCommunity(params);
      _ref.invalidate(myCommunitiesProvider);
      _ref.invalidate(myPrivateCommunitiesProvider);
      _ref.invalidate(publicCommunitiesProvider('general'));
      _ref.invalidate(publicCommunitiesProvider('book'));
      state = const AsyncData(null);
      return community;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }
}

final communityActionProvider =
    StateNotifierProvider.autoDispose<CommunityActionController, AsyncValue<void>>(
  (ref) => CommunityActionController(
    ref.watch(communityRepositoryProvider),
    ref,
  ),
);