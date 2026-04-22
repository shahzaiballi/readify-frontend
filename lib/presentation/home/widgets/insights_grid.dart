// ENHANCED UI: Premium insights grid with animated counters,
// glowing icon containers, and polished card design
import 'package:flutter/material.dart';
import '../../../../domain/entities/user_stats_entity.dart';
import '../../../../core/utils/responsive_utils.dart';

class InsightsGrid extends StatefulWidget {
  final InsightsEntity insights;

  const InsightsGrid({super.key, required this.insights});

  @override
  State<InsightsGrid> createState() => _InsightsGridState();
}

class _InsightsGridState extends State<InsightsGrid>
    with SingleTickerProviderStateMixin {
  // ENHANCED UI: Stagger animation for cards
  late AnimationController _staggerCtrl;
  late List<Animation<double>> _cardAnims;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _cardAnims = List.generate(3, (i) {
      final start = i * 0.15;
      final end = start + 0.6;
      return CurvedAnimation(
        parent: _staggerCtrl,
        curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeOut),
      );
    });

    _staggerCtrl.forward();
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ENHANCED UI: Section header matching design system
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: context.responsive.wp(20)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Insights',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: context.responsive.sp(18),
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: const Color(0xFFB062FF),
                    fontSize: context.responsive.sp(13),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: context.responsive.sp(16)),

        // ENHANCED UI: Animated insight cards
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: context.responsive.wp(20)),
          child: Row(
            children: [
              Expanded(
                child: _buildInsightCard(
                  context,
                  animation: _cardAnims[0],
                  icon: Icons.style_rounded,
                  iconColor: const Color(0xFFB062FF),
                  iconBg: const Color(0xFFB062FF),
                  value: widget.insights.cardsDue.toString(),
                  label: 'Cards Due',
                ),
              ),
              SizedBox(width: context.responsive.wp(12)),
              Expanded(
                child: _buildInsightCard(
                  context,
                  animation: _cardAnims[1],
                  icon: Icons.local_fire_department_rounded,
                  iconColor: const Color(0xFF2196F3),
                  iconBg: const Color(0xFF2196F3),
                  value: '${widget.insights.readTodayMinutes}m',
                  label: 'Read Today',
                ),
              ),
              SizedBox(width: context.responsive.wp(12)),
              Expanded(
                child: _buildInsightCard(
                  context,
                  animation: _cardAnims[2],
                  icon: Icons.bolt_rounded,
                  iconColor: const Color(0xFF00E676),
                  iconBg: const Color(0xFF00E676),
                  value: '${widget.insights.dayStreak}',
                  label: 'Day Streak',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard(
    BuildContext context, {
    required Animation<double> animation,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String value,
    required String label,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, child) => Opacity(
        opacity: animation.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - animation.value.clamp(0.0, 1.0))),
          child: child,
        ),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: context.responsive.sp(18),
          horizontal: context.responsive.sp(8),
        ),
        decoration: BoxDecoration(
          // ENHANCED UI: Subtle gradient for depth
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1E233D),
              const Color(0xFF191E35),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius:
              BorderRadius.circular(context.responsive.sp(18)),
          border: Border.all(
            color: Colors.white.withOpacity(0.06),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // ENHANCED UI: Icon with glow effect
            Container(
              padding: EdgeInsets.all(context.responsive.sp(10)),
              decoration: BoxDecoration(
                color: iconBg.withOpacity(0.15),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: iconBg.withOpacity(0.2),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(icon,
                  color: iconColor,
                  size: context.responsive.sp(20)),
            ),
            SizedBox(height: context.responsive.sp(12)),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: context.responsive.sp(20),
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: context.responsive.sp(3)),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: context.responsive.sp(10),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
