// lib/presentation/community/pages/community_page.dart

// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../controllers/community_controller.dart';
import '../widgets/community_card.dart';
import 'create_community_page.dart';
import '../../../domain/entities/community_entity.dart';

// ── Main Page ─────────────────────────────────────────────────────────────────

class CommunityPage extends ConsumerStatefulWidget {
  const CommunityPage({super.key});

  @override
  ConsumerState<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends ConsumerState<CommunityPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(communityTabProvider.notifier).state = _tabController.index;
      }
    });
    _searchController.addListener(() {
      ref.read(communitySearchProvider.notifier).state = _searchController.text;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            SizedBox(height: context.responsive.sp(10)),
            _buildSearchBar(context),
            SizedBox(height: context.responsive.sp(10)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.responsive.wp(20)),
              child: _CommunityTabBar(controller: _tabController),
            ),
            SizedBox(height: context.responsive.sp(6)),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _CommunityTabContent(type: 'general'),
                  _CommunityTabContent(type: 'book'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.responsive.wp(20),
        context.responsive.sp(18),
        context.responsive.wp(16),
        0,
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Community',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: context.responsive.sp(24),
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Find your reading tribe',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: context.responsive.sp(12),
                ),
              ),
            ],
          ),
          const Spacer(),
          _CreateBtn(onTap: () => _showCreateModal(context)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.responsive.wp(20)),
      child: Container(
        height: context.responsive.sp(42),
        decoration: BoxDecoration(
          color: const Color(0xFF141A2E),
          borderRadius: BorderRadius.circular(context.responsive.sp(22)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: TextField(
          controller: _searchController,
          style: TextStyle(color: Colors.white, fontSize: context.responsive.sp(14)),
          decoration: InputDecoration(
            hintText: 'Search communities…',
            hintStyle: TextStyle(
              color: Colors.white30,
              fontSize: context.responsive.sp(13),
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Colors.white30,
              size: context.responsive.sp(18),
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: context.responsive.sp(12)),
          ),
        ),
      ),
    );
  }

  void _showCreateModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => const CreateCommunityPage(),
    );
  }
}

// ── Tab Bar ───────────────────────────────────────────────────────────────────

class _CommunityTabBar extends StatelessWidget {
  final TabController controller;
  const _CommunityTabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.responsive.sp(42),
      decoration: BoxDecoration(
        color: const Color(0xFF161B2E),
        borderRadius: BorderRadius.circular(context.responsive.sp(12)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: const Color(0xFFB062FF),
          borderRadius: BorderRadius.circular(context.responsive.sp(10)),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white38,
        labelStyle: TextStyle(
          fontSize: context.responsive.sp(13),
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: context.responsive.sp(13),
          fontWeight: FontWeight.normal,
        ),
        padding: EdgeInsets.all(context.responsive.sp(4)),
        tabs: const [
          Tab(text: 'General'),
          Tab(text: 'Book Groups'),
        ],
      ),
    );
  }
}

// ── Combined tab content: My Groups strip + Discover list ─────────────────────

class _CommunityTabContent extends ConsumerWidget {
  final String type;
  const _CommunityTabContent({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myAsync = ref.watch(myCommunitiesProvider);
    final publicAsync = ref.watch(publicCommunitiesProvider(type));

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // My Groups stories strip
        SliverToBoxAdapter(
          child: myAsync.maybeWhen(
            data: (all) {
              final mine = all.where((c) => c.communityType == type).toList();
              if (mine.isEmpty) return const SizedBox.shrink();
              return _MyGroupsStrip(communities: mine);
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ),

        // Discover heading
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              context.responsive.wp(20),
              context.responsive.sp(12),
              context.responsive.wp(20),
              context.responsive.sp(4),
            ),
            child: Row(
              children: [
                Text(
                  'Discover',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.responsive.sp(15),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: context.responsive.wp(6)),
                publicAsync.maybeWhen(
                  data: (list) => Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.responsive.wp(7),
                      vertical: context.responsive.sp(2),
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB062FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(context.responsive.sp(10)),
                    ),
                    child: Text(
                      '${list.length}',
                      style: TextStyle(
                        color: const Color(0xFFB062FF),
                        fontSize: context.responsive.sp(11),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),

        // Community list
        publicAsync.when(
          data: (communities) {
            if (communities.isEmpty) {
              return SliverToBoxAdapter(
                child: _EmptyState(
                  icon: Icons.public_rounded,
                  title: 'No communities yet',
                  subtitle: 'Be the first to create one!',
                ),
              );
            }
            return SliverPadding(
              padding: EdgeInsets.fromLTRB(
                context.responsive.wp(16),
                context.responsive.sp(4),
                context.responsive.wp(16),
                context.responsive.sp(32),
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => Column(
                    children: [
                      CommunityCard(community: communities[i]),
                      Divider(
                        color: Colors.white.withValues(alpha: 0.05),
                        height: 1,
                        indent: context.responsive.sp(70),
                      ),
                    ],
                  ),
                  childCount: communities.length,
                ),
              ),
            );
          },
          loading: () => const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator.adaptive(
                  valueColor: AlwaysStoppedAnimation(Color(0xFFB062FF)),
                ),
              ),
            ),
          ),
          error: (_, _) => SliverToBoxAdapter(
            child: _EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Could not load communities',
              subtitle: 'Pull down to retry',
            ),
          ),
        ),
      ],
    );
  }
}

