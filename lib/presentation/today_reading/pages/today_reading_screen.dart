import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/today_reading_entity.dart';
import '../controllers/today_reading_controller.dart';
import '../widgets/day_complete_card.dart';
import '../widgets/today_summary_sheet.dart';

class TodayReadingScreen extends ConsumerStatefulWidget {
  final String bookId;
  const TodayReadingScreen({super.key, required this.bookId});

  @override
  ConsumerState<TodayReadingScreen> createState() => _TodayReadingScreenState();
}

class _TodayReadingScreenState extends ConsumerState<TodayReadingScreen> {
  static const _bg = Color(0xFF0A0F1E);
  static const _accent = Color(0xFFB062FF);
  static const _textPrimary = Color(0xFFF1F1F3);
  static const _textSecondary = Color(0xFF8A8FA8);

  double _fontSize = 17.0;
  bool _showFontControls = false;

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(todayReadingControllerProvider(widget.bookId));

    return asyncState.when(
      loading: () => const Scaffold(
        backgroundColor: _TodayReadingScreenState._bg,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_TodayReadingScreenState._accent),
          ),
        ),
      ),
      error: (err, _) => _ErrorView(
        message: err.toString().replaceAll('Exception: ', ''),
      ),
      data: (state) {
        if (state.isComplete) {
          return _CompletionView(
            bookId: widget.bookId,
            reading: state.reading,
            result: state.completeResult,
          );
        }
        return _buildReader(context, state);
      },
    );
  }

  Widget _buildReader(BuildContext context, TodayReadingState state) {
    final controller =
        ref.read(todayReadingControllerProvider(widget.bookId).notifier);
    final reading = state.reading;
    final chunks = state.chunks;
    final idx = state.currentChunkIndex;
    final isLast = state.isOnLastChunk;
    final currentChunk = state.currentChunk;

    final chapter = _chapterForIndex(idx, reading);
    final globalPageNum =
        currentChunk?.pageNumber ?? (reading.todayPageStart + idx);
    final totalToday = chunks.length;

    return Scaffold(
      backgroundColor: _TodayReadingScreenState._bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Session progress bar ──────────────────────────────────────
            _SessionProgressBar(
              current: idx + 1,
              total: totalToday,
            ),

            // ── Top header ────────────────────────────────────────────────
            _TopHeader(
              chapterNumber: chapter?.number ?? 0,
              chapterTitle: chapter?.title ?? '',
              dayNumber: reading.dayNumber,
              totalDays: reading.totalDays,
              onBack: () => Navigator.of(context).pop(),
              onFontTap: () =>
                  setState(() => _showFontControls = !_showFontControls),
            ),

            // ── Font size controls ────────────────────────────────────────
            if (_showFontControls)
              _FontControls(
                fontSize: _fontSize,
                onDecrease: () => setState(
                    () => _fontSize = (_fontSize - 1).clamp(13.0, 26.0)),
                onIncrease: () => setState(
                    () => _fontSize = (_fontSize + 1).clamp(13.0, 26.0)),
              ),

            // ── Page indicator pill ───────────────────────────────────────
            _PagePill(
              current: idx + 1,
              total: totalToday,
              globalPage: globalPageNum,
            ),

            const SizedBox(height: 4),

            // ── Reading content ───────────────────────────────────────────
            Expanded(
              child: chunks.isEmpty
                  ? _EmptyState(isComplete: reading.isTodayComplete)
                  : _ReadingContent(
                      key: ValueKey(idx),
                      text: currentChunk?.text ?? '',
                      fontSize: _fontSize,
                    ),
            ),

            // ── Bottom navigation ─────────────────────────────────────────
            _BottomNav(
              currentIndex: idx,
              total: totalToday,
              isLast: isLast,
              onPrevious: () => controller.previousPage(),
              onNext: () => controller.nextPage(),
              onSummary:
                  isLast ? () => _showSummarySheet(context) : null,
            ),
          ],
        ),
      ),
    );
  }

  void _showSummarySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TodaySummarySheet(
        bookId: widget.bookId,
        onSkimComplete: () => Navigator.of(context, rootNavigator: true).pop(),
      ),
    );
  }

  TodayChapterEntity? _chapterForIndex(
      int idx, TodayReadingEntity reading) {
    int seen = 0;
    for (final ch in reading.chapters) {
      if (idx < seen + ch.chunks.length) return ch;
      seen += ch.chunks.length;
    }
    return reading.chapters.isNotEmpty ? reading.chapters.last : null;
  }
}

