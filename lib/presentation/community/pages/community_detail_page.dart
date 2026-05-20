// lib/presentation/community/pages/community_detail_page.dart

// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/responsive_utils.dart';
import '../controllers/community_controller.dart';
import '../../../domain/entities/community_entity.dart';

// ── Main page ─────────────────────────────────────────────────────────────────

class CommunityDetailPage extends ConsumerWidget {
  final String communityId;
  const CommunityDetailPage({super.key, required this.communityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communityAsync = ref.watch(communityDetailProvider(communityId));
    final membersAsync = ref.watch(communityMembersProvider(communityId));

    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      body: communityAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator.adaptive(
            valueColor: AlwaysStoppedAnimation(Color(0xFFB062FF)),
          ),
        ),
        error: (_, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Colors.white30, size: 48),
              const SizedBox(height: 12),
              Text('Could not load community',
                  style: TextStyle(
                      color: Colors.white38,
                      fontSize: context.responsive.sp(14))),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Go back',
                    style: TextStyle(color: Color(0xFFB062FF))),
              ),
            ],
          ),
        ),
        data: (community) => _DetailBody(
          communityId: communityId,
          community: community,
          membersAsync: membersAsync,
        ),
      ),
    );
  }
}

// ── Full body ─────────────────────────────────────────────────────────────────

class _DetailBody extends ConsumerWidget {
  final String communityId;
  final CommunityEntity community;
  final AsyncValue<List<CommunityMemberEntity>> membersAsync;

  const _DetailBody({
    required this.communityId,
    required this.community,
    required this.membersAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionCtrl = ref.read(communityActionProvider.notifier);
    final inviteToken = community.inviteToken;
    final inviteLink = inviteToken != null
        ? 'https://readify.app/community/join/$inviteToken'
        : null;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Hero header ────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _HeroHeader(
            community: community,
            onBack: () => context.pop(),
          ),
        ),

        // ── Description ────────────────────────────────────────────────────
        if (community.description.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                context.responsive.wp(20),
                context.responsive.sp(16),
                context.responsive.wp(20),
                0,
              ),
              child: Container(
                padding: EdgeInsets.all(context.responsive.sp(14)),
                decoration: BoxDecoration(
                  color: const Color(0xFF141B2E),
                  borderRadius: BorderRadius.circular(context.responsive.sp(14)),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Text(
                  community.description,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: context.responsive.sp(13),
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),

        // ── Primary CTA buttons ─────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              context.responsive.wp(20),
              context.responsive.sp(18),
              context.responsive.wp(20),
              0,
            ),
            child: Column(
              children: [
                // Open Chat (shown for members)
                if (community.isMember)
                  _PrimaryButton(
                    icon: Icons.chat_rounded,
                    label: 'Open Chat',
                    gradient: const LinearGradient(
                        colors: [Color(0xFF9B4DFF), Color(0xFFB062FF)]),
                    onTap: () =>
                        context.push('/community/$communityId/chat'),
                  ),

                if (community.isMember)
                  SizedBox(height: context.responsive.sp(10)),

                // Join / Leave
                _PrimaryButton(
                  icon: community.isMember
                      ? Icons.exit_to_app_rounded
                      : Icons.group_add_rounded,
                  label: community.isMember
                      ? 'Leave Community'
                      : 'Join Community',
                  gradient: community.isMember
                      ? const LinearGradient(
                          colors: [Color(0xFF3A1A1A), Color(0xFF4A1A1A)])
                      : const LinearGradient(
                          colors: [Color(0xFF1A2340), Color(0xFF222E50)]),
                  borderColor: community.isMember
                      ? Colors.redAccent.withValues(alpha: 0.4)
                      : const Color(0xFFB062FF).withValues(alpha: 0.3),
                  textColor: community.isMember
                      ? Colors.redAccent
                      : const Color(0xFFB062FF),
                  onTap: () async {
                    if (community.isMember) {
                      await actionCtrl.leaveCommunity(communityId);
                    } else {
                      await actionCtrl.joinCommunity(communityId);
                    }
                  },
                ),

                // Invite link (private + admin)
                if (inviteLink != null && community.isAdmin) ...[
                  SizedBox(height: context.responsive.sp(10)),
                  _InviteLinkRow(inviteLink: inviteLink),
                ],
              ],
            ),
          ),
        ),

