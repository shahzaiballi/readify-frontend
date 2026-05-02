// lib/presentation/community/pages/community_page.dart

// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      if (!_tabController.indexIsChanging) {
        ref.read(communityTabProvider.notifier).state = _tabController.index;
        // Reset sub-filter when switching main tab
        ref.read(communitySubFilterProvider.notifier).state = 0;
      }
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
    final subFilter = ref.watch(communitySubFilterProvider);
    final type = tab == 0 ? 'general' : 'book';

    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
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

            // ── Search bar ───────────────────────────────────────────────────
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

            // ── Main Tabs (General / Book Groups) ────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: context.responsive.wp(20)),
              child: _CommunityTabBar(controller: _tabController),
            ),

            SizedBox(height: context.responsive.sp(12)),

            // ── Sub-filter chips (Public / My Communities / Private) ──────────
            _SubFilterBar(
              selected: subFilter,
              onSelect: (i) {
                ref.read(communitySubFilterProvider.notifier).state = i;
              },
            ),

            SizedBox(height: context.responsive.sp(8)),

            // ── Content ──────────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _CommunityFeedTab(type: 'general'),
                  _CommunityFeedTab(type: 'book'),
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
      isDismissible: false, // prevent accidental dismiss while loading
      builder: (_) => const CreateCommunityPage(),
    );
  }
}

// ── Sub-filter bar ────────────────────────────────────────────────────────────

class _SubFilterBar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;

  const _SubFilterBar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final filters = [
      (Icons.public_rounded, 'Public'),
      (Icons.groups_rounded, 'My Communities'),
      (Icons.lock_outline_rounded, 'Private'),
    ];

    return SizedBox(
      height: context.responsive.sp(34),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: context.responsive.wp(20)),
        separatorBuilder: (_, __) => SizedBox(width: context.responsive.wp(8)),
        itemCount: filters.length,
        itemBuilder: (context, i) {
          final isSelected = selected == i;
          return GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: context.responsive.wp(12),
                vertical: context.responsive.sp(6),
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFB062FF).withOpacity(0.18)
                    : const Color(0xFF1A223B),
                borderRadius: BorderRadius.circular(context.responsive.sp(20)),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFB062FF).withOpacity(0.6)
                      : Colors.white12,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filters[i].$1,
                    color: isSelected
                        ? const Color(0xFFB062FF)
                        : Colors.white38,
                    size: context.responsive.sp(13),
                  ),
                  SizedBox(width: context.responsive.wp(5)),
                  Text(
                    filters[i].$2,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFFB062FF)
                          : Colors.white38,
                      fontSize: context.responsive.sp(12),
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
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
  final String type;

  const _CommunityFeedTab({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subFilter = ref.watch(communitySubFilterProvider);
    final buddyAsync = ref.watch(buddySuggestionsProvider);

    // 0 = Public, 1 = My Communities, 2 = Private
    switch (subFilter) {
      case 1:
        return _MyCommunitiesView(type: type);
      case 2:
        return _PrivateCommunitiesView();
      default:
        return _PublicCommunitiesView(type: type, buddyAsync: buddyAsync);
    }
  }
}

// ── Public View ───────────────────────────────────────────────────────────────

class _PublicCommunitiesView extends ConsumerWidget {
  final String type;
  final AsyncValue<List<CommunityEntity>> buddyAsync;