// ── Session progress bar ────────────────────────────────────────────────────

class _SessionProgressBar extends StatelessWidget {
  final int current;
  final int total;
  const _SessionProgressBar({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? current / total : 0.0;
    return Stack(
      children: [
        Container(height: 3, color: const Color(0xFF1E2640)),
        FractionallySizedBox(
          widthFactor: pct.clamp(0.0, 1.0),
          child: Container(
            height: 3,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF9146FF), Color(0xFFB062FF)],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Top header ──────────────────────────────────────────────────────────────

class _TopHeader extends StatelessWidget {
  final int chapterNumber;
  final String chapterTitle;
  final int dayNumber;
  final int totalDays;
  final VoidCallback onBack;
  final VoidCallback onFontTap;

  const _TopHeader({
    required this.chapterNumber,
    required this.chapterTitle,
    required this.dayNumber,
    required this.totalDays,
    required this.onBack,
    required this.onFontTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = chapterTitle.length > 28
        ? '${chapterTitle.substring(0, 26)}…'
        : chapterTitle;

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 6, 12, 6),
      color: _TodayReadingScreenState._bg,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: _TodayReadingScreenState._textSecondary, size: 18),
            onPressed: onBack,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (chapterTitle.isNotEmpty)
                  Text(
                    'Ch. $chapterNumber  ·  $title',
                    style: const TextStyle(
                      color: _TodayReadingScreenState._textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                Text(
                  'Day $dayNumber of $totalDays',
                  style: const TextStyle(
                    color: _TodayReadingScreenState._textSecondary,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.text_fields_rounded,
                color: _TodayReadingScreenState._textSecondary, size: 20),
            onPressed: onFontTap,
            tooltip: 'Font size',
          ),
        ],
      ),
    );
  }
}

// ── Font size controls ──────────────────────────────────────────────────────

class _FontControls extends StatelessWidget {
  final double fontSize;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _FontControls({
    required this.fontSize,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF131929),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
            const Text('A',
              style: TextStyle(color: _TodayReadingScreenState._textSecondary, fontSize: 13)),
          const SizedBox(width: 16),
          _IconBtn(icon: Icons.remove, onTap: onDecrease),
          const SizedBox(width: 12),
          Text(
            '${fontSize.toInt()}px',
            style: const TextStyle(
              color: _TodayReadingScreenState._textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          _IconBtn(icon: Icons.add, onTap: onIncrease),
          const SizedBox(width: 16),
          const Text('A',
              style: TextStyle(color: _TodayReadingScreenState._textPrimary, fontSize: 20)),
        ],
      ),
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
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon,
            color: _TodayReadingScreenState._textPrimary, size: 14),
      ),
    );
  }
}

// ── Page indicator pill ─────────────────────────────────────────────────────

class _PagePill extends StatelessWidget {
  final int current;
  final int total;
  final int globalPage;