        // ── Members section ─────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              context.responsive.wp(20),
              context.responsive.sp(22),
              context.responsive.wp(20),
              context.responsive.sp(8),
            ),
            child: Row(
              children: [
                Text(
                  'Members',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.responsive.sp(15),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: context.responsive.wp(8)),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.responsive.wp(8),
                    vertical: context.responsive.sp(2),
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB062FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(context.responsive.sp(10)),
                  ),
                  child: Text(
                    '${community.memberCount}',
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
        ),

        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: context.responsive.wp(20)),
          sliver: membersAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator.adaptive(
                    valueColor: AlwaysStoppedAnimation(Color(0xFFB062FF)),
                  ),
                ),
              ),
            ),
            error: (_, _) => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Could not load members',
                    style: TextStyle(color: Colors.white38)),
              ),
            ),
            data: (members) => SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: context.responsive.sp(14),
                crossAxisSpacing: context.responsive.sp(10),
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _MemberTile(member: members[i]),
                childCount: members.length > 12 ? 12 : members.length,
              ),
            ),
          ),
        ),

        // ── Admin controls ──────────────────────────────────────────────────
        if (community.isAdmin)
          SliverToBoxAdapter(
            child: _AdminControls(
              community: community,
              communityId: communityId,
            ),
          ),

        // Bottom padding
        SliverToBoxAdapter(
          child: SizedBox(height: context.responsive.sp(48)),
        ),
      ],
    );
  }
}

// ── Hero header ───────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final CommunityEntity community;
  final VoidCallback onBack;
  const _HeroHeader({required this.community, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      height: context.responsive.sp(220) + topPad,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A0A38), Color(0xFF0F1626)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // Back button
          Positioned(
            top: topPad + context.responsive.sp(8),
            left: context.responsive.wp(8),
            child: IconButton(
              onPressed: onBack,
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white70,
                size: context.responsive.sp(20),
              ),
            ),
          ),

          // Privacy badge
          Positioned(
            top: topPad + context.responsive.sp(16),
            right: context.responsive.wp(16),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.responsive.wp(10),
                vertical: context.responsive.sp(4),
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(context.responsive.sp(20)),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    community.privacy == 'private'
                        ? Icons.lock_rounded
                        : Icons.public_rounded,
                    color: Colors.white60,
                    size: context.responsive.sp(11),
                  ),
                  SizedBox(width: context.responsive.wp(4)),
                  Text(
                    community.privacy == 'private' ? 'Private' : 'Public',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: context.responsive.sp(11),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Center content
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: topPad * 0.5),
                // Cover emoji / image
                Container(
                  width: context.responsive.sp(76),
                  height: context.responsive.sp(76),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3D1A6E), Color(0xFF1A2340)],
                    ),
                    border: Border.all(
                      color: const Color(0xFFB062FF).withValues(alpha: 0.5),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFB062FF).withValues(alpha: 0.25),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: community.coverImageUrl != null
                      ? ClipOval(
                          child: Image.network(
                            community.coverImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Center(
                              child: Text(community.coverEmoji,
                                  style: TextStyle(
                                      fontSize: context.responsive.sp(34))),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(community.coverEmoji,
                              style: TextStyle(
                                  fontSize: context.responsive.sp(34)))),
                ),
                SizedBox(height: context.responsive.sp(12)),
                Text(
                  community.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.responsive.sp(20),
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: context.responsive.sp(6)),
                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StatChip(
                      icon: Icons.people_rounded,
                      label: '${community.memberCount} members',
                    ),
                    SizedBox(width: context.responsive.wp(10)),
                    _StatChip(
                      icon: community.communityType == 'book'
                          ? Icons.menu_book_rounded
                          : Icons.chat_bubble_outline_rounded,
                      label: community.communityType == 'book'
                          ? 'Book group'
                          : 'General',
                    ),
                    if (community.isAdmin) ...[
                      SizedBox(width: context.responsive.wp(10)),
                      _StatChip(
                        icon: Icons.shield_rounded,
                        label: 'Admin',
                        color: const Color(0xFFFFD700),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _StatChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white54;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: c, size: context.responsive.sp(12)),
        SizedBox(width: context.responsive.wp(4)),
        Text(label,
            style:
                TextStyle(color: c, fontSize: context.responsive.sp(11))),
      ],
    );
  }
}

