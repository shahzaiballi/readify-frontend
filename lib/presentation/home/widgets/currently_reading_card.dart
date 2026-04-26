import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/user_stats_entity.dart';
import '../../../../core/utils/responsive_utils.dart';
import 'package:go_router/go_router.dart';
import '../../profile/controllers/reading_plan_controller.dart';

class CurrentlyReadingCard extends ConsumerStatefulWidget {
  final UserProgressEntity progress;

  const CurrentlyReadingCard({super.key, required this.progress});

  @override
  ConsumerState<CurrentlyReadingCard> createState() =>
      _CurrentlyReadingCardState();
}

class _CurrentlyReadingCardState extends ConsumerState<CurrentlyReadingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  /// Navigate to the reading screen using the real chapter / chunk from the
  /// progress entity. Falls back gracefully when they aren't available yet.
  void _continueReading(BuildContext context) {
    final chapterId = widget.progress.currentChapterId;
    if (chapterId == null || chapterId.isEmpty) {
      // No chapter data yet — go to the chapter list so the user can pick one
      context.push('/chapters/${widget.progress.bookId}');
      return;
    }

    context.push(
      '/read/${widget.progress.bookId}/$chapterId',
      extra: {'initialChunkIndex': widget.progress.currentChunkIndex},
    );
  }

  @override
  Widget build(BuildContext context) {
    final readingPlan = ref.watch(readingPlanProvider);
    final int estimatedDaysLeft =
        ((100 - widget.progress.progressPercent) * 2 /
                readingPlan.dailyMinutes)
            .ceil()
            .clamp(1, 100);

    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) => _pressController.reverse(),
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: context.responsive.wp(20)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.responsive.sp(24)),
            gradient: const LinearGradient(
              colors: [Color(0xFF2D1B52), Color(0xFF1A2340), Color(0xFF0F1A33)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB062FF).withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
                spreadRadius: -5,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative glow orb
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: context.responsive.sp(120),
                  height: context.responsive.sp(120),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFB062FF).withOpacity(0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.all(context.responsive.sp(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFB062FF),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: context.responsive.wp(8)),
                        Text(
                          'CURRENTLY READING',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: context.responsive.sp(10),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: context.responsive.sp(16)),

                    // Book info row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Book cover
                        Hero(
                          tag: 'book-cover-${widget.progress.bookId}',
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                  context.responsive.sp(12)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  context.responsive.sp(12)),
                              child: widget.progress.imageUrl.isNotEmpty
                                  ? Image.network(
                                      widget.progress.imageUrl,
                                      height: context.responsive.sp(90),
                                      width: context.responsive.sp(62),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _placeholderCover(context),
                                    )
                                  : _placeholderCover(context),
                            ),
                          ),
                        ),

                        SizedBox(width: context.responsive.wp(16)),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.progress.title,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: context.responsive.sp(18),
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.3,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: context.responsive.sp(4)),
                              Text(
                                'by ${widget.progress.author}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: context.responsive.sp(12),
                                ),
                              ),
                              SizedBox(height: context.responsive.sp(16)),

                              // Progress bar
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Progress',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: context.responsive.sp(11),
                                    ),
                                  ),
                                  Text(
                                    '${widget.progress.progressPercent}%',
                                    style: TextStyle(
                                      color: const Color(0xFFB062FF),
                                      fontSize: context.responsive.sp(11),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: context.responsive.sp(6)),
                              Stack(
                                children: [
                                  Container(
                                    height: context.responsive.sp(5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: widget.progress
                                            .progressPercent /
                                        100,
                                    child: Container(
                                      height: context.responsive.sp(5),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFB062FF),
                                            Color(0xFF7B2FFF),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFB062FF)
                                                .withOpacity(0.5),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: context.responsive.sp(8)),
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    color:
                                        Colors.greenAccent.withOpacity(0.8),
                                    size: context.responsive.sp(12),
                                  ),
                                  SizedBox(width: context.responsive.wp(4)),
                                  Text(
                                    '$estimatedDaysLeft days left',
                                    style: TextStyle(
                                      color: Colors.greenAccent.withOpacity(
                                          0.8),
                                      fontSize: context.responsive.sp(11),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: context.responsive.sp(20)),

                    // Continue reading — uses real chapter & chunk
                    _PremiumButton(
                      label: 'Continue Reading',
                      icon: Icons.play_arrow_rounded,
                      onTap: () => _continueReading(context),
                    ),

                    SizedBox(height: context.responsive.sp(12)),

                    // Secondary actions
                    Row(
                      children: [
                        Expanded(
                          child: _GhostButton(
                            label: 'Flashcards',
                            icon: Icons.style_outlined,
                            onTap: () => context.push(
                                '/flashcards/${widget.progress.bookId}'),
                          ),
                        ),
                        SizedBox(width: context.responsive.wp(12)),
                        Expanded(
                          child: _GhostButton(
                            label: 'Summary',
                            icon: Icons.description_outlined,
                            onTap: () => context.push(
                                '/book_summary/${widget.progress.bookId}'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderCover(BuildContext context) {
    return Container(
      height: context.responsive.sp(90),
      width: context.responsive.sp(62),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(context.responsive.sp(12)),
      ),
      child: Icon(Icons.book, color: Colors.white30,
          size: context.responsive.sp(24)),
    );
  }
}

// ── Shared button widgets ─────────────────────────────────────────────────────

class _PremiumButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PremiumButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<_PremiumButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: double.infinity,
          padding:
              EdgeInsets.symmetric(vertical: context.responsive.sp(14)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(context.responsive.sp(14)),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon,
                  color: const Color(0xFF0F1626),
                  size: context.responsive.sp(20)),
              SizedBox(width: context.responsive.wp(8)),
              Text(
                widget.label,
                style: TextStyle(
                  color: const Color(0xFF0F1626),
                  fontSize: context.responsive.sp(14),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _GhostButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            EdgeInsets.symmetric(vertical: context.responsive.sp(12)),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius:
              BorderRadius.circular(context.responsive.sp(12)),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: Colors.white.withOpacity(0.7),
                size: context.responsive.sp(15)),
            SizedBox(width: context.responsive.wp(6)),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: context.responsive.sp(12),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}