  const _PublicCommunitiesView({required this.type, required this.buddyAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final publicAsync = ref.watch(publicCommunitiesProvider(type));

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Buddy suggestions (book tab only)
        if (type == 'book')
          SliverToBoxAdapter(
            child: buddyAsync.when(
              data: (suggestions) {
                if (suggestions.isEmpty) return const SizedBox.shrink();
                return _Section(
                  title: 'Buddy Groups',
                  subtitle: 'Groups for books you\'re reading',
                  children: [BuddySuggestionBanner(suggestions: suggestions)],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

        // Discover header
        SliverToBoxAdapter(
          child: Padding(
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
                  'Discover',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.responsive.sp(16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Public communities anyone can join',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: context.responsive.sp(11),
                  ),
                ),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(child: SizedBox(height: context.responsive.sp(8))),

        publicAsync.when(
          data: (communities) {
            if (communities.isEmpty) {
              return SliverToBoxAdapter(
                child: _EmptyState(
                  icon: Icons.public_rounded,
                  title: 'No public communities yet',
                  subtitle: 'Be the first to create one!',
                ),
              );
            }
            return SliverPadding(
              padding: EdgeInsets.symmetric(
                  horizontal: context.responsive.wp(20)),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => CommunityCard(
                    community: communities[i],
                    compact: false,
                  ),
                  childCount: communities.length,
                ),
              ),
            );
          },
          loading: () => const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator.adaptive(
                  valueColor:
                      AlwaysStoppedAnimation(Color(0xFFB062FF)),
                ),
              ),
            ),
          ),
          error: (_, __) => SliverToBoxAdapter(
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

// ── My Communities View ───────────────────────────────────────────────────────

class _MyCommunitiesView extends ConsumerWidget {
  final String type;

  const _MyCommunitiesView({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myAsync = ref.watch(myCommunitiesProvider);

    return myAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator.adaptive(
          valueColor: AlwaysStoppedAnimation(Color(0xFFB062FF)),
        ),
      ),
      error: (_, __) => Center(
        child: Text('Error loading your communities',
            style: TextStyle(color: Colors.redAccent)),
      ),
      data: (all) {
        final filtered =
            all.where((c) => c.communityType == type).toList();

        if (filtered.isEmpty) {
          return _EmptyState(
            icon: Icons.groups_outlined,
            title: 'No communities joined yet',
            subtitle: 'Switch to Public to discover and join communities',
          );
        }

        return ListView(
          padding: EdgeInsets.fromLTRB(
            context.responsive.wp(20),
            context.responsive.sp(12),
            context.responsive.wp(20),
            context.responsive.sp(32),
          ),
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: context.responsive.sp(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Communities',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.responsive.sp(16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Groups you\'ve joined or created',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: context.responsive.sp(11),
                    ),
                  ),
                ],
              ),
            ),
            ...filtered.map((c) => CommunityCard(community: c, compact: false)),
          ],
        );
      },
    );
  }
}

// ── Private Communities View ──────────────────────────────────────────────────

class _PrivateCommunitiesView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privateAsync = ref.watch(myPrivateCommunitiesProvider);

    return privateAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator.adaptive(
          valueColor: AlwaysStoppedAnimation(Color(0xFFB062FF)),
        ),
      ),
      error: (_, __) => Center(
        child: Text('Error loading private communities',
            style: TextStyle(color: Colors.redAccent)),
      ),
      data: (communities) {
        if (communities.isEmpty) {
          return _EmptyState(
            icon: Icons.lock_outline_rounded,
            title: 'No private communities',
            subtitle: 'Create a private community and invite your friends via link',
          );
        }

        return ListView(
          padding: EdgeInsets.fromLTRB(
            context.responsive.wp(20),
            context.responsive.sp(12),
            context.responsive.wp(20),
            context.responsive.sp(32),
          ),
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: context.responsive.sp(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Private Communities',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.responsive.sp(16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Invite-only groups you belong to',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: context.responsive.sp(11),
                    ),
                  ),
                ],
              ),
            ),
            ...communities.map((c) => _PrivateCommunityCard(community: c)),
          ],
        );
      },
    );
  }
}

// ── Private Community Card ────────────────────────────────────────────────────

class _PrivateCommunityCard extends StatelessWidget {
  final CommunityEntity community;

  const _PrivateCommunityCard({required this.community});

  @override
  Widget build(BuildContext context) {
    final inviteToken = community.inviteToken;
    final inviteLink = inviteToken != null
        ? 'https://readify.app/community/join/$inviteToken'
        : null;

    return Container(
      margin: EdgeInsets.only(bottom: context.responsive.sp(12)),
      child: Column(
        children: [
          CommunityCard(community: community, compact: false),
          if (inviteLink != null && community.isAdmin)
            Container(
              margin: EdgeInsets.only(top: context.responsive.sp(-6)),
              padding: EdgeInsets.all(context.responsive.sp(12)),
              decoration: BoxDecoration(
                color: const Color(0xFF131928),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(context.responsive.sp(14)),
                  bottomRight: Radius.circular(context.responsive.sp(14)),
                ),
                border: Border.all(color: const Color(0xFFB062FF).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.link, color: const Color(0xFFB062FF), size: context.responsive.sp(14)),
                  SizedBox(width: context.responsive.wp(8)),
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
                        color: const Color(0xFFB062FF).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(context.responsive.sp(6)),
                        border: Border.all(color: const Color(0xFFB062FF).withOpacity(0.3)),
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
            ),
        ],
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
        padding: EdgeInsets.all(context.responsive.sp(32)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(context.responsive.sp(24)),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white24,
                size: context.responsive.sp(40),
              ),
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

// ── Shared buttons ────────────────────────────────────────────────────────────

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
              Text(title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.responsive.sp(16),
                    fontWeight: FontWeight.bold,
                  )),
              Text(subtitle,
                  style: TextStyle(color: Colors.white38, fontSize: context.responsive.sp(11))),
            ],
          ),
        ),
        SizedBox(height: context.responsive.sp(8)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.responsive.wp(20)),
          child: Column(children: children),
        ),
        SizedBox(height: context.responsive.sp(8)),
        Divider(color: Colors.white.withOpacity(0.06)),
      ],
    );
  }
}

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