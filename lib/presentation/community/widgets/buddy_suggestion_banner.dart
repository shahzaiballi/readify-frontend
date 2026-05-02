// lib/presentation/community/widgets/buddy_suggestion_banner.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../domain/entities/community_entity.dart';

class BuddySuggestionBanner extends StatelessWidget {
  final List<CommunityEntity> suggestions;

  const BuddySuggestionBanner({super.key, required this.suggestions});

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: context.responsive.sp(130),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final community = suggestions[index];
          return _BuddyCard(community: community);
        },
      ),
    );
  }
}

class _BuddyCard extends StatelessWidget {
  final CommunityEntity community;
  const _BuddyCard({required this.community});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/community/${community.id}'),
      child: Container(
        width: context.responsive.wp(160),
        margin: EdgeInsets.only(right: context.responsive.wp(12)),
        padding: EdgeInsets.all(context.responsive.sp(14)),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2D1B52), Color(0xFF1A2340)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(context.responsive.sp(14)),
          border: Border.all(color: const Color(0xFFB062FF).withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: context.responsive.sp(36),
                  height: context.responsive.sp(36),
                  decoration: BoxDecoration(
                    color: const Color(0xFF381A5D),
                    borderRadius: BorderRadius.circular(context.responsive.sp(8)),
                  ),
                  child: Center(
                    child: Text(
                      community.coverEmoji,
                      style: TextStyle(fontSize: context.responsive.sp(18)),
                    ),
                  ),
                ),
                SizedBox(width: context.responsive.wp(8)),
                Expanded(
                  child: Text(
                    community.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.responsive.sp(12),
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Icon(
                  Icons.people_outline,
                  color: Colors.white38,
                  size: context.responsive.sp(12),
                ),
                SizedBox(width: context.responsive.wp(4)),
                Text(
                  '${community.memberCount} members',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: context.responsive.sp(10),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.responsive.sp(8)),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: context.responsive.sp(6)),
              decoration: BoxDecoration(
                color: const Color(0xFFB062FF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(context.responsive.sp(8)),
              ),
              child: Text(
                'Join Group',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFFB062FF),
                  fontSize: context.responsive.sp(11),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}