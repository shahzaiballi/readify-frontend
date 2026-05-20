// lib/presentation/community/pages/community_chat_page.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../domain/entities/community_entity.dart';
import '../controllers/community_controller.dart';

// ── Mixed list item: either a date separator (DateTime) or a chat message ──────

class _ChatItem {
  final dynamic data;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  const _ChatItem({
    required this.data,
    this.isFirstInGroup = false,
    this.isLastInGroup = false,
  });
}

// ── Main chat page ─────────────────────────────────────────────────────────────

class CommunityChatPage extends ConsumerStatefulWidget {
  final String communityId;
  const CommunityChatPage({super.key, required this.communityId});

  @override
  ConsumerState<CommunityChatPage> createState() => _CommunityChatPageState();
}

class _CommunityChatPageState extends ConsumerState<CommunityChatPage> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showScrollFab = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final nearBottom =
        _scrollController.position.maxScrollExtent - _scrollController.offset < 150;
    if (_showScrollFab == nearBottom) {
      setState(() => _showScrollFab = !nearBottom);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  List<_ChatItem> _buildItems(List<MessageEntity> messages) {
    final items = <_ChatItem>[];
    DateTime? lastDate;
    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];
      final d = DateTime(msg.createdAt.year, msg.createdAt.month, msg.createdAt.day);
      if (lastDate == null || d != lastDate) {
        items.add(_ChatItem(data: d));
        lastDate = d;
      }
      final isFirst = i == 0 || messages[i].senderId != messages[i - 1].senderId;
      final isLast = i == messages.length - 1 || messages[i].senderId != messages[i + 1].senderId;
      items.add(_ChatItem(data: msg, isFirstInGroup: isFirst, isLastInGroup: isLast));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.communityId;
    final msgState = ref.watch(messagesControllerProvider(id));
    final ctrl = ref.read(messagesControllerProvider(id).notifier);
    final communityAsync = ref.watch(communityDetailProvider(id));

    ref.listen(messagesControllerProvider(id), (prev, next) {
      final wasEmpty = prev?.messages.isEmpty ?? true;
      if (next.messages.length != (prev?.messages.length ?? 0) && wasEmpty) {
        _scrollToBottom();
      }
    });

    final items = _buildItems(msgState.messages);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      appBar: _buildAppBar(context, communityAsync, id),
      body: Column(
        children: [
          if (msgState.replyingTo != null)
            _ReplyBanner(
              message: msgState.replyingTo!,
              onDismiss: () => ctrl.setReplyingTo(null),
            ),
          Expanded(
            child: Stack(
              children: [
                _buildMessageList(context, msgState, items, ctrl),
                if (_showScrollFab)
                  Positioned(
                    bottom: 12,
                    right: 16,
                    child: _ScrollFab(onTap: _scrollToBottom),
                  ),
              ],
            ),
          ),
          _ChatInputBar(
            controller: _textController,
            isSending: msgState.isSending,
            onSend: () async {
              final text = _textController.text.trim();
              if (text.isEmpty) return;
              _textController.clear();
              await ctrl.sendMessage(text);
              _scrollToBottom();
            },
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AsyncValue<CommunityEntity> communityAsync,
    String id,
  ) {
    return AppBar(
      backgroundColor: const Color(0xFF0F1626),
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white70, size: context.responsive.sp(18)),
      ),
      title: communityAsync.when(
        data: (community) => GestureDetector(
          onTap: () => context.push('/community/$id'),
          child: Row(
            children: [
              _ChatAvatar(community: community),
              SizedBox(width: context.responsive.wp(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      community.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: context.responsive.sp(15),
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${community.memberCount} members  •  tap for info',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: context.responsive.sp(10),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.white.withValues(alpha: 0.07), height: 1),
      ),
    );
  }

  Widget _buildMessageList(
    BuildContext context,
    MessagesState msgState,
    List<_ChatItem> items,
    MessagesController ctrl,
  ) {
    if (msgState.isLoading && msgState.messages.isEmpty) {
      return const Center(
        child: CircularProgressIndicator.adaptive(
          valueColor: AlwaysStoppedAnimation(Color(0xFFB062FF)),
        ),
      );
    }
    if (msgState.messages.isEmpty) {
      return _EmptyChat();
    }
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(
        context.responsive.wp(12),
        context.responsive.sp(12),
        context.responsive.wp(12),
        context.responsive.sp(12),
      ),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final item = items[i];
        if (item.data is DateTime) {
          return _DateSeparator(date: item.data as DateTime);
        }
        final msg = item.data as MessageEntity;
        return _MessageBubble(
          message: msg,
          isFirstInGroup: item.isFirstInGroup,
          isLastInGroup: item.isLastInGroup,
          onReply: () => ctrl.setReplyingTo(msg),
          onReact: (emoji) => ctrl.toggleReaction(msg.id, emoji),
          onDelete: msg.isMine ? () => ctrl.deleteMessage(msg.id) : null,
        );
      },
    );
  }
}

// ── Empty chat ────────────────────────────────────────────────────────────────

class _EmptyChat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('💬', style: TextStyle(fontSize: context.responsive.sp(52))),
          SizedBox(height: context.responsive.sp(14)),
          Text(
            'No messages yet',
            style: TextStyle(color: Colors.white54, fontSize: context.responsive.sp(15)),
          ),
          SizedBox(height: context.responsive.sp(6)),
          Text(
            'Be the first to say hello!',
            style: TextStyle(color: Colors.white30, fontSize: context.responsive.sp(12)),
          ),
        ],
      ),
    );
  }
}

// ── Scroll to bottom FAB ──────────────────────────────────────────────────────

class _ScrollFab extends StatelessWidget {
  final VoidCallback onTap;
  const _ScrollFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: context.responsive.sp(38),
        height: context.responsive.sp(38),
        decoration: BoxDecoration(
          color: const Color(0xFF1A223B),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Colors.white70,
          size: context.responsive.sp(22),
        ),
      ),
    );
  }
}

// ── Chat header avatar ────────────────────────────────────────────────────────

class _ChatAvatar extends StatelessWidget {
  final CommunityEntity community;
  const _ChatAvatar({required this.community});

  @override
  Widget build(BuildContext context) {
    final size = context.responsive.sp(36);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF2D1B52), Color(0xFF1A2340)],
        ),
      ),
      child: community.coverImageUrl != null
          ? ClipOval(
              child: Image.network(community.coverImageUrl!, fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Center(
                    child: Text(community.coverEmoji,
                        style: TextStyle(fontSize: size * 0.44)),
                  )))
          : Center(
              child: Text(community.coverEmoji,
                  style: TextStyle(fontSize: size * 0.44))),
    );
  }
}

// ── Date separator pill ───────────────────────────────────────────────────────

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  String get _label {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${date.day} ${_months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: context.responsive.sp(14)),
        padding: EdgeInsets.symmetric(
          horizontal: context.responsive.wp(12),
          vertical: context.responsive.sp(5),
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1A223B),
          borderRadius: BorderRadius.circular(context.responsive.sp(20)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Text(
          _label,
          style: TextStyle(
            color: Colors.white38,
            fontSize: context.responsive.sp(11),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ── Reply banner ──────────────────────────────────────────────────────────────

class _ReplyBanner extends StatelessWidget {
  final MessageEntity message;
  final VoidCallback onDismiss;

  const _ReplyBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.responsive.wp(16),
        vertical: context.responsive.sp(10),
      ),
      color: const Color(0xFF1A223B),
      child: Row(
        children: [
          Container(
            width: 3,
            height: context.responsive.sp(36),
            color: const Color(0xFFB062FF),
          ),
          SizedBox(width: context.responsive.wp(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${message.senderName}',
                  style: TextStyle(
                    color: const Color(0xFFB062FF),
                    fontSize: context.responsive.sp(11),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  message.content,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: context.responsive.sp(12),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close, color: Colors.white38, size: 18),
          ),
        ],
      ),
    );
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final VoidCallback onReply;
  final void Function(String emoji) onReact;
  final VoidCallback? onDelete;

  const _MessageBubble({
    required this.message,
    required this.isFirstInGroup,
    required this.isLastInGroup,
    required this.onReply,
    required this.onReact,
    this.onDelete,
  });

  BorderRadius _radius(bool isMine) {
    const r = 18.0;
    const tail = 4.0;
    if (isMine) {
      return BorderRadius.only(
        topLeft: const Radius.circular(r),
        topRight: Radius.circular(isFirstInGroup ? tail : r),
        bottomLeft: const Radius.circular(r),
        bottomRight: const Radius.circular(r),
      );
    }
    return BorderRadius.only(
      topLeft: Radius.circular(isFirstInGroup ? tail : r),
      topRight: const Radius.circular(r),
      bottomLeft: const Radius.circular(r),
      bottomRight: const Radius.circular(r),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    final isDeleted = message.isDeleted;
    final showAvatar = !isMine;
    final avatarR = context.responsive.sp(14);

    return GestureDetector(
      onLongPress: isDeleted ? null : () {
        HapticFeedback.lightImpact();
        _showActions(context);
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: isLastInGroup
              ? context.responsive.sp(10)
              : context.responsive.sp(2),
        ),
        child: Row(
          mainAxisAlignment:
              isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Avatar space for others
            if (showAvatar)
              Padding(
                padding: EdgeInsets.only(right: context.responsive.wp(8)),
                child: isFirstInGroup
                    ? CircleAvatar(
                        radius: avatarR,
                        backgroundImage: message.senderAvatarUrl.isNotEmpty
                            ? NetworkImage(message.senderAvatarUrl)
                            : null,
                        backgroundColor: const Color(0xFF2D1B52),
                        child: message.senderAvatarUrl.isEmpty
                            ? Text(
                                message.senderName.isNotEmpty
                                    ? message.senderName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: context.responsive.sp(11),
                                ),
                              )
                            : null,
                      )
                    : SizedBox(width: avatarR * 2),
              ),

            Flexible(
              child: Column(
                crossAxisAlignment:
                    isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Sender name (first in group only)
                  if (!isMine && isFirstInGroup)
                    Padding(
                      padding: EdgeInsets.only(
                        left: context.responsive.wp(4),
                        bottom: context.responsive.sp(3),
                      ),
                      child: Text(
                        message.senderName,
                        style: TextStyle(
                          color: const Color(0xFFB062FF),
                          fontSize: context.responsive.sp(11),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  // Reply preview
                  if (message.replyTo != null)
                    Container(
                      margin: EdgeInsets.only(bottom: context.responsive.sp(3)),
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7),
                      padding: EdgeInsets.symmetric(
                        horizontal: context.responsive.wp(10),
                        vertical: context.responsive.sp(6),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(context.responsive.sp(8)),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 2.5,
                            height: context.responsive.sp(28),
                            color: const Color(0xFFB062FF),
                          ),
                          SizedBox(width: context.responsive.wp(7)),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.replyTo!.senderName,
                                  style: TextStyle(
                                    color: const Color(0xFFB062FF),
                                    fontSize: context.responsive.sp(10),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  message.replyTo!.contentPreview,
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: context.responsive.sp(11),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Bubble
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.72,
                    ),
                    padding: EdgeInsets.fromLTRB(
                      context.responsive.wp(13),
                      context.responsive.sp(9),
                      context.responsive.wp(13),
                      context.responsive.sp(7),
                    ),
                    decoration: BoxDecoration(
                      gradient: isDeleted
                          ? null
                          : isMine
                              ? const LinearGradient(
                                  colors: [Color(0xFF9B4DFF), Color(0xFFB062FF)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                      color: isDeleted
                          ? Colors.white.withValues(alpha: 0.04)
                          : isMine
                              ? null
                              : const Color(0xFF1A223B),
                      borderRadius: _radius(isMine),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          message.content,
                          style: TextStyle(
                            color: isDeleted ? Colors.white30 : Colors.white,
                            fontSize: context.responsive.sp(14),
                            fontStyle: isDeleted
                                ? FontStyle.italic
                                : FontStyle.normal,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: context.responsive.sp(2)),
                        Text(
                          message.timeLabel,
                          style: TextStyle(
                            color: isMine
                                ? Colors.white.withValues(alpha: 0.55)
                                : Colors.white30,
                            fontSize: context.responsive.sp(9),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Reactions
                  if (message.reactions.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: context.responsive.sp(4)),
                      child: Wrap(
                        spacing: context.responsive.wp(4),
                        runSpacing: context.responsive.sp(3),
                        children: message.reactions.map((r) {
                          return GestureDetector(
                            onTap: () => onReact(r.emoji),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.responsive.wp(7),
                                vertical: context.responsive.sp(3),
                              ),
                              decoration: BoxDecoration(
                                color: r.reactedByMe
                                    ? const Color(0xFFB062FF).withValues(alpha: 0.2)
                                    : Colors.white.withValues(alpha: 0.07),
                                borderRadius:
                                    BorderRadius.circular(context.responsive.sp(12)),
                                border: Border.all(
                                  color: r.reactedByMe
                                      ? const Color(0xFFB062FF).withValues(alpha: 0.5)
                                      : Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Text(
                                '${r.emoji} ${r.count}',
                                style:
                                    TextStyle(fontSize: context.responsive.sp(12)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActions(BuildContext context) {
    final emojis = ['❤️', '👍', '😂', '🔥', '😮', '👏'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF141B2E),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // Emoji picker pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A223B),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: emojis.map((e) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        onReact(e);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(e, style: const TextStyle(fontSize: 28)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              Divider(color: Colors.white.withValues(alpha: 0.06)),
              _ActionRow(
                icon: Icons.reply_rounded,
                label: 'Reply',
                onTap: () {
                  Navigator.pop(context);
                  onReply();
                },
              ),
              if (onDelete != null)
                _ActionRow(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete message',
                  color: Colors.redAccent,
                  onTap: () {
                    Navigator.pop(context);
                    onDelete!();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Action row ────────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.responsive.wp(4),
          vertical: context.responsive.sp(12),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(context.responsive.sp(8)),
              decoration: BoxDecoration(
                color: (color ?? Colors.white).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(context.responsive.sp(10)),
              ),
              child: Icon(icon, color: c, size: context.responsive.sp(18)),
            ),
            SizedBox(width: context.responsive.wp(12)),
            Text(label,
                style: TextStyle(color: c, fontSize: context.responsive.sp(14))),
          ],
        ),
      ),
    );
  }
}

// ── Chat input bar ────────────────────────────────────────────────────────────

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _ChatInputBar({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.responsive.wp(14),
        context.responsive.sp(10),
        context.responsive.wp(14),
        context.responsive.sp(10) + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1626),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A223B),
                borderRadius: BorderRadius.circular(context.responsive.sp(22)),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: TextField(
                controller: controller,
                maxLines: 5,
                minLines: 1,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: context.responsive.sp(14),
                ),
                decoration: InputDecoration(
                  hintText: 'Message…',
                  hintStyle: TextStyle(
                    color: Colors.white30,
                    fontSize: context.responsive.sp(14),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: context.responsive.wp(16),
                    vertical: context.responsive.sp(11),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: context.responsive.wp(10)),
          GestureDetector(
            onTap: isSending ? null : onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: context.responsive.sp(44),
              height: context.responsive.sp(44),
              decoration: BoxDecoration(
                gradient: isSending
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFFB062FF), Color(0xFF7B3FF2)],
                      ),
                color: isSending ? Colors.white12 : null,
                shape: BoxShape.circle,
                boxShadow: isSending
                    ? null
                    : [
                        BoxShadow(
                          color: const Color(0xFFB062FF).withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: isSending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Icon(Icons.send_rounded,
                      color: Colors.white, size: context.responsive.sp(20)),
            ),
          ),
        ],
      ),
    );
  }
}