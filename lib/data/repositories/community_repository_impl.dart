// lib/data/repositories/community_repository_impl.dart

import '../../domain/entities/community_entity.dart';
import '../network/api_client.dart';

class CommunityRepositoryImpl {
  final ApiClient _api = ApiClient.instance;

  // ── Parsers ───────────────────────────────────────────────────────────────

  CommunityMemberEntity _parseMember(Map<String, dynamic> d) {
    return CommunityMemberEntity(
      id: d['id'].toString(),
      name: d['name'] ?? '',
      avatarUrl: d['avatarUrl'] ?? '',
      memberSince: d['memberSince'] ?? '',
      booksReading: d['booksReading'] ?? 0,
    );
  }

  ReactionEntity _parseReaction(Map<String, dynamic> d) {
    return ReactionEntity(
      emoji: d['emoji'] ?? '',
      count: d['count'] ?? 0,
      reactedByMe: d['reactedByMe'] ?? false,
    );
  }

  ReplyPreviewEntity? _parseReplyPreview(Map<String, dynamic>? d) {
    if (d == null) return null;
    return ReplyPreviewEntity(
      id: d['id'].toString(),
      senderName: d['senderName'] ?? '',
      contentPreview: d['contentPreview'] ?? '',
    );
  }

  MessageEntity _parseMessage(Map<String, dynamic> d) {
    return MessageEntity(
      id: d['id'].toString(),
      senderId: d['senderId'].toString(),
      senderName: d['senderName'] ?? '',
      senderAvatarUrl: d['senderAvatarUrl'] ?? '',
      content: d['content'] ?? '',
      reactions: (d['reactions'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map(_parseReaction)
          .toList(),
      replyTo: _parseReplyPreview(d['replyTo'] as Map<String, dynamic>?),
      isDeleted: d['isDeleted'] ?? false,
      isMine: d['isMine'] ?? false,
      timeLabel: d['timeLabel'] ?? '',
      createdAt: DateTime.tryParse(d['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  LastMessagePreview? _parseLastMessage(Map<String, dynamic>? d) {
    if (d == null) return null;
    return LastMessagePreview(
      senderName: d['senderName'] ?? '',
      content: d['content'] ?? '',
      timeLabel: d['timeLabel'] ?? '',
    );
  }

  CommunityEntity _parseCommunity(Map<String, dynamic> d) {
    return CommunityEntity(
      id: d['id'].toString(),
      name: d['name'] ?? '',
      description: d['description'] ?? '',
      communityType: d['community_type'] ?? 'general',
      privacy: d['privacy'] ?? 'public',
      memberCount: d['member_count'] ?? 0,
      coverEmoji: d['cover_emoji'] ?? '📚',
      coverImageUrl: d['coverImageUrl'] as String?,
      bookTitle: d['bookTitle'] as String?,
      bookCover: d['bookCover'] as String?,
      isMember: d['isMember'] ?? false,
      isAdmin: d['isAdmin'] ?? false,
      lastMessage: _parseLastMessage(d['lastMessage'] as Map<String, dynamic>?),
      members: (d['members'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map(_parseMember)
          .toList(),
      inviteToken: d['inviteLink'] as String?,
      createdAt: DateTime.tryParse(d['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  // ── API Methods ───────────────────────────────────────────────────────────

  Future<List<CommunityEntity>> getPublicCommunities({
    String? type,
    String? bookId,
    String? search,
  }) async {
    final Map<String, dynamic> params = {};
    if (type != null) params['type'] = type;
    if (bookId != null) params['book_id'] = bookId;
    if (search != null && search.isNotEmpty) params['search'] = search;

    final data = await _api.get(
      '/api/v1/community/',
      queryParameters: params,
    ) as List<dynamic>;
    return data.cast<Map<String, dynamic>>().map(_parseCommunity).toList();
  }

  Future<List<CommunityEntity>> getMyCommunities() async {
    final data = await _api.get(
      '/api/v1/community/',
      queryParameters: {'mine': 'true'},
    ) as List<dynamic>;
    return data.cast<Map<String, dynamic>>().map(_parseCommunity).toList();
  }

  Future<List<CommunityEntity>> getMyPrivateCommunities() async {
    final data = await _api.get(
      '/api/v1/community/',
      queryParameters: {'private': 'true'},
    ) as List<dynamic>;
    return data.cast<Map<String, dynamic>>().map(_parseCommunity).toList();
  }

  Future<CommunityEntity> getCommunityDetail(String id) async {
    final data = await _api.get('/api/v1/community/$id/') as Map<String, dynamic>;
    return _parseCommunity(data);
  }

  Future<CommunityEntity> createCommunity(CreateCommunityParams params) async {
    final body = <String, dynamic>{
      'name': params.name,
      'description': params.description,
      'community_type': params.communityType,
      'privacy': params.privacy,
      'cover_emoji': params.coverEmoji,
    };
    if (params.bookId != null) body['book_id'] = params.bookId;

    final data = await _api.post('/api/v1/community/', body: body) as Map<String, dynamic>;
    return _parseCommunity(data);
  }

  Future<Map<String, dynamic>> joinCommunity(String id) async {
    return await _api.post('/api/v1/community/$id/join/') as Map<String, dynamic>;
  }

  Future<void> leaveCommunity(String id) async {
    await _api.post('/api/v1/community/$id/leave/');
  }

  Future<CommunityEntity> joinByInvite(String token) async {
    final data = await _api.post('/api/v1/community/join/$token/') as Map<String, dynamic>;
    return _parseCommunity(data);
  }

  Future<List<MessageEntity>> getMessages(String communityId, {String? beforeId}) async {
    final params = <String, dynamic>{};
    if (beforeId != null) params['before'] = beforeId;

    final data = await _api.get(
      '/api/v1/community/$communityId/messages/',
      queryParameters: params,
    ) as List<dynamic>;
    return data.cast<Map<String, dynamic>>().map(_parseMessage).toList();
  }

  Future<MessageEntity> sendMessage(
    String communityId,
    String content, {
    String? replyToId,
  }) async {
    final body = <String, dynamic>{'content': content};
    if (replyToId != null) body['reply_to_id'] = replyToId;

    final data = await _api.post(
      '/api/v1/community/$communityId/messages/',
      body: body,
    ) as Map<String, dynamic>;
    return _parseMessage(data);
  }

  Future<void> toggleReaction(String messageId, String emoji) async {
    await _api.post(
      '/api/v1/community/messages/$messageId/react/',
      body: {'emoji': emoji},
    );
  }

  Future<void> deleteMessage(String messageId) async {
    await _api.delete('/api/v1/community/messages/$messageId/');
  }

  Future<List<CommunityEntity>> getBuddySuggestions() async {
    final data = await _api.get('/api/v1/community/suggestions/buddy/') as List<dynamic>;
    return data.cast<Map<String, dynamic>>().map(_parseCommunity).toList();
  }

  Future<List<CommunityMemberEntity>> getMembers(String communityId) async {
    final data = await _api.get('/api/v1/community/$communityId/members/') as List<dynamic>;
    return data.cast<Map<String, dynamic>>().map(_parseMember).toList();
  }
}