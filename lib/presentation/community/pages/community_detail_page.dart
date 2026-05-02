// lib/presentation/community/pages/community_detail_page.dart

// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/responsive_utils.dart';
import '../../../../domain/entities/community_entity.dart';
import '../controllers/community_controller.dart';

class CommunityDetailPage extends ConsumerWidget {
  final String communityId;

  const CommunityDetailPage({super.key, required this.communityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communityAsync = ref.watch(communityDetailProvider(communityId));
    final membersAsync = ref.watch(communityMembersProvider(communityId));
    final actionController = ref.read(communityActionProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1626),
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text('Community', style: TextStyle(color: Colors.white)),
      ),
      body: communityAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error loading community')),
        data: (community) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(context.responsive.wp(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ─────────────────────────────
                Row(
                  children: [
                    Container(
                      width: context.responsive.sp(60),
                      height: context.responsive.sp(60),
                      decoration: BoxDecoration(
                        color: const Color(0xFF381A5D),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          community.coverEmoji,
                          style: TextStyle(fontSize: context.responsive.sp(28)),
                        ),
                      ),
                    ),
                    SizedBox(width: context.responsive.wp(16)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            community.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: context.responsive.sp(18),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: context.responsive.sp(4)),
                          Text(
                            '${community.memberCount} members',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: context.responsive.sp(12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: context.responsive.sp(16)),

                // ── Description ─────────────────────────
                if (community.description.isNotEmpty)
                  Text(
                    community.description,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: context.responsive.sp(14),
                    ),
                  ),

                SizedBox(height: context.responsive.sp(20)),

                // ── Join / Leave ───────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (community.isJoined) {
                        await actionController.leaveCommunity(communityId);
                      } else {
                        await actionController.joinCommunity(communityId);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: community.isJoined
                          ? Colors.redAccent
                          : const Color(0xFFB062FF),
                      padding: EdgeInsets.symmetric(
                        vertical: context.responsive.sp(14),
                      ),
                    ),
                    child: Text(
                      community.isJoined ? 'Leave Community' : 'Join Community',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),

                SizedBox(height: context.responsive.sp(20)),

                // ── Members ────────────────────────────
                Text(
                  'Members',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.responsive.sp(16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: context.responsive.sp(10)),

                membersAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('Error loading members'),
                  data: (members) {
                    if (members.isEmpty) {
                      return const Text(
                        'No members yet',
                        style: TextStyle(color: Colors.white38),
                      );
                    }

                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: members.take(10).map((m) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: m.avatarUrl.isNotEmpty
                                  ? NetworkImage(m.avatarUrl)
                                  : null,
                              backgroundColor: const Color(0xFF381A5D),
                              child: m.avatarUrl.isEmpty
                                  ? Text(
                                      m.name[0].toUpperCase(),
                                      style: const TextStyle(color: Colors.white),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              m.name,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    );
                  },
                ),

                SizedBox(height: context.responsive.sp(30)),

                // ── Open Chat ─────────────────────────
                if (community.isJoined)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        context.push('/community/$communityId/chat');
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFB062FF)),
                        padding: EdgeInsets.symmetric(
                          vertical: context.responsive.sp(14),
                        ),
                      ),
                      child: const Text(
                        'Open Chat',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}