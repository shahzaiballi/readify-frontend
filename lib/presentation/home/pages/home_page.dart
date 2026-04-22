// ENHANCED UI: Complete premium home page with staggered animations,
// glassmorphism effects, and polished micro-interactions
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/services/notification_service.dart';
import '../controllers/home_controller.dart';
import '../widgets/currently_reading_card.dart';
import '../widgets/insights_grid.dart';
import '../widgets/minimal_book_row_card.dart';
import '../widgets/horizontal_book_list.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../../library/pages/library_page.dart';
import '../../discussions/pages/discussions_page.dart';
import '../../profile/pages/profile_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with TickerProviderStateMixin {
  int _currentIndex = 0;

  // ENHANCED UI: Staggered entry animation controllers
  late AnimationController _headerAnimController;
  late AnimationController _contentAnimController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _contentFade;

  @override
  void initState() {
    super.initState();

    // ENHANCED UI: Header animation
    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _headerFade = CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeOut,
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeOutCubic,
    ));

    // ENHANCED UI: Content stagger animation
    _contentAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _contentFade = CurvedAnimation(
      parent: _contentAnimController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _headerAnimController.forward();
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _contentAnimController.forward();
      });

      final notifService = ref.read(notificationServiceProvider);
      notifService.requestPermissions();
      notifService.scheduleDailyReminders();
    });
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    _contentAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex != 0) {
      Widget bodyContent;
      if (_currentIndex == 1) {
        bodyContent = const LibraryPage();
      } else if (_currentIndex == 2) {
        bodyContent = const DiscussionsPage();
      } else if (_currentIndex == 3) {
        bodyContent = const ProfilePage();
      } else {
        bodyContent = Center(
            child: Text("Tab $_currentIndex Content",
                style: const TextStyle(color: Colors.white)));
      }

      return Scaffold(
        backgroundColor: const Color(0xFF0F1626),
        body: bodyContent,
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
        ),
      );
    }

    final currentProgress = ref.watch(currentProgressProvider);
    final insights = ref.watch(insightsProvider);
    final recommendedBooks = ref.watch(recommendedBooksProvider);
    final trendingBooks = ref.watch(trendingBooksProvider);
    final libraryBooks = ref.watch(libraryBooksProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1626),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: context.responsive.isLandscape
                        ? 800
                        : double.infinity),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  slivers: [
                    // ENHANCED UI: Animated floating header with greeting
                    SliverToBoxAdapter(
                      child: SlideTransition(
                        position: _headerSlide,
                        child: FadeTransition(
                          opacity: _headerFade,
                          child: _buildPremiumHeader(context),
                        ),
                      ),
                    ),

                    // ENHANCED UI: Animated content sections
                    SliverToBoxAdapter(
                      child: FadeTransition(
                        opacity: _contentFade,
                        child: Column(
                          children: [
                            // Currently Reading
                            _buildAsyncWidget(
                              asyncValue: currentProgress,
                              builder: (data) => Padding(
                                padding: EdgeInsets.only(
                                    bottom: context.responsive.sp(28)),
                                child: CurrentlyReadingCard(progress: data),
                              ),
                            ),

                            // Insights
                            _buildAsyncWidget(
                              asyncValue: insights,
                              builder: (data) => Padding(
                                padding: EdgeInsets.only(
                                    bottom: context.responsive.sp(28)),
                                child: InsightsGrid(insights: data),
                              ),
                            ),

                            // Recommended Books Header
                            _buildSectionHeader(
                              context,
                              title: 'Recommended for You',
                              subtitle:
                                  'Based on your interest in Self-Improvement',
                              icon: Icons.auto_awesome,
                              onViewAll: () =>
                                  context.push('/all_books/recommended'),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Recommended Books List
                    recommendedBooks.when(
                      data: (books) => SliverList(
                        delegate: SliverChildBuilderDelegate(
                          childCount: books.length,
                          (context, index) => FadeTransition(
                            opacity: _contentFade,
                            child: MinimalBookRowCard(book: books[index]),
                          ),
                        ),
                      ),
                      loading: () => SliverToBoxAdapter(
                          child: _buildShimmerList(context)),
                      error: (e, st) => SliverToBoxAdapter(
                          child: _buildErrorState(context, 'books')),
                    ),

                    SliverToBoxAdapter(
                        child:
                            SizedBox(height: context.responsive.sp(28))),

                    // Trending Books
                    SliverToBoxAdapter(
                      child: FadeTransition(
                        opacity: _contentFade,
                        child: _buildAsyncWidget(
                          asyncValue: trendingBooks,
                          builder: (data) => Padding(
                            padding: EdgeInsets.only(
                                bottom: context.responsive.sp(28)),
                            child: HorizontalBookList(
                              title: 'Trending This Week',
                              books: data,
                              showBadges: true,
                              onViewAll: () =>
                                  context.push('/all_books/trending'),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Library Books
                    SliverToBoxAdapter(
                      child: FadeTransition(
                        opacity: _contentFade,
                        child: _buildAsyncWidget(
                          asyncValue: libraryBooks,
                          builder: (data) => Padding(
                            padding: EdgeInsets.only(
                                bottom: context.responsive.sp(28)),
                            child: HorizontalBookList(
                              title: 'Your Library',
                              books: data,
                              showsAuthor: false,
                              onViewAll: () {
                                setState(() => _currentIndex = 1);
                              },
                            ),
                          ),
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                        child:
                            SizedBox(height: context.responsive.sp(20))),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ENHANCED UI: Premium header with glassmorphism search button
  Widget _buildPremiumHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.responsive.wp(20),
        context.responsive.sp(16),
        context.responsive.wp(20),
        context.responsive.sp(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Good evening, Ali ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: context.responsive.sp(22),
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      '👋',
                      style:
                          TextStyle(fontSize: context.responsive.sp(20)),
                    ),
                  ],
                ),
                SizedBox(height: context.responsive.sp(4)),
                Text(
                  'Ready to continue your reading journey?',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: context.responsive.sp(13),
                  ),
                ),
              ],
            ),
          ),
          // ENHANCED UI: Glassmorphic search button
          GestureDetector(
            onTap: () => context.push('/search'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(context.responsive.sp(10)),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius:
                    BorderRadius.circular(context.responsive.sp(14)),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.search_rounded,
                color: Colors.white,
                size: context.responsive.sp(22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ENHANCED UI: Polished section header with animated indicator
  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    String? subtitle,
    required IconData icon,
    VoidCallback? onViewAll,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.responsive.wp(20),
        vertical: context.responsive.sp(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.responsive.sp(18),
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(width: context.responsive.wp(8)),
                  Icon(icon,
                      color: const Color(0xFFB062FF),
                      size: context.responsive.sp(16)),
                ],
              ),
              if (onViewAll != null)
                GestureDetector(
                  onTap: onViewAll,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.responsive.wp(12),
                      vertical: context.responsive.sp(6),
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB062FF).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(
                          context.responsive.sp(20)),
                      border: Border.all(
                        color: const Color(0xFFB062FF).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'See All',
                          style: TextStyle(
                            color: const Color(0xFFB062FF),
                            fontSize: context.responsive.sp(12),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: context.responsive.wp(4)),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: const Color(0xFFB062FF),
                          size: context.responsive.sp(10),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (subtitle != null) ...[
            SizedBox(height: context.responsive.sp(4)),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: context.responsive.sp(12),
              ),
            ),
          ],
          SizedBox(height: context.responsive.sp(8)),
        ],
      ),
    );
  }

  // ENHANCED UI: Shimmer skeleton loader for books list
  Widget _buildShimmerList(BuildContext context) {
    return Column(
      children: List.generate(
          3,
          (i) => Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsive.wp(20),
                  vertical: context.responsive.sp(8),
                ),
                child: _ShimmerCard(height: context.responsive.sp(110)),
              )),
    );
  }

  // ENHANCED UI: Polished error state
  Widget _buildErrorState(BuildContext context, String type) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: context.responsive.wp(20),
        vertical: context.responsive.sp(16),
      ),
      padding: EdgeInsets.all(context.responsive.sp(24)),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(context.responsive.sp(16)),
        border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded,
              color: Colors.redAccent.withOpacity(0.7),
              size: context.responsive.sp(24)),
          SizedBox(width: context.responsive.wp(16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Failed to load $type',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.responsive.sp(14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Check your connection and try again',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: context.responsive.sp(12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAsyncWidget<T>(
      {required AsyncValue<T> asyncValue,
      required Widget Function(T) builder}) {
    return asyncValue.when(
      data: builder,
      loading: () => const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(
          child: CircularProgressIndicator.adaptive(
            valueColor:
                AlwaysStoppedAnimation<Color>(Color(0xFFB062FF)),
          ),
        ),
      ),
      error: (e, st) => _buildErrorState(context, 'data'),
    );
  }
}

// ENHANCED UI: Animated shimmer skeleton card
class _ShimmerCard extends StatefulWidget {
  final double height;
  const _ShimmerCard({required this.height});

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment(_shimmerAnimation.value - 1, 0),
              end: Alignment(_shimmerAnimation.value, 0),
              colors: const [
                Color(0xFF1A1F36),
                Color(0xFF242A45),
                Color(0xFF1A1F36),
              ],
            ),
          ),
        );
      },
    );
  }
}
