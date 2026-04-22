// ENHANCED UI: Premium book detail page with hero cover image,
// animated stats, glassmorphic action cards, and smooth transitions
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/responsive_utils.dart';
import '../controllers/book_detail_controller.dart';
import '../widgets/book_detail_header.dart';
import '../widgets/book_stats_row.dart';
import '../widgets/quick_action_card.dart';
import '../../auth/widgets/primary_button.dart';
import 'package:go_router/go_router.dart';

class BookDetailPage extends ConsumerStatefulWidget {
  final String bookId;

  const BookDetailPage({super.key, required this.bookId});

  @override
  ConsumerState<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends ConsumerState<BookDetailPage>
    with TickerProviderStateMixin {
  // ENHANCED UI: Entry animations
  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ENHANCED UI: Scroll-driven header opacity
  final ScrollController _scrollCtrl = ScrollController();
  double _headerOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    _scrollCtrl.addListener(() {
      final opacity = (_scrollCtrl.offset / 200).clamp(0.0, 1.0);
      if ((opacity - _headerOpacity).abs() > 0.01) {
        setState(() => _headerOpacity = opacity);
      }
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookAsyncValue = ref.watch(bookDetailProvider(widget.bookId));

    return Scaffold(
      backgroundColor: const Color(0xFF0F1626),
      // ENHANCED UI: Transparent app bar that fades in on scroll
      appBar: AppBar(
        backgroundColor:
            const Color(0xFF0F1626).withOpacity(_headerOpacity),
        elevation: 0,
        leading: Padding(
          padding: EdgeInsets.all(context.responsive.sp(8)),
          child: GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withOpacity(0.1), width: 1),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: context.responsive.sp(16)),
            ),
          ),
        ),
        title: AnimatedOpacity(
          opacity: _headerOpacity,
          duration: const Duration(milliseconds: 200),
          child: bookAsyncValue.maybeWhen(
            data: (book) => Text(
              book.title,
              style: TextStyle(
                color: Colors.white,
                fontSize: context.responsive.sp(15),
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return bookAsyncValue.when(
              data: (book) => FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _scrollCtrl,
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.symmetric(
                            horizontal: context.responsive.wp(20),
                            vertical: context.responsive.sp(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              BookDetailHeader(book: book),
                              SizedBox(height: context.responsive.sp(28)),

                              // ENHANCED UI: Stats with subtle divider
                              BookStatsRow(book: book),
                              SizedBox(height: context.responsive.sp(28)),

                              // ENHANCED UI: Section label
                              _SectionLabel(label: 'Quick Actions'),
                              SizedBox(height: context.responsive.sp(14)),

                              // ENHANCED UI: Staggered quick action cards
                              ..._buildStaggeredActions(context, book),
                            ],
                          ),
                        ),
                      ),

                      // ENHANCED UI: Pinned bottom CTA with gradient fade
                      _buildBottomCTA(context, book),
                    ],
                  ),
                ),
              ),
              loading: () => _buildLoadingState(context),
              error: (err, st) => _buildErrorState(context, err),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildStaggeredActions(BuildContext context, dynamic book) {
    final actions = [
      (
        'Reading Plan',
        'Track your daily progress',
        Icons.track_changes_rounded,
        const Color(0xFFB062FF),
        () => context.push('/reading_plan'),
      ),
      (
        'Flashcards',
        'Review key concepts',
        Icons.style_rounded,
        const Color(0xFF4A90E2),
        () => context.push('/flashcards/${book.id}'),
      ),
      (
        'Chapter Summary',
        'Chapter-wise summaries',
        Icons.description_rounded,
        const Color(0xFF00B4D8),
        () => context.push('/book_summary/${book.id}'),
      ),
      (
        'Discussions',
        'Join the conversation',
        Icons.chat_bubble_rounded,
        const Color(0xFFE83E8C),
        () => context.push('/all_discussions?bookId=${book.id}'),
      ),
    ];

    return List.generate(actions.length, (i) {
      return TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: Duration(milliseconds: 400 + (i * 80)),
        curve: Curves.easeOut,
        builder: (_, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        ),
        child: Padding(
          padding:
              EdgeInsets.only(bottom: context.responsive.sp(10)),
          child: QuickActionCard(
            title: actions[i].$1,
            subtitle: actions[i].$2,
            icon: actions[i].$3,
            iconColor: actions[i].$4,
            onTap: actions[i].$5,
            hasNotification: actions[i].$1 == 'Discussions',
          ),
        ),
      );
    });
  }

  Widget _buildBottomCTA(BuildContext context, dynamic book) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.responsive.wp(20),
        context.responsive.sp(12),
        context.responsive.wp(20),
        context.responsive.sp(20),
      ),
      decoration: BoxDecoration(
        // ENHANCED UI: Gradient fade from transparent to background
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0F1626).withOpacity(0),
            const Color(0xFF0F1626).withOpacity(0.95),
            const Color(0xFF0F1626),
          ],
          stops: const [0, 0.3, 1],
        ),
      ),
      child: PrimaryButton(
        text: 'Continue Reading',
        onPressed: () => context.push('/chapters/${book.id}'),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(context.responsive.wp(20)),
      child: Column(
        children: [
          _ShimmerBlock(height: context.responsive.sp(200)),
          SizedBox(height: context.responsive.sp(20)),
          _ShimmerBlock(height: context.responsive.sp(80)),
          SizedBox(height: context.responsive.sp(20)),
          _ShimmerBlock(height: context.responsive.sp(200)),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object err) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.responsive.wp(32)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(context.responsive.sp(24)),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off_rounded,
                  color: Colors.redAccent.withOpacity(0.7),
                  size: context.responsive.sp(40)),
            ),
            SizedBox(height: context.responsive.sp(20)),
            Text(
              'Failed to load book details',
              style: TextStyle(
                color: Colors.white,
                fontSize: context.responsive.sp(16),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.responsive.sp(8)),
            Text(
              'Check your connection and try again',
              style: TextStyle(
                color: Colors.white54,
                fontSize: context.responsive.sp(13),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ENHANCED UI: Shimmer block for loading state
class _ShimmerBlock extends StatefulWidget {
  final double height;
  const _ShimmerBlock({required this.height});

  @override
  State<_ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<_ShimmerBlock>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
    _anim = Tween<double>(begin: -2, end: 2)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value, 0),
            colors: const [Color(0xFF1A1F36), Color(0xFF232840), Color(0xFF1A1F36)],
          ),
        ),
      ),
    );
  }
}

// ENHANCED UI: Consistent section label widget
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: Colors.white,
        fontSize: context.responsive.sp(18),
        fontWeight: FontWeight.bold,
        letterSpacing: -0.2,
      ),
    );
  }
}
