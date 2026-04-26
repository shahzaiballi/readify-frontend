import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../controllers/chapter_controller.dart';
import '../widgets/chapter_header_card.dart';
import '../widgets/chapter_list_item.dart';
import '../../book_detail/controllers/book_detail_controller.dart';

class ChapterListPage extends ConsumerWidget {
  final String bookId;

  const ChapterListPage({super.key, required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We fetch book details to populate the top summary block
    final bookDetailsAsync = ref.watch(bookDetailProvider(bookId));
    final chaptersAsync = ref.watch(chapterListProvider(bookId));

    return Scaffold(
      backgroundColor: const Color(0xFF0F1626),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: context.responsive.isLandscape ? 800 : double.infinity),
                child: Column(
                  children: [
                    // Navigation Bar Header
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: context.responsive.wp(20),
                          vertical: context.responsive.sp(16)),
                      child: Row(
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                                color: Color(0xFF1E233D), shape: BoxShape.circle),
                            child: IconButton(
                              icon: Icon(Icons.arrow_back,
                                  color: Colors.white70,
                                  size: context.responsive.sp(20)),
                              // FIX: Use context.pop() which correctly navigates
                              // back to the previous route in the navigation stack
                              // (BookDetailPage). The old fallback context.go('/')
                              // was sending users to the root/onboarding which
                              // broke the entire navigation flow.
                              onPressed: () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  // Only fall back to /home — never to '/'
                                  // which would hit the onboarding redirect.
                                  context.go('/home');
                                }
                              },
                            ),
                          ),
                          SizedBox(width: context.responsive.wp(16)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Chapters',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: context.responsive.sp(18),
                                    fontWeight: FontWeight.bold),
                              ),
                              bookDetailsAsync.maybeWhen(
                                data: (book) => Text(
                                  book.title,
                                  style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: context.responsive.sp(12)),
                                ),
                                orElse: () => const SizedBox.shrink(),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),

                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          // Header Summary Block
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: context.responsive.wp(20),
                                  vertical: context.responsive.sp(16)),
                              child: bookDetailsAsync.when(
                                data: (book) {
                                  return chaptersAsync.when(
                                    data: (chapters) => ChapterHeaderCard(
                                        book: book, chapters: chapters),
                                    loading: () => const Center(
                                        child: CircularProgressIndicator.adaptive(
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                                Color(0xFFB062FF)))),
                                    error: (e, st) => const SizedBox.shrink(),
                                  );
                                },
                                loading: () => const Center(
                                    child: CircularProgressIndicator.adaptive(
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                            Color(0xFFB062FF)))),
                                error: (e, st) => Text('Error: $e',
                                    style: const TextStyle(color: Colors.redAccent)),
                              ),
                            ),
                          ),

                          // Chapters List
                          chaptersAsync.when(
                            data: (chapters) => SliverPadding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: context.responsive.wp(20)),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) => ChapterListItem(
                                      chapter: chapters[index], bookId: bookId),
                                  childCount: chapters.length,
                                ),
                              ),
                            ),
                            loading: () => const SliverToBoxAdapter(
                                child: Center(
                                    child: CircularProgressIndicator.adaptive(
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                            Color(0xFFB062FF))))),
                            error: (e, st) => SliverToBoxAdapter(
                                child: Center(
                                    child: Text('Error: $e',
                                        style: const TextStyle(
                                            color: Colors.redAccent)))),
                          ),

                          SliverToBoxAdapter(
                              child: SizedBox(height: context.responsive.sp(32))),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}