  const _PagePill(
      {required this.current, required this.total, required this.globalPage});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _TodayReadingScreenState._accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Page $current of $total today',
              style: const TextStyle(
                color: _TodayReadingScreenState._accent,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '(Book page $globalPage)',
            style: const TextStyle(
              color: _TodayReadingScreenState._textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reading content ─────────────────────────────────────────────────────────

class _ReadingContent extends StatelessWidget {
  final String text;
  final double fontSize;

  const _ReadingContent({super.key, required this.text, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: SelectableText(
        text,
        style: GoogleFonts.merriweather(
          fontSize: fontSize,
          height: 1.85,
          color: _TodayReadingScreenState._textPrimary,
          letterSpacing: 0.15,
        ),
        textAlign: TextAlign.left,
      ),
    );
  }
}

// ── Empty state ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isComplete;
  const _EmptyState({required this.isComplete});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
                decoration: BoxDecoration(
                color: _TodayReadingScreenState._accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_stories_rounded,
                  color: _TodayReadingScreenState._accent, size: 32),
            ),
            const SizedBox(height: 20),
            Text(
              isComplete
                  ? "You've finished today's reading!"
                  : 'No reading content yet',
              style: const TextStyle(
                color: _TodayReadingScreenState._textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isComplete
                  ? 'Come back tomorrow for the next session.'
                  : 'This book may still be processing.',
              style: const TextStyle(
                color: _TodayReadingScreenState._textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back,
                  size: 16, color: _TodayReadingScreenState._accent),
              label: const Text('Go Back',
                  style: TextStyle(color: _TodayReadingScreenState._accent)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom navigation bar ───────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final int total;
  final bool isLast;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback? onSummary;

  const _BottomNav({
    required this.currentIndex,
    required this.total,
    required this.isLast,
    required this.onPrevious,
    required this.onNext,
    this.onSummary,
  });

  @override
  Widget build(BuildContext context) {
    final hasPrev = currentIndex > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: _TodayReadingScreenState._bg,
        border: Border(top: BorderSide(color: Color(0xFF1E2640), width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLast && onSummary != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: onSummary,
                child: Container(
                  width: double.infinity,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2640),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF9146FF)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('⚡', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 6),
                      Text(
                        'AI Summary',
                        style: TextStyle(
                          color: Color(0xFFB062FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Row(
            children: [
          // Previous button
          Expanded(
            child: GestureDetector(
              onTap: hasPrev ? onPrevious : null,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: hasPrev
                      ? const Color(0xFF1E2640)
                      : const Color(0xFF131929),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: hasPrev ? Colors.white12 : Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_back_ios_new,
                      size: 14,
                        color: hasPrev
                          ? _TodayReadingScreenState._textPrimary
                          : _TodayReadingScreenState._textSecondary
                            .withValues(alpha: 0.3),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Previous',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: hasPrev
                            ? _TodayReadingScreenState._textPrimary
                            : _TodayReadingScreenState._textSecondary
                                .withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Next / Finish button
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: onNext,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: isLast
                      ? const LinearGradient(
                          colors: [Color(0xFF3CCF7E), Color(0xFF29A867)],
                        )
                      : const LinearGradient(
                          colors: [Color(0xFF9146FF), Color(0xFFB062FF)],
                        ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: (isLast
                              ? const Color(0xFF3CCF7E)
                              : const Color(0xFFB062FF))
                          .withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLast ? 'Finish Today\'s Reading' : 'Next Page',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      isLast
                          ? Icons.check_circle_outline_rounded
                          : Icons.arrow_forward_ios_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Completion view ─────────────────────────────────────────────────────────

class _CompletionView extends StatelessWidget {
  final String bookId;
  final TodayReadingEntity reading;
  final TodayCompleteResult? result;

  const _CompletionView({
    required this.bookId,
    required this.reading,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _TodayReadingScreenState._bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.close,
                      color: _TodayReadingScreenState._textSecondary),
                  onPressed: () => context.go('/home'),
                ),
              ),
              DayCompleteCard(
                bookId: bookId,
                reading: reading,
                result: result,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Error view ──────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _TodayReadingScreenState._bg,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back,
                    color: _TodayReadingScreenState._textSecondary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.error_outline_rounded,
                        color: Colors.redAccent, size: 28),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Unable to load reading',
                    style: TextStyle(
                      color: _TodayReadingScreenState._textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    style: const TextStyle(
                      color: _TodayReadingScreenState._textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back',
                    style: TextStyle(
                      color: _TodayReadingScreenState._accent)),
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
