import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../home/controllers/home_controller.dart';
import '../widgets/book_grid_card.dart';
import 'package:go_router/go_router.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _genres = ['Mystery', 'Romance', 'Fantasy', 'Sci-Fi'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trendingBooks = ref.watch(trendingBooksProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1626),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: context.responsive.isLandscape ? 800 : double.infinity),
                child: CustomScrollView(
                  slivers: [
                    // Modern Header
                    SliverAppBar(
                      backgroundColor: const Color(0xFF0F1626),
                      floating: true,
                      elevation: 0,
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                      title: Text(
                        'Discover',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: context.responsive.sp(22),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      centerTitle: true,
                      toolbarHeight: context.responsive.sp(60),
                    ),

                    // Search Bar Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: context.responsive.wp(20), vertical: context.responsive.sp(16)),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A223B),
                            borderRadius: BorderRadius.circular(context.responsive.sp(16)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: context.responsive.sp(16)),
                            decoration: InputDecoration(
                              hintText: 'Search books, authors, or genres...',
                              hintStyle: TextStyle(color: Colors.white54, fontSize: context.responsive.sp(14)),
                              prefixIcon: Icon(Icons.search, color: const Color(0xFFB062FF), size: context.responsive.sp(20)),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.mic, color: Colors.white54, size: context.responsive.sp(20)),
                                onPressed: () {},
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: context.responsive.sp(16)),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Genres Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: context.responsive.sp(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: context.responsive.wp(20)),
                              child: Text(
                                "Browse Genres",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: context.responsive.sp(18),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: context.responsive.sp(16)),
                            SizedBox(
                              height: context.responsive.sp(44),
                              child: ListView.separated(
                                padding: EdgeInsets.symmetric(horizontal: context.responsive.wp(20)),
                                scrollDirection: Axis.horizontal,
                                itemCount: _genres.length,
                                separatorBuilder: (context, index) => SizedBox(width: context.responsive.wp(12)),
                                itemBuilder: (context, index) {
                                  return _buildGenreChip(_genres[index]);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(child: SizedBox(height: context.responsive.sp(24))),

                    // Trending Section Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          context.responsive.wp(20),
                          0,
                          context.responsive.wp(20),
                          context.responsive.sp(16),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Trending Now',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: context.responsive.sp(18),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: context.responsive.wp(8)),
                            Container(
                              padding: EdgeInsets.all(context.responsive.sp(4)),
                              decoration: BoxDecoration(
                                color: Colors.orangeAccent.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.trending_up, color: Colors.orangeAccent, size: context.responsive.sp(14)),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Trending Grid
                    trendingBooks.when(
                      data: (data) => SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: context.responsive.wp(20)),
                        sliver: SliverGrid(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.55,
                            crossAxisSpacing: context.responsive.wp(12),
                            mainAxisSpacing: context.responsive.sp(16),
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return BookGridCard(book: data[index]);
                            },
                            childCount: data.length,
                          ),
                        ),
                      ),
                      loading: () => const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: CircularProgressIndicator.adaptive(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB062FF)),
                            ),
                          ),
                        ),
                      ),
                      error: (e, st) => SliverToBoxAdapter(
                        child: Center(
                          child: Text('Error: $e', style: const TextStyle(color: Colors.redAccent)),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(child: SizedBox(height: context.responsive.sp(32))),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGenreChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.responsive.wp(20)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB062FF), Color(0xFF6A4CFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(context.responsive.sp(24)),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: context.responsive.sp(14),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

