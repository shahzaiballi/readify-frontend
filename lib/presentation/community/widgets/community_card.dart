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
    return InkWell(
      onTap: () => context.push('/community/${community.id}'),
      borderRadius: BorderRadius.circular(context.responsive.sp(16)),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.responsive.wp(4),
          vertical: context.responsive.sp(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _CommunityAvatar(community: community),
            SizedBox(width: context.responsive.wp(14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name row
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                community.name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: context.responsive.sp(15),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (community.privacy == 'private') ...[
                              SizedBox(width: context.responsive.wp(4)),
                              Icon(Icons.lock_rounded,
                                  color: Colors.white38,
                                  size: context.responsive.sp(12)),
                            ],
                            if (community.isAdmin) ...[
                              SizedBox(width: context.responsive.wp(4)),
                              Icon(Icons.shield_rounded,
                                  color: const Color(0xFFFFD700),
                                  size: context.responsive.sp(12)),
                            ],
                          ],
                        ),
                      ),
                      if (community.lastMessage != null)
                        Text(
                          community.lastMessage!.timeLabel,
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: context.responsive.sp(11),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: context.responsive.sp(3)),
                  // Subtitle row
                  Row(
                    children: [
                      Expanded(child: _buildPreview(context)),
                      if (!community.isMember)
                        _JoinBadge(),
                      if (community.isMember)
                        _MemberDot(hasActivity: community.lastMessage != null),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    if (community.bookTitle != null) {
      return Row(
        children: [
          Icon(Icons.menu_book_rounded,
              color: const Color(0xFFB062FF), size: context.responsive.sp(11)),
          SizedBox(width: context.responsive.wp(3)),
          Flexible(
            child: Text(
              community.bookTitle!,
              style: TextStyle(
                color: const Color(0xFFB062FF),
                fontSize: context.responsive.sp(12),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }
    final preview = community.lastMessage != null
        ? '${community.lastMessage!.senderName}: ${community.lastMessage!.content}'
        : community.description.isNotEmpty
            ? community.description
            : 'Tap to view';
    return Text(
      preview,
      style: TextStyle(
        color: Colors.white38,
        fontSize: context.responsive.sp(12),
        height: 1.3,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// ── Circle avatar with emoji or image ─────────────────────────────────────────

class _CommunityAvatar extends StatelessWidget {
  final CommunityEntity community;
  const _CommunityAvatar({required this.community});

  @override
  Widget build(BuildContext context) {
    final size = context.responsive.sp(54);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF2D1B52), Color(0xFF1A2340)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.5,
        ),
      ),
      child: community.coverImageUrl != null
          ? ClipOval(
              child: Image.network(
                community.coverImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _emoji(context, size),
              ),
            )
          : _emoji(context, size),
    );
  }

  Widget _emoji(BuildContext context, double size) {
    return Center(
      child: Text(
        community.coverEmoji,
        style: TextStyle(fontSize: size * 0.44),
      ),
    );
  }
}

// ── Join badge for undiscovered communities ────────────────────────────────────

class _JoinBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.responsive.wp(8),
        vertical: context.responsive.sp(3),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFB062FF).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(context.responsive.sp(20)),
        border: Border.all(color: const Color(0xFFB062FF).withValues(alpha: 0.4)),
      ),
      child: Text(
        'Join',
        style: TextStyle(
          color: const Color(0xFFB062FF),
          fontSize: context.responsive.sp(11),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ── Active dot for joined communities ─────────────────────────────────────────

class _MemberDot extends StatelessWidget {
  final bool hasActivity;
  const _MemberDot({required this.hasActivity});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.people_outline_rounded,
            color: Colors.white24, size: context.responsive.sp(12)),
      ],
    );
  }
}