// ── Primary action button ─────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Gradient gradient;
  final Color? borderColor;
  final Color? textColor;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
    this.borderColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: context.responsive.sp(14)),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(context.responsive.sp(14)),
          border: borderColor != null
              ? Border.all(color: borderColor!)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: textColor ?? Colors.white,
                size: context.responsive.sp(18)),
            SizedBox(width: context.responsive.wp(8)),
            Text(
              label,
              style: TextStyle(
                color: textColor ?? Colors.white,
                fontSize: context.responsive.sp(14),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Invite link row ───────────────────────────────────────────────────────────

class _InviteLinkRow extends StatelessWidget {
  final String inviteLink;
  const _InviteLinkRow({required this.inviteLink});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.responsive.wp(14),
        vertical: context.responsive.sp(12),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF141B2E),
        borderRadius: BorderRadius.circular(context.responsive.sp(14)),
        border: Border.all(
            color: const Color(0xFFB062FF).withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.link_rounded,
              color: const Color(0xFFB062FF),
              size: context.responsive.sp(16)),
          SizedBox(width: context.responsive.wp(10)),
          Expanded(
            child: Text(
              inviteLink,
              style: TextStyle(
                color: Colors.white38,
                fontSize: context.responsive.sp(11),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: inviteLink));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Invite link copied!'),
                  backgroundColor: Color(0xFFB062FF),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.responsive.wp(10),
                vertical: context.responsive.sp(5),
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFB062FF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(context.responsive.sp(8)),
                border: Border.all(
                    color: const Color(0xFFB062FF).withValues(alpha: 0.3)),
              ),
              child: Text(
                'Copy',
                style: TextStyle(
                  color: const Color(0xFFB062FF),
                  fontSize: context.responsive.sp(11),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Member grid tile ──────────────────────────────────────────────────────────

class _MemberTile extends StatelessWidget {
  final CommunityMemberEntity member;
  const _MemberTile({required this.member});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: context.responsive.sp(24),
              backgroundImage: member.avatarUrl.isNotEmpty
                  ? NetworkImage(member.avatarUrl)
                  : null,
              backgroundColor: const Color(0xFF2D1B52),
              child: member.avatarUrl.isEmpty
                  ? Text(
                      member.name.isNotEmpty
                          ? member.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: context.responsive.sp(14),
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            if (member.isAdmin)
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  padding: EdgeInsets.all(context.responsive.sp(2)),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1020),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFF0B1020), width: 1),
                  ),
                  child: Icon(
                    Icons.shield_rounded,
                    color: const Color(0xFFFFD700),
                    size: context.responsive.sp(11),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: context.responsive.sp(5)),
        Text(
          member.name.split(' ').first,
          style: TextStyle(
            color: Colors.white54,
            fontSize: context.responsive.sp(10),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Admin controls ────────────────────────────────────────────────────────────

class _AdminControls extends ConsumerWidget {
  final CommunityEntity community;
  final String communityId;
  const _AdminControls({required this.community, required this.communityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.responsive.wp(20),
        context.responsive.sp(24),
        context.responsive.wp(20),
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_rounded,
                  color: const Color(0xFFFFD700),
                  size: context.responsive.sp(14)),
              SizedBox(width: context.responsive.wp(6)),
              Text(
                'Admin Controls',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: context.responsive.sp(14),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: context.responsive.sp(12)),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF141B2E),
              borderRadius: BorderRadius.circular(context.responsive.sp(14)),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Column(
              children: [
                _AdminTile(
                  icon: Icons.edit_rounded,
                  label: 'Edit community info',
                  onTap: () => _showEditSheet(context, ref),
                ),
                Divider(
                    color: Colors.white.withValues(alpha: 0.06), height: 1),
                _AdminTile(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete community',
                  color: Colors.redAccent,
                  onTap: () => _confirmDelete(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController(text: community.name);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF141B2E),
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Edit Community',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Community name',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF1A223B),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await ref
                          .read(communityActionProvider.notifier)
                          .updateCommunity(
                            communityId,
                            name: nameCtrl.text.trim(),
                          );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB062FF),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save Changes',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF141B2E),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Community',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${community.name}"? This cannot be undone.',
          style: const TextStyle(color: Colors.white54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(communityActionProvider.notifier)
                  .deleteCommunity(communityId);
              if (context.mounted) context.go('/community');
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

// ── Admin tile ────────────────────────────────────────────────────────────────

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _AdminTile({
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
      borderRadius: BorderRadius.circular(context.responsive.sp(14)),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.responsive.wp(16),
          vertical: context.responsive.sp(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: c, size: context.responsive.sp(18)),
            SizedBox(width: context.responsive.wp(12)),
            Text(label,
                style: TextStyle(
                    color: c, fontSize: context.responsive.sp(14))),
            const Spacer(),
            Icon(Icons.chevron_right_rounded,
                color: Colors.white24, size: context.responsive.sp(18)),
          ],
        ),
      ),
    );
  }
}