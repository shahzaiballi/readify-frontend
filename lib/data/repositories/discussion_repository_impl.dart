import '../../domain/entities/post_entity.dart';
import '../../domain/entities/reply_entity.dart';
import '../../domain/repositories/discussion_repository.dart';
import '../network/api_client.dart';

class DiscussionRepositoryImpl implements DiscussionRepository {
  final ApiClient _api = ApiClient.instance;

  // ── Posts ─────────────────────────────────────────────────────────────

  @override
  Future<List<PostEntity>> getPosts({String filter = 'All'}) async {
    final data = await _api.get(
      '/discussions/',
      queryParameters: {'filter': filter},
    ) as List;
    return data.map((e) => _parsePost(e)).toList();
  }

  Future<List<PostEntity>> getPostsByBook(String bookId) async {
    final data = await _api.get(
      '/discussions/',
      queryParameters: {'book_id': bookId},
    ) as List;
    return data.map((e) => _parsePost(e)).toList();
  }

  @override
  Future<PostEntity> getPostDetails(String postId) async {
    final data = await _api.get('/discussions/$postId/');
    return _parsePost(data);
  }

  Future<PostEntity> createPost({
    required String title,
    required String content,
    String? bookId,
    String? chapterTag,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'content': content,
    };
    if (bookId != null && bookId.isNotEmpty) body['book_id'] = bookId;
    if (chapterTag != null && chapterTag.isNotEmpty) {
      body['chapter_tag'] = chapterTag;
    }

    final data = await _api.post('/discussions/', body: body);
    return _parsePost(data);
  }

  Future<void> deletePost(String postId) async {
    await _api.delete('/discussions/$postId/');
  }

  // ── Likes ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> togglePostLike(String postId) async {
    final data = await _api.post('/discussions/$postId/like/');
    return {
      'liked': data['liked'] as bool,
      'likesCount': data['likesCount'] as int,
    };
  }

  Future<Map<String, dynamic>> toggleReplyLike(String replyId) async {
    final data = await _api.post(
      '/discussions/replies/$replyId/like/',
    );
    return {
      'liked': data['liked'] as bool,
      'likesCount': data['likesCount'] as int,
    };
  }

  // ── Replies ───────────────────────────────────────────────────────────

  @override
  Future<List<ReplyEntity>> getReplies(String postId) async {
    final data = await _api.get(
      '/discussions/$postId/replies/',
    ) as List;
    return data.map((e) => _parseReply(e)).toList();
  }

  Future<ReplyEntity> createReply({
    required String postId,
    required String content,
  }) async {
    final data = await _api.post(
      '/discussions/$postId/replies/',
      body: {'content': content},
    );
    return _parseReply(data);
  }

  // ── Parsers ───────────────────────────────────────────────────────────

  PostEntity _parsePost(Map<String, dynamic> data) {
    return PostEntity(
      id: data['id'].toString(),
      userName: data['userName'] ?? '',
      userAvatarUrl: data['userAvatarUrl'] ?? '',
      timeAgo: data['timeAgo'] ?? '',
      chapterTag: data['chapterTag']?.toString().isNotEmpty == true
          ? data['chapterTag']
          : null,
      title: data['title'] ?? '',
      contentSnippet: data['contentSnippet'] ?? '',
      likesCount: data['likesCount'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
      bookId: data['bookId']?.toString() ?? '',
    );
  }

  ReplyEntity _parseReply(Map<String, dynamic> data) {
    return ReplyEntity(
      id: data['id'].toString(),
      userName: data['userName'] ?? '',
      userAvatarUrl: data['userAvatarUrl'] ?? '',
      timeAgo: data['timeAgo'] ?? '',
      content: data['content'] ?? '',
      likesCount: data['likesCount'] ?? 0,
    );
  }
}