// lib/domain/entities/community_entity.dart

class CommunityMemberEntity {
  final String id;
  final String name;
  final String avatarUrl;
  final String memberSince;
  final int booksReading;

  const CommunityMemberEntity({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.memberSince,
    required this.booksReading,
  });
}

class ReactionEntity {
  final String emoji;
  final int count;
  final bool reactedByMe;

  const ReactionEntity({
    required this.emoji,
    required this.count,
    required this.reactedByMe,
  });
}

class ReplyPreviewEntity {
  final String id;
  final String senderName;
  final String contentPreview;

  const ReplyPreviewEntity({
    required this.id,
    required this.senderName,
    required this.contentPreview,
  });
}

class MessageEntity {
  final String id;
  final String senderId;
  final String senderName;
  final String senderAvatarUrl;
  final String content;
  final List<ReactionEntity> reactions;
  final ReplyPreviewEntity? replyTo;
  final bool isDeleted;
  final bool isMine;
  final String timeLabel;
  final DateTime createdAt;

  const MessageEntity({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderAvatarUrl,
    required this.content,
    required this.reactions,
    this.replyTo,
    required this.isDeleted,
    required this.isMine,
    required this.timeLabel,
    required this.createdAt,
  });
}

class LastMessagePreview {
  final String senderName;
  final String content;
  final String timeLabel;

  const LastMessagePreview({
    required this.senderName,
    required this.content,
    required this.timeLabel,
  });
}

class CommunityEntity {
  final String id;
  final String name;
  final String description;
  final String communityType; // 'general' | 'book'
  final String privacy; // 'public' | 'private'
  final int memberCount;
  final String coverEmoji;
  final String? coverImageUrl;
  final String? bookTitle;
  final String? bookCover;
  final bool isMember;
  final bool isAdmin;
  final LastMessagePreview? lastMessage;
  final List<CommunityMemberEntity> members;
  final String? inviteToken;
  final DateTime createdAt;

  const CommunityEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.communityType,
    required this.privacy,
    required this.memberCount,
    required this.coverEmoji,
    this.coverImageUrl,
    this.bookTitle,
    this.bookCover,
    required this.isMember,
    required this.isAdmin,
    this.lastMessage,
    this.members = const [],
    this.inviteToken,
    required this.createdAt,
  });

  bool get isJoined => isMember;

  CommunityEntity copyWith({
    bool? isMember,
    bool? isAdmin,
    int? memberCount,
    List<CommunityMemberEntity>? members,
    LastMessagePreview? lastMessage,
  }) {
    return CommunityEntity(
      id: id,
      name: name,
      description: description,
      communityType: communityType,
      privacy: privacy,
      memberCount: memberCount ?? this.memberCount,
      coverEmoji: coverEmoji,
      coverImageUrl: coverImageUrl,
      bookTitle: bookTitle,
      bookCover: bookCover,
      isMember: isMember ?? this.isMember,
      isAdmin: isAdmin ?? this.isAdmin,
      lastMessage: lastMessage ?? this.lastMessage,
      members: members ?? this.members,
      inviteToken: inviteToken,
      createdAt: createdAt,
    );
  }
}

class CreateCommunityParams {
  final String name;
  final String description;
  final String communityType;
  final String privacy;
  final String? bookId;
  final String coverEmoji;

  const CreateCommunityParams({
    required this.name,
    required this.description,
    required this.communityType,
    required this.privacy,
    this.bookId,
    this.coverEmoji = '📚',
  });
}