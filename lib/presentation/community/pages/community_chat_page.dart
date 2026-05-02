// lib/presentation/community/pages/community_chat_page.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../domain/entities/community_entity.dart';
import '../controllers/community_controller.dart';

class CommunityChatPage extends ConsumerStatefulWidget {
  final String communityId;

  const CommunityChatPage({super.key, required this.communityId});

  @override
  ConsumerState<CommunityChatPage> createState() => _CommunityChatPageState();
}

class _CommunityChatPageState extends ConsumerState<CommunityChatPage> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final params = widget.communityId;
    final messagesState = ref.watch(messagesControllerProvider(params));
    final controller = ref.read(messagesControllerProvider(params).notifier);
    final communityAsync = ref.watch(communityDetailProvider(params));

    // Scroll to bottom when new messages arrive
    ref.listen(messagesControllerProvider(params), (_, next) {
      if (next.messages.isNotEmpty) _scrollToBottom();
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1626),
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Container(
            padding: EdgeInsets.all(context.responsive.sp(8)),
            decoration: const BoxDecoration(
              color: Color(0xFF1A223B),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: context.responsive.sp(18),
            ),
          ),
        ),
        title: communityAsync.when(
          data: (community) => Row(
            children: [
              Container(
                width: context.responsive.sp(34),
                height: context.responsive.sp(34),
                decoration: BoxDecoration(
                  color: const Color(0xFF381A5D),
                  borderRadius: BorderRadius.circular(context.responsive.sp(8)),
                ),
                child: Center(
                  child: Text(
                    community.coverEmoji,
                    style: TextStyle(fontSize: context.responsive.sp(17)),
                  ),
                ),
              ),
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
                      '${community.memberCount} members',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: context.responsive.sp(11),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ),
      body: Column(
        children: [
          // Reply banner
          if (messagesState.replyingTo != null)
            _ReplyBanner(
              message: messagesState.replyingTo!,
              onDismiss: () => controller.setReplyingTo(null),
            ),

          // Messages list
          Expanded(
            child: messagesState.isLoading && messagesState.messages.isEmpty
                ? const Center(
                    child: CircularProgressIndicator.adaptive(
                      valueColor:
                          AlwaysStoppedAnimation(Color(0xFFB062FF)),
                    ),
                  )
                : messagesState.messages.isEmpty
                    ? _EmptyChat()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.symmetric(
                          horizontal: context.responsive.wp(16),
                          vertical: context.responsive.sp(12),
                        ),
                        itemCount: messagesState.messages.length,
                        itemBuilder: (context, index) {
                          final msg = messagesState.messages[index];
                          return _MessageBubble(
                            message: msg,
                            onReply: () => controller.setReplyingTo(msg),
                            onReact: (emoji) =>
                                controller.toggleReaction(msg.id, emoji),
                            onDelete: msg.isMine
                                ? () => controller.deleteMessage(msg.id)
                                : null,
                          );
                        },
                      ),
          ),

          // Input bar
          _ChatInputBar(
            controller: _textController,
            isSending: messagesState.isSending,
            onSend: () async {
              final text = _textController.text.trim();
              if (text.isEmpty) return;
              _textController.clear();
              await controller.sendMessage(text);
              _scrollToBottom();
            },
          ),
        ],
      ),
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
          Text('💬', style: TextStyle(fontSize: context.responsive.sp(48))),
          SizedBox(height: context.responsive.sp(12)),
          Text(
            'No messages yet',
            style: TextStyle(
              color: Colors.white54,
              fontSize: context.responsive.sp(15),
            ),
          ),
          SizedBox(height: context.responsive.sp(6)),
          Text(
            'Be the first to say hello!',
            style: TextStyle(
              color: Colors.white30,
              fontSize: context.responsive.sp(12),
            ),
          ),
        ],
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
  final VoidCallback onReply;
  final void Function(String emoji) onReact;
  final VoidCallback? onDelete;

  const _MessageBubble({
    required this.message,
    required this.onReply,
    required this.onReact,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    final isDeleted = message.isDeleted;

    return GestureDetector(
      onLongPress: isDeleted
          ? null
          : () => _showActions(context),
      child: Padding(
        padding: EdgeInsets.only(bottom: context.responsive.sp(8)),
        child: Row(
          mainAxisAlignment:
              isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMine) ...[
              CircleAvatar(
                radius: context.responsive.sp(14),
                backgroundImage: message.senderAvatarUrl.isNotEmpty
                    ? NetworkImage(message.senderAvatarUrl)
                    : null,
                backgroundColor: const Color(0xFF381A5D),
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
              ),
              SizedBox(width: context.responsive.wp(8)),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment:
                    isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMine)
                    Padding(
                      padding: EdgeInsets.only(
                        left: context.responsive.wp(4),
                        bottom: context.responsive.sp(3),
                      ),
                      child: Text(
                        message.senderName,
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: context.responsive.sp(11),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  // Reply preview
                  if (message.replyTo != null)
                    Container(
                      margin: EdgeInsets.only(
                          bottom: context.responsive.sp(3)),
                      padding: EdgeInsets.symmetric(
                        horizontal: context.responsive.wp(10),
                        vertical: context.responsive.sp(6),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(
                            context.responsive.sp(8)),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
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

                  // Bubble
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.72,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: context.responsive.wp(14),
                      vertical: context.responsive.sp(10),
                    ),
                    decoration: BoxDecoration(
                      color: isDeleted
                          ? Colors.white.withOpacity(0.04)
                          : isMine
                              ? const Color(0xFFB062FF)
                              : const Color(0xFF1A223B),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(context.responsive.sp(16)),
                        topRight: Radius.circular(context.responsive.sp(16)),
                        bottomLeft: Radius.circular(
                            isMine ? context.responsive.sp(16) : 4),
                        bottomRight: Radius.circular(
                            isMine ? 4 : context.responsive.sp(16)),
                      ),
                    ),
                    child: Text(
                      message.content,
                      style: TextStyle(
                        color: isDeleted ? Colors.white30 : Colors.white,
                        fontSize: context.responsive.sp(14),
                        fontStyle:
                            isDeleted ? FontStyle.italic : FontStyle.normal,
                        height: 1.4,
                      ),
                    ),
                  ),

                  // Reactions
                  if (message.reactions.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: context.responsive.sp(4)),
                      child: Wrap(
                        spacing: context.responsive.wp(4),
                        children: message.reactions.map((r) {
                          return GestureDetector(
                            onTap: () => onReact(r.emoji),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.responsive.wp(6),
                                vertical: context.responsive.sp(2),
                              ),
                              decoration: BoxDecoration(
                                color: r.reactedByMe
                                    ? const Color(0xFFB062FF)
                                        .withOpacity(0.2)
                                    : Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(
                                    context.responsive.sp(10)),
                                border: Border.all(
                                  color: r.reactedByMe
                                      ? const Color(0xFFB062FF)
                                          .withOpacity(0.4)
                                      : Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: Text(
                                '${r.emoji} ${r.count}',
                                style: TextStyle(
                                    fontSize: context.responsive.sp(11)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  // Time
                  Padding(
                    padding: EdgeInsets.only(
                      top: context.responsive.sp(3),
                      left: context.responsive.wp(4),
                      right: context.responsive.wp(4),
                    ),
                    child: Text(
                      message.timeLabel,
                      style: TextStyle(
                        color: Colors.white30,
                        fontSize: context.responsive.sp(10),
                      ),
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
        padding: EdgeInsets.all(context.responsive.sp(20)),
        decoration: BoxDecoration(
          color: const Color(0xFF1A223B),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(context.responsive.sp(20)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick reactions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: emojis.map((e) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onReact(e);
                  },
                  child: Text(
                    e,
                    style: TextStyle(fontSize: context.responsive.sp(28)),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: context.responsive.sp(16)),
            // Actions
            _ActionRow(
              icon: Icons.reply,
              label: 'Reply',
              onTap: () {
                Navigator.pop(context);
                onReply();
              },
            ),
            if (onDelete != null)
              _ActionRow(
                icon: Icons.delete_outline,
                label: 'Delete',
                color: Colors.redAccent,
                onTap: () {
                  Navigator.pop(context);
                  onDelete!();
                },
              ),
          ],
        ),
      ),
    );
  }
}

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
    return ListTile(
      leading: Icon(icon, color: c, size: context.responsive.sp(20)),
      title: Text(
        label,
        style: TextStyle(color: c, fontSize: context.responsive.sp(14)),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
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
        context.responsive.wp(16),
        context.responsive.sp(10),
        context.responsive.wp(16),
        context.responsive.sp(10) + MediaQuery.of(context).padding.bottom,
      ),
      color: const Color(0xFF0F1626),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A223B),
                borderRadius: BorderRadius.circular(context.responsive.sp(24)),
                border: Border.all(color: Colors.white12),
              ),
              child: TextField(
                controller: controller,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: context.responsive.sp(14),
                ),
                decoration: InputDecoration(
                  hintText: 'Message…',
                  hintStyle: TextStyle(
                    color: Colors.white38,
                    fontSize: context.responsive.sp(14),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: context.responsive.wp(16),
                    vertical: context.responsive.sp(11),
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          SizedBox(width: context.responsive.wp(10)),
          GestureDetector(
            onTap: isSending ? null : onSend,
            child: Container(
              width: context.responsive.sp(44),
              height: context.responsive.sp(44),
              decoration: BoxDecoration(
                color: isSending
                    ? Colors.white12
                    : const Color(0xFFB062FF),
                shape: BoxShape.circle,
              ),
              child: isSending
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: context.responsive.sp(20),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}