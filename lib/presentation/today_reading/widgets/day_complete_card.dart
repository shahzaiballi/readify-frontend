import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/today_reading_entity.dart';
import '../../../core/utils/responsive_utils.dart';

class DayCompleteCard extends StatelessWidget {
  final String bookId;
  final TodayReadingEntity reading;
  final TodayCompleteResult? result;

  const DayCompleteCard({
    super.key,
    required this.bookId,
    required this.reading,
    this.result,
  });

  String _milestoneMessage(String? milestone) {
    switch (milestone) {
      case '25_percent':
        return '🎯 Quarter way there!';
      case '50_percent':
        return '🔥 Halfway through!';
      case '75_percent':
        return '⚡ Almost there!';
      case '100_percent':
        return '🏆 Book complete!';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = result?.progressPercent ?? reading.progressPercent;
    final daysRemaining = result?.daysRemaining ?? reading.daysRemaining;
    final nextDay = result?.nextDayNumber ?? (reading.dayNumber + 1);
    final totalDays = result?.totalDays ?? reading.totalDays;
    final isBookDone = result?.isBookComplete ?? false;
    final milestone = result?.milestone;
    final pagesReadToday = result?.pagesReadToday ?? reading.pagesPerDay;
    final totalPagesRead = result?.totalPagesRead ?? reading.pagesReadSoFar;
    final totalPages = result?.totalPages ?? reading.totalPages;

    return Container(
      margin: EdgeInsets.all(context.responsive.sp(20)),
      padding: EdgeInsets.all(context.responsive.sp(24)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.responsive.sp(24)),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0A3A), Color(0xFF0D1830)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFB062FF).withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB062FF).withValues(alpha: 0.2),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Celebration icon
          Container(
            width: context.responsive.sp(76),
            height: context.responsive.sp(76),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isBookDone
                  ? const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFF8C00)])
                  : const LinearGradient(
                      colors: [Color(0xFF9146FF), Color(0xFFB062FF)]),
              boxShadow: [
                BoxShadow(
                  color: (isBookDone
                          ? const Color(0xFFFFD700)
                          : const Color(0xFFB062FF))
                      .withValues(alpha: 0.35),
                  blurRadius: 24,
                ),
              ],
            ),
            child: Icon(
              isBookDone ? Icons.emoji_events_rounded : Icons.menu_book_rounded,
              color: Colors.white,
              size: context.responsive.sp(36),
            ),
          ),

          SizedBox(height: context.responsive.sp(20)),

          // Title
          Text(
            isBookDone ? '🎊 Book Complete!' : "Day ${reading.dayNumber} Done!",
            style: TextStyle(
              color: Colors.white,
              fontSize: context.responsive.sp(24),
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: context.responsive.sp(4)),

          Text(
            'You read $pagesReadToday pages today',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: context.responsive.sp(14),
            ),
            textAlign: TextAlign.center,
          ),

          // Milestone banner
          if (milestone != null && milestone.isNotEmpty) ...[
            SizedBox(height: context.responsive.sp(12)),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.responsive.wp(16),
                vertical: context.responsive.sp(7),
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFB062FF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(context.responsive.sp(20)),
                border: Border.all(
                    color: const Color(0xFFB062FF).withValues(alpha: 0.35)),
              ),
              child: Text(
                _milestoneMessage(milestone),
                style: TextStyle(
                  color: const Color(0xFFB062FF),
                  fontSize: context.responsive.sp(13),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          SizedBox(height: context.responsive.sp(24)),

          // Overall progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall Progress',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: context.responsive.sp(12),
                ),
              ),
              Text(
                '$totalPagesRead / $totalPages pages',
                style: TextStyle(
                  color: const Color(0xFFB062FF),
                  fontSize: context.responsive.sp(12),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: context.responsive.sp(8)),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: context.responsive.sp(8),
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFB062FF)),
            ),
          ),
          SizedBox(height: context.responsive.sp(4)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$progress% complete',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: context.responsive.sp(11)),
              ),
              Text(
                isBookDone ? '🏁 Finished' : '$daysRemaining sessions left',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: context.responsive.sp(11)),
              ),
            ],
          ),

          SizedBox(height: context.responsive.sp(20)),

          // Stats row: 3 chips
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  icon: Icons.menu_book_rounded,
                  label: '$pagesReadToday pages',
                  sublabel: 'read today',
                  color: const Color(0xFFB062FF),
                ),
              ),
              SizedBox(width: context.responsive.wp(8)),
              Expanded(
                child: _StatChip(
                  icon: Icons.auto_stories_rounded,
                  label: '$totalPagesRead pages',
                  sublabel: 'total read',
                  color: const Color(0xFF3CDFB0),
                ),
              ),
              SizedBox(width: context.responsive.wp(8)),
              Expanded(
                child: _StatChip(
                  icon: Icons.event_rounded,
                  label: isBookDone ? 'Done!' : 'Day $nextDay',
                  sublabel: isBookDone ? 'complete' : 'of $totalDays',
                  color: Colors.white70,
                ),
              ),
            ],
          ),

          SizedBox(height: context.responsive.sp(24)),

          // Primary CTA
          _ActionButton(
            label: isBookDone ? 'Go to Library' : 'Back to Home',
            icon: isBookDone
                ? Icons.library_books_rounded
                : Icons.home_rounded,
            gradient: isBookDone
                ? const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFF8C00)])
                : const LinearGradient(
                    colors: [Color(0xFF9146FF), Color(0xFFB062FF)]),
            onTap: () => context.go('/home'),
          ),

          SizedBox(height: context.responsive.sp(12)),

          if (!isBookDone)
            GestureDetector(
              onTap: () => context.push('/chapters/$bookId'),
              child: Text(
                'View chapter list',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: context.responsive.sp(13),
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sublabel;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    this.sublabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.responsive.wp(12),
        vertical: context.responsive.sp(10),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(context.responsive.sp(12)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: context.responsive.sp(14)),
          SizedBox(width: context.responsive.wp(6)),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: context.responsive.sp(12),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (sublabel != null) ...[
                  SizedBox(height: context.responsive.sp(2)),
                  Text(
                    sublabel!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: context.responsive.sp(11),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Gradient? gradient;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: context.responsive.sp(14)),
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? Colors.white : null,
          borderRadius: BorderRadius.circular(context.responsive.sp(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: gradient != null ? Colors.white : const Color(0xFF0F1626),
                size: context.responsive.sp(18)),
            SizedBox(width: context.responsive.wp(8)),
            Text(
              label,
              style: TextStyle(
                color: gradient != null ? Colors.white : const Color(0xFF0F1626),
                fontSize: context.responsive.sp(14),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
