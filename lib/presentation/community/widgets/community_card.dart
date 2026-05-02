// lib/presentation/community/widgets/community_card.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../domain/entities/community_entity.dart';

class CommunityCard extends StatelessWidget {
  final CommunityEntity community;
  final bool compact;

  const CommunityCard({
    super.key,
    required this.community,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/community/${community.id}'),
      child: Container(
        margin: EdgeInsets.only(bottom: context.responsive.sp(12)),
        padding: EdgeInsets.all(context.responsive.sp(16)),
        decoration: BoxDecoration(
          color: const Color(0xFF1A223B),
          borderRadius: BorderRadius.circular(context.responsive.sp(16)),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            _buildAvatar(context),
            SizedBox(width: context.responsive.wp(14)),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          community.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: context.responsive.sp(14),
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (community.privacy == 'private')
                        Padding(
                          padding: EdgeInsets.only(left: context.responsive.wp(6)),
                          child: Icon(
                            Icons.lock_outline,
                            color: Colors.white38,
                            size: context.responsive.sp(13),
                          ),
                        ),
                    ],
                  ),
                  if (community.bookTitle != null) ...[
                    SizedBox(height: context.responsive.sp(2)),
                    Text(
                      community.bookTitle!,
                      style: TextStyle(
                        color: const Color(0xFFB062FF),
                        fontSize: context.responsive.sp(11),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  SizedBox(height: context.responsive.sp(6)),
                  _buildLastMessage(context),
                ],
              ),
            ),

            SizedBox(width: context.responsive.wp(8)),

            // Right side
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (community.lastMessage != null)
                  Text(
                    community.lastMessage!.timeLabel,
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: context.responsive.sp(10),
                    ),
                  ),
                SizedBox(height: context.responsive.sp(6)),
                _MemberCountBadge(count: community.memberCount),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final size = context.responsive.sp(48);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.responsive.sp(12)),
        gradient: const LinearGradient(
          colors: [Color(0xFF381A5D), Color(0xFF1A2340)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: community.coverImageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(context.responsive.sp(12)),
              child: Image.network(
                community.coverImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _emojiPlaceholder(context, size),
              ),
            )
          : _emojiPlaceholder(context, size),
    );
  }

  Widget _emojiPlaceholder(BuildContext context, double size) {
    return Center(
      child: Text(
        community.coverEmoji,
        style: TextStyle(fontSize: size * 0.45),
      ),
    );
  }

  Widget _buildLastMessage(BuildContext context) {
    if (community.lastMessage == null) {
      return Text(
        community.description.isNotEmpty
            ? community.description
            : 'No messages yet',
        style: TextStyle(
          color: Colors.white38,
          fontSize: context.responsive.sp(12),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    final msg = community.lastMessage!;
    return Text(
      '${msg.senderName}: ${msg.content}',
      style: TextStyle(
        color: Colors.white54,
        fontSize: context.responsive.sp(12),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _MemberCountBadge extends StatelessWidget {
  final int count;
  const _MemberCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final label = count >= 1000
        ? '${(count / 1000).toStringAsFixed(1)}K'
        : '$count';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.responsive.wp(7),
        vertical: context.responsive.sp(3),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFB062FF).withOpacity(0.15),
        borderRadius: BorderRadius.circular(context.responsive.sp(8)),
        border: Border.all(color: const Color(0xFFB062FF).withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_outline,
            color: const Color(0xFFB062FF),
            size: context.responsive.sp(10),
          ),
          SizedBox(width: context.responsive.wp(3)),
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFFB062FF),
              fontSize: context.responsive.sp(10),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}