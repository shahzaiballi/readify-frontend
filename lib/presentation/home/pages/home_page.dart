// 🔥 PREMIUM HOME PAGE (NEXT-LEVEL UI)

import 'dart:ui';
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
import '../../profile/controllers/profile_controller.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with TickerProviderStateMixin {
  int _currentIndex = 0;

  late AnimationController _anim;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween(begin: const Offset(0, 0.1), end: Offset.zero).animate(_fade);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _anim.forward();

      final notif = ref.read(notificationServiceProvider);
      notif.requestPermissions();
      notif.scheduleDailyReminders();
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return "Good morning";
    if (h < 17) return "Good afternoon";
    return "Good evening";
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex != 0) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F1626),
        body: _currentIndex == 1
            ? const LibraryPage()
            : _currentIndex == 2
                ? const DiscussionsPage()
                : const ProfilePage(),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
        ),
      );
    }

    final profile = ref.watch(profileControllerProvider);
    final current = ref.watch(currentProgressProvider);
    final insights = ref.watch(insightsProvider);
    final recommended = ref.watch(recommendedBooksProvider);
    final trending = ref.watch(trendingBooksProvider);
    final library = ref.watch(libraryBooksProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
      body: Stack(
        children: [
          // 🔥 BACKGROUND GRADIENT
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0B1020), Color(0xFF141B34)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 🔥 GLASS HEADER
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fade,
                    child: SlideTransition(
                      position: _slide,
                      child: _buildGlassHeader(profile),
                    ),
                  ),
                ),

                // 🔥 MAIN CONTENT
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fade,
                    child: Column(
                      children: [
                        _buildAsync(current, (data) {
                          if (data == null) {
                            return _emptyState();
                          }
                          return CurrentlyReadingCard(progress: data);
                        }),

                        _buildAsync(insights, (data) {
                          return InsightsGrid(insights: data);
                        }),

                        _sectionHeader(
                          "Recommended for You",
                          onTap: () =>
                              context.push('/all_books/recommended'),
                        ),
                      ],
                    ),
                  ),
                ),

                // 🔥 RECOMMENDED
                recommended.when(
                  data: (books) => SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (c, i) => _fadeItem(
                          MinimalBookRowCard(book: books[i]), i),
                      childCount: books.length,
                    ),
                  ),
                  loading: () => _loaderSliver(),
                  error: (_, __) => _errorSliver(),
                ),

                _gap(),

                // 🔥 TRENDING
                SliverToBoxAdapter(
                  child: _buildAsync(trending, (data) {
                    return HorizontalBookList(
                      title: "Trending",
                      books: data,
                      showBadges: true,
                    );
                  }),
                ),

                // 🔥 LIBRARY
              

                _gap(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= UI COMPONENTS =================

  Widget _buildGlassHeader(AsyncValue profile) {
    final name = profile.when(
      data: (p) => (p.name ?? '').split(' ').first,
      loading: () => '',
      error: (_, __) => 'Reader',
    );

    return Padding(
      padding: const EdgeInsets.all(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${_getGreeting()}, ${name.isEmpty ? 'Reader' : name} 👋",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.search, color: Colors.white),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          if (onTap != null)
            GestureDetector(
              onTap: onTap,
              child: const Text("See All",
                  style: TextStyle(color: Color(0xFFB062FF))),
            )
        ],
      ),
    );
  }

  Widget _fadeItem(Widget child, int index) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (_, double val, __) => Opacity(
        opacity: val,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - val)),
          child: child,
        ),
      ),
    );
  }

  Widget _buildAsync<T>(
      AsyncValue<T> async, Widget Function(T data) builder) {
    return async.when(
      data: builder,
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) =>
          const Center(child: Text("Error", style: TextStyle(color: Colors.white))),
    );
  }

  Widget _emptyState() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        "Start your reading journey 📚",
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _loaderSliver() => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );

  Widget _errorSliver() => const SliverToBoxAdapter(
        child: Center(
            child: Text("Error loading data",
                style: TextStyle(color: Colors.white))),
      );

  Widget _gap() => const SliverToBoxAdapter(
        child: SizedBox(height: 20),
      );
}