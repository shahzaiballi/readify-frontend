import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../home/controllers/home_controller.dart';
import '../../library/controllers/library_controller.dart';
import '../../../domain/entities/user_stats_entity.dart';
import '../../../domain/entities/library_book_entity.dart';
import '../widgets/reading_stats_card.dart';
import '../widgets/progress_chart_widget.dart';
import '../widgets/completed_books_widget.dart';

class ProgressPage extends ConsumerWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(insightsProvider);
    final rawLibraryAsync = ref.watch(rawLibraryProvider);
    final currentProgressAsync = ref.watch(currentProgressProvider);

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.responsive.wp(20),
                vertical: context.responsive.sp(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Progress',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.responsive.sp(28),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: context.responsive.sp(8)),
                  Text(
                    'Track your reading journey',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: context.responsive.sp(14),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Reading Stats
          SliverToBoxAdapter(
            child: insightsAsync.when(
              data: (insights) {
                final booksRead = rawLibraryAsync.valueOrNull
                    ?.where((b) => b.status == LibraryStatus.completed)
                    .length ?? 0;
                return _buildStatsSection(context, insights, booksRead);
              },
              loading: () => _buildLoadingStatsSection(context),
              error: (e, _) => _buildErrorWidget(context),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: context.responsive.sp(24))),

          // Progress Chart
          SliverToBoxAdapter(
            child: currentProgressAsync.when(
              data: (progress) => progress != null
                  ? ProgressChartWidget(progress: progress)
                  : _buildNoReadingState(context),
              loading: () => Center(
                child: Padding(
                  padding: EdgeInsets.all(context.responsive.sp(24)),
                  child: const CircularProgressIndicator.adaptive(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB062FF)),
                  ),
                ),
              ),
              error: (e, _) => _buildErrorWidget(context),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: context.responsive.sp(24))),

          // Completed Books Section
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: context.responsive.wp(20)),
              child: Text(
                'Completed Books',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: context.responsive.sp(18),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: context.responsive.sp(12))),

          SliverToBoxAdapter(
            child: rawLibraryAsync.when(
              data: (books) {
                final completedBooks = books
                    .where((b) => b.status == LibraryStatus.completed)
                    .toList();
                return completedBooks.isNotEmpty
                    ? CompletedBooksWidget(books: completedBooks)
                    : _buildNoCompletedBooksState(context);
              },
              loading: () => Center(
                child: Padding(
                  padding: EdgeInsets.all(context.responsive.sp(24)),
                  child: const CircularProgressIndicator.adaptive(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB062FF)),
                  ),
                ),
              ),
              error: (e, _) => _buildErrorWidget(context),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: context.responsive.sp(32))),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, InsightsEntity insights, int booksRead) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.responsive.wp(20)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ReadingStatsCard(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Day Streak',
                  value: '${insights.dayStreak}',
                  unit: 'days',
                  backgroundColor: const Color(0xFFFF6B6B),
                ),
              ),
              SizedBox(width: context.responsive.wp(12)),
              Expanded(
                child: ReadingStatsCard(
                  icon: Icons.menu_book_rounded,
                  label: 'Pages Today',
                  value: '${insights.readTodayPages}',
                  unit: 'pages',
                  backgroundColor: const Color(0xFF4ECDC4),
                ),
              ),
            ],
          ),
          SizedBox(height: context.responsive.sp(12)),
          Row(
            children: [
              Expanded(
                child: ReadingStatsCard(
                  icon: Icons.bookmarks_rounded,
                  label: 'Cards Due',
                  value: '${insights.cardsDue}',
                  unit: 'cards',
                  backgroundColor: const Color(0xFFFFD93D),
                ),
              ),
              SizedBox(width: context.responsive.wp(12)),
              Expanded(
                child: ReadingStatsCard(
                  icon: Icons.menu_book_rounded,
                  label: 'Books Read',
                  value: '$booksRead',
                  unit: 'books',
                  backgroundColor: const Color(0xFF6BCB77),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingStatsSection(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.responsive.wp(20)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: context.responsive.sp(120),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(context.responsive.sp(16)),
                  ),
                ),
              ),
              SizedBox(width: context.responsive.wp(12)),
              Expanded(
                child: Container(
                  height: context.responsive.sp(120),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(context.responsive.sp(16)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoReadingState(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.responsive.wp(20),
        vertical: context.responsive.sp(32),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.auto_stories_rounded,
              color: Colors.white24,
              size: context.responsive.sp(64),
            ),
            SizedBox(height: context.responsive.sp(16)),
            Text(
              'No reading history yet',
              style: TextStyle(
                color: Colors.white70,
                fontSize: context.responsive.sp(16),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: context.responsive.sp(8)),
            Text(
              'Start reading a book to track your progress',
              style: TextStyle(
                color: Colors.white38,
                fontSize: context.responsive.sp(13),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCompletedBooksState(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.responsive.wp(20)),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.emoji_events_outlined,
              color: Colors.white24,
              size: context.responsive.sp(48),
            ),
            SizedBox(height: context.responsive.sp(12)),
            Text(
              'No completed books yet',
              style: TextStyle(
                color: Colors.white70,
                fontSize: context.responsive.sp(14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.responsive.wp(20),
        vertical: context.responsive.sp(32),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.redAccent,
              size: context.responsive.sp(48),
            ),
            SizedBox(height: context.responsive.sp(16)),
            Text(
              'Error loading progress',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: context.responsive.sp(14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
