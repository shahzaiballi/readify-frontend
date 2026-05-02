// lib/presentation/community/pages/community_page.dart

// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../controllers/community_controller.dart';
import '../widgets/community_card.dart';
import '../widgets/buddy_suggestion_banner.dart';
import 'create_community_page.dart';
import '../../../domain/entities/community_entity.dart';

class CommunityPage extends ConsumerStatefulWidget {
  const CommunityPage({super.key});

  @override
  ConsumerState<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends ConsumerState<CommunityPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      ref.read(communityTabProvider.notifier).state = _tabController.index;
    });
    _searchController.addListener(() {
      ref.read(communitySearchProvider.notifier).state =
          _searchController.text;
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
    final tab = ref.watch(communityTabProvider);
    final type = tab == 0 ? 'general' : 'book';
    final publicAsync = ref.watch(publicCommunitiesProvider(type));
    final myAsync = ref.watch(myCommunitiesProvider);
    final buddyAsync = ref.watch(buddySuggestionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.responsive.wp(20),
                context.responsive.sp(20),
                context.responsive.wp(12),
                0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Community',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: context.responsive.sp(26),
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Find your reading tribe',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: context.responsive.sp(13),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _IconBtn(
                        icon: _showSearch ? Icons.close : Icons.search,
                        onTap: () =>
                            setState(() => _showSearch = !_showSearch),
                      ),
                      SizedBox(width: context.responsive.wp(8)),
                      _CreateBtn(
                        onTap: () => _showCreateModal(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: context.responsive.sp(16)),

            // ── Search bar ──────────────────────────────────────────────────
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: _showSearch
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsive.wp(20),
                ),
                child: Container(
                  height: context.responsive.sp(44),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A223B),
                    borderRadius:
                        BorderRadius.circular(context.responsive.sp(14)),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.responsive.sp(14),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search communities…',
                      hintStyle: TextStyle(
                        color: Colors.white38,
                        fontSize: context.responsive.sp(14),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: const Color(0xFFB062FF),
                        size: context.responsive.sp(18),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: context.responsive.sp(12),
                      ),
                    ),
                  ),
                ),
              ),
              secondChild: const SizedBox.shrink(),
            ),

            if (_showSearch) SizedBox(height: context.responsive.sp(12)),

            // ── Tabs ────────────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: context.responsive.wp(20)),
              child: _CommunityTabBar(controller: _tabController),
            ),

            SizedBox(height: context.responsive.sp(16)),

            // ── Content ─────────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _CommunityFeedTab(
                    publicAsync: publicAsync,
                    myAsync: myAsync,
                    buddyAsync: buddyAsync,
                    type: 'general',
                  ),
                  _CommunityFeedTab(
                    publicAsync: publicAsync,
                    myAsync: myAsync,
                    buddyAsync: buddyAsync,
                    type: 'book',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
        border: Border.all(color: Colors.white.withOpacity(0.06)),
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

// ── Feed Tab ──────────────────────────────────────────────────────────────────

class _CommunityFeedTab extends ConsumerWidget {
  final AsyncValue<List<CommunityEntity>> publicAsync;
  final AsyncValue<List<CommunityEntity>> myAsync;
  final AsyncValue<List<CommunityEntity>> buddyAsync;
  final String type;

  const _CommunityFeedTab({
    required this.publicAsync,
    required this.myAsync,
    required this.buddyAsync,
    required this.type,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── My Communities ─────────────────────
        SliverToBoxAdapter(
          child: myAsync.when(
            data: (all) {
              final myFiltered = all
                  .where((c) => c.communityType == type)
                  .toList();

              if (myFiltered.isEmpty) return const SizedBox.shrink();

              return _Section(
                title: 'My Communities',
                subtitle: 'Groups you\'ve joined',
                children: myFiltered
                    .map((c) => CommunityCard(
                          community: c,
                          compact: false,
                        ))
                    .toList(),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),

        // ── Buddy Suggestions ─────────────────────
        if (type == 'book')
          SliverToBoxAdapter(
            child: buddyAsync.when(
              data: (suggestions) {
                if (suggestions.isEmpty) {
                  return const SizedBox.shrink();
                }

                return _Section(
                  title: 'Buddy Groups',
                  subtitle: 'Groups for books you\'re reading',
                  children: [
                    BuddySuggestionBanner(
                      suggestions: suggestions,
                    ),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

        // ── Public Communities ─────────────────────
        publicAsync.when(
          data: (communities) {
            if (communities.isEmpty) {
              return const SliverToBoxAdapter(
                child: Center(
                  child: Text(
                    'No communities yet',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              );
            }

            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => CommunityCard(
                  community: communities[i],
                  compact: false,
                ),
                childCount: communities.length,
              ),
            );
          },
          loading: () => const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SliverToBoxAdapter(
            child: Center(
              child: Text(
                'Error loading communities',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Section wrapper ───────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.responsive.wp(20),
            context.responsive.sp(8),
            context.responsive.wp(20),
            context.responsive.sp(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: context.responsive.sp(18),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: context.responsive.sp(2)),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: context.responsive.sp(11),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.responsive.sp(8)),
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: context.responsive.wp(20)),
          child: Column(children: children),
        ),
        SizedBox(height: context.responsive.sp(8)),
        Divider(color: Colors.white.withOpacity(0.06)),
        SizedBox(height: context.responsive.sp(8)),
      ],
    );
  }
}

// ── Icon button ───────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(context.responsive.sp(10)),
        decoration: BoxDecoration(
          color: const Color(0xFF1A223B),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(icon,
            color: Colors.white70, size: context.responsive.sp(18)),
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
              color: const Color(0xFFB062FF).withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add,
                color: Colors.white, size: context.responsive.sp(16)),
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