// ── My Groups horizontal stories strip ────────────────────────────────────────

class _MyGroupsStrip extends StatelessWidget {
  final List<CommunityEntity> communities;
  const _MyGroupsStrip({required this.communities});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.responsive.wp(20),
            context.responsive.sp(4),
            context.responsive.wp(20),
            context.responsive.sp(10),
          ),
          child: Row(
            children: [
              Text(
                'My Groups',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: context.responsive.sp(14),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: context.responsive.wp(6)),
              Container(
                width: context.responsive.sp(18),
                height: context.responsive.sp(18),
                decoration: const BoxDecoration(
                  color: Color(0xFFB062FF),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${communities.length}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.responsive.sp(10),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: context.responsive.sp(88),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: context.responsive.wp(16)),
            itemCount: communities.length,
            itemBuilder: (ctx, i) => _MyGroupItem(community: communities[i]),
          ),
        ),
        SizedBox(height: context.responsive.sp(4)),
        Divider(color: Colors.white.withValues(alpha: 0.07), height: 1),
        SizedBox(height: context.responsive.sp(4)),
      ],
    );
  }
}

// ── Single story item in the My Groups strip ───────────────────────────────────

class _MyGroupItem extends StatelessWidget {
  final CommunityEntity community;
  const _MyGroupItem({required this.community});

  @override
  Widget build(BuildContext context) {
    final avatarSize = context.responsive.sp(52);
    final hasActivity = community.lastMessage != null;

    return GestureDetector(
      onTap: () => context.push('/community/${community.id}/chat'),
      child: SizedBox(
        width: context.responsive.sp(70),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2D1B52), Color(0xFF1A2340)],
                    ),
                    border: Border.all(
                      color: hasActivity
                          ? const Color(0xFFB062FF)
                          : Colors.white.withValues(alpha: 0.12),
                      width: hasActivity ? 2.5 : 1.5,
                    ),
                  ),
                  child: community.coverImageUrl != null
                      ? ClipOval(
                          child: Image.network(
                            community.coverImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Center(
                              child: Text(community.coverEmoji,
                                  style: TextStyle(fontSize: avatarSize * 0.42)),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(community.coverEmoji,
                              style: TextStyle(fontSize: avatarSize * 0.42)),
                        ),
                ),
                if (community.privacy == 'private')
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(context.responsive.sp(2)),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B1020),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF0B1020), width: 1),
                      ),
                      child: Icon(Icons.lock_rounded,
                          size: context.responsive.sp(10),
                          color: Colors.white54),
                    ),
                  ),
              ],
            ),
            SizedBox(height: context.responsive.sp(5)),
            Text(
              community.name,
              style: TextStyle(
                color: Colors.white60,
                fontSize: context.responsive.sp(10),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.responsive.sp(40)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(context.responsive.sp(24)),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white24, size: context.responsive.sp(40)),
            ),
            SizedBox(height: context.responsive.sp(16)),
            Text(
              title,
              style: TextStyle(
                color: Colors.white70,
                fontSize: context.responsive.sp(15),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.responsive.sp(8)),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white30,
                fontSize: context.responsive.sp(12),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Create button ─────────────────────────────────────────────────────────────

class _CreateBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _CreateBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.responsive.wp(14),
          vertical: context.responsive.sp(9),
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFB062FF), Color(0xFF7B3FF2)],
          ),
          borderRadius: BorderRadius.circular(context.responsive.sp(12)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB062FF).withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: Colors.white, size: context.responsive.sp(16)),
            SizedBox(width: context.responsive.wp(4)),
            Text(
              'New',
              style: TextStyle(
                color: Colors.white,
                fontSize: context.responsive.sp(13),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}