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
import '../../profile/controllers/reading_plan_controller.dart';
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
              data: (book) {
                final isStarted = book.progressPercent > 0;
                return FadeTransition(
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
                                SizedBox(height: context.responsive.sp(24)),

                                if (isStarted) ...[  
                                  // In-progress: show reading progress stats
                                  BookStatsRow(book: book),
                                  SizedBox(height: context.responsive.sp(28)),
                                ] else ...[  
                                  // Not started: show About + discovery info
                                  if (book.description.isNotEmpty) ...[  
                                    _buildAboutSection(context, book),
                                    SizedBox(height: context.responsive.sp(20)),
                                  ],
                                  _buildDiscoveryStats(context, book),
                                  SizedBox(height: context.responsive.sp(28)),
                                ],

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
                );
              },
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
            hasNotification: false,
          ),
        ),
      );
    });
  }

  Widget _buildBottomCTA(BuildContext context, dynamic book) {
    final isStarted = (book.progressPercent as int) > 0;
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
        text: isStarted ? 'Continue Reading' : 'Start Reading',
        onPressed: isStarted
            ? () => context.push('/chapters/${book.id}')
            : () => _showStartReadingSheet(context, book),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context, dynamic book) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label: 'About this Book'),
        SizedBox(height: context.responsive.sp(12)),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(context.responsive.sp(16)),
          decoration: BoxDecoration(
            color: const Color(0xFF1E233D),
            borderRadius: BorderRadius.circular(context.responsive.sp(12)),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Text(
            book.description as String,
            style: TextStyle(
              color: Colors.white70,
              fontSize: context.responsive.sp(13),
              height: 1.65,
            ),
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDiscoveryStats(BuildContext context, dynamic book) {
    return Row(
      children: [
        Expanded(
          child: _DiscoveryStat(
            value: '${book.pagesLeft}',
            label: 'Total Pages',
            context: context,
          ),
        ),
        SizedBox(width: context.responsive.wp(12)),
        Expanded(
          child: _DiscoveryStat(
            value: '${book.totalChapters}',
            label: 'Chapters',
            context: context,
          ),
        ),
        SizedBox(width: context.responsive.wp(12)),
        Expanded(
          child: _DiscoveryStat(
            value: (book.rating as double).toStringAsFixed(1),
            label: 'Rating',
            context: context,
            isRating: true,
          ),
        ),
      ],
    );
  }

  Widget _DiscoveryStat({
    required String value,
    required String label,
    required BuildContext context,
    bool isRating = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: context.responsive.sp(16)),
      decoration: BoxDecoration(
        color: const Color(0xFF1E233D),
        borderRadius: BorderRadius.circular(context.responsive.sp(12)),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          if (isRating)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_rounded, color: Colors.amber, size: context.responsive.sp(14)),
                SizedBox(width: context.responsive.wp(3)),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.responsive.sp(18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          else
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: context.responsive.sp(18),
                fontWeight: FontWeight.bold,
              ),
            ),
          SizedBox(height: context.responsive.sp(4)),
          Text(
            label,
            style: TextStyle(
              color: Colors.white54,
              fontSize: context.responsive.sp(11),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showStartReadingSheet(BuildContext context, dynamic book) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StartReadingSheet(
        bookId: book.id as String,
        onStart: () => context.push('/chapters/${book.id}'),
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
      builder: (_, _) => Container(
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

// ── Start Reading Sheet ────────────────────────────────────────────────────────

class _StartReadingSheet extends ConsumerStatefulWidget {
  final String bookId;
  final VoidCallback onStart;

  const _StartReadingSheet({
    required this.bookId,
    required this.onStart,
  });

  @override
  ConsumerState<_StartReadingSheet> createState() => _StartReadingSheetState();
}

class _StartReadingSheetState extends ConsumerState<_StartReadingSheet> {
  late String _selectedMode;
  late int _dailyMinutes;
  bool _useCustom = false;

  static const _modes = ['skim', 'concept', 'deep', 'exam'];
  static const _modeEmoji = {'skim': '⚡', 'concept': '💡', 'deep': '🧠', 'exam': '🎯'};
  static const _modeLabels = {'skim': 'Skim', 'concept': 'Concept', 'deep': 'Deep', 'exam': 'Exam'};

  String get _planSummary =>
      '${_modeEmoji[_selectedMode]} ${_modeLabels[_selectedMode]} · $_dailyMinutes min/day';

  @override
  void initState() {
    super.initState();
    final plan = ref.read(readingPlanProvider);
    _selectedMode = plan.readingMode;
    _dailyMinutes = plan.dailyMinutes;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F1626),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(context.responsive.sp(24)),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          context.responsive.wp(24),
          context.responsive.sp(12),
          context.responsive.wp(24),
          MediaQuery.of(context).padding.bottom + context.responsive.sp(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: context.responsive.sp(20)),
            Text(
              'Reading Plan',
              style: TextStyle(
                color: Colors.white,
                fontSize: context.responsive.sp(18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: context.responsive.sp(4)),
            Text(
              'How do you want to read this book?',
              style: TextStyle(
                color: Colors.white54,
                fontSize: context.responsive.sp(13),
              ),
            ),
            SizedBox(height: context.responsive.sp(20)),
            _PlanOptionTile(
              isSelected: !_useCustom,
              icon: Icons.tune_rounded,
              title: 'Use Default Plan',
              subtitle: _planSummary,
              onTap: () => setState(() => _useCustom = false),
            ),
            SizedBox(height: context.responsive.sp(10)),
            _PlanOptionTile(
              isSelected: _useCustom,
              icon: Icons.edit_note_rounded,
              title: 'Custom for this book',
              subtitle: 'Override your default settings',
              onTap: () => setState(() => _useCustom = true),
            ),
            if (_useCustom) ...[
              SizedBox(height: context.responsive.sp(16)),
              Container(
                padding: EdgeInsets.all(context.responsive.sp(14)),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E233D),
                  borderRadius: BorderRadius.circular(context.responsive.sp(12)),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reading Mode',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: context.responsive.sp(12),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: context.responsive.sp(10)),
                    Row(
                      children: _modes.map((mode) {
                        final selected = _selectedMode == mode;
                        final isLast = mode == _modes.last;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedMode = mode),
                            child: Container(
                              margin: EdgeInsets.only(
                                right: isLast ? 0 : context.responsive.wp(6),
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: context.responsive.sp(8),
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFFB062FF)
                                    : const Color(0xFF0F1626),
                                borderRadius: BorderRadius.circular(
                                  context.responsive.sp(8),
                                ),
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFFB062FF)
                                      : Colors.white12,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    _modeEmoji[mode] ?? '',
                                    style: TextStyle(
                                      fontSize: context.responsive.sp(14),
                                    ),
                                  ),
                                  SizedBox(height: context.responsive.sp(2)),
                                  Text(
                                    _modeLabels[mode] ?? mode,
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : Colors.white54,
                                      fontSize: context.responsive.sp(10),
                                      fontWeight: selected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: context.responsive.sp(14)),
                    Row(
                      children: [
                        Text(
                          'Daily reading:',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: context.responsive.sp(12),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            if (_dailyMinutes > 5) {
                              setState(() => _dailyMinutes -= 5);
                            }
                          },
                          child: Container(
                            width: context.responsive.sp(28),
                            height: context.responsive.sp(28),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F1626),
                              borderRadius: BorderRadius.circular(
                                context.responsive.sp(6),
                              ),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Icon(
                              Icons.remove,
                              color: Colors.white54,
                              size: context.responsive.sp(14),
                            ),
                          ),
                        ),
                        SizedBox(width: context.responsive.wp(10)),
                        Text(
                          '$_dailyMinutes min',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: context.responsive.sp(13),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: context.responsive.wp(10)),
                        GestureDetector(
                          onTap: () {
                            if (_dailyMinutes < 180) {
                              setState(() => _dailyMinutes += 5);
                            }
                          },
                          child: Container(
                            width: context.responsive.sp(28),
                            height: context.responsive.sp(28),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F1626),
                              borderRadius: BorderRadius.circular(
                                context.responsive.sp(6),
                              ),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Icon(
                              Icons.add,
                              color: Colors.white54,
                              size: context.responsive.sp(14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: context.responsive.sp(24)),
            SizedBox(
              width: double.infinity,
              height: context.responsive.sp(52),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9146FF), Color(0xFF3861FB)],
                  ),
                  borderRadius: BorderRadius.circular(context.responsive.sp(12)),
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onStart();
                  },
                  icon: Icon(
                    Icons.menu_book_rounded,
                    color: Colors.white,
                    size: context.responsive.sp(18),
                  ),
                  label: Text(
                    'Start Reading',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.responsive.sp(15),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(context.responsive.sp(12)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Plan Option Tile ───────────────────────────────────────────────────────────

class _PlanOptionTile extends StatelessWidget {
  final bool isSelected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PlanOptionTile({
    required this.isSelected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(context.responsive.sp(14)),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFB062FF).withOpacity(0.1)
              : const Color(0xFF1E233D),
          borderRadius: BorderRadius.circular(context.responsive.sp(12)),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFB062FF)
                : Colors.white.withOpacity(0.06),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(context.responsive.sp(8)),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFB062FF).withOpacity(0.2)
                    : const Color(0xFF2A2F4C),
                borderRadius: BorderRadius.circular(context.responsive.sp(8)),
              ),
              child: Icon(
                icon,
                color: isSelected ? const Color(0xFFB062FF) : Colors.white54,
                size: context.responsive.sp(16),
              ),
            ),
            SizedBox(width: context.responsive.wp(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFFB062FF)
                          : Colors.white,
                      fontSize: context.responsive.sp(14),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: context.responsive.sp(2)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: context.responsive.sp(12),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: const Color(0xFFB062FF),
                size: context.responsive.sp(18),
              ),
          ],
        ),
      ),
    );
  }
}

