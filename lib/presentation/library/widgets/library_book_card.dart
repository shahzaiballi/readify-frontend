// ENHANCED UI: Premium library book card with animated interactions,
// polished progress display, and smooth press feedback
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/library_book_entity.dart';
import '../../../../core/utils/responsive_utils.dart';
import 'package:go_router/go_router.dart';
import '../controllers/library_state_provider.dart';

class LibraryBookCard extends ConsumerStatefulWidget {
  final LibraryBookEntity book;

  const LibraryBookCard({super.key, required this.book});

  @override
  ConsumerState<LibraryBookCard> createState() => _LibraryBookCardState();
}

class _LibraryBookCardState extends ConsumerState<LibraryBookCard>
    with SingleTickerProviderStateMixin {
  // ENHANCED UI: Press animation
  late AnimationController _pressCtrl;
  late Animation<double> _scale;
  bool _imageLoaded = false;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.975).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite =
        ref.watch(favoriteBooksProvider).contains(widget.book.id);

    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        context.push('/book_detail/${widget.book.id}');
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: context.responsive.wp(20),
            vertical: context.responsive.sp(7),
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF161B2E),
            borderRadius:
                BorderRadius.circular(context.responsive.sp(20)),
            border: Border.all(
              color: Colors.white.withOpacity(0.06),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(context.responsive.sp(14)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ENHANCED UI: Book cover with shimmer loader
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(context.responsive.sp(12)),
                  child: Stack(
                    children: [
                      if (!_imageLoaded)
                        _ShimmerBox(
                          width: context.responsive.wp(68),
                          height: context.responsive.sp(102),
                        ),
                      Image.network(
                        widget.book.imageUrl,
                        height: context.responsive.sp(102),
                        width: context.responsive.wp(68),
                        fit: BoxFit.cover,
                        frameBuilder: (_, child, frame, __) {
                          if (frame != null && !_imageLoaded) {
                            WidgetsBinding.instance.addPostFrameCallback(
                                (_) =>
                                    setState(() => _imageLoaded = true));
                          }
                          return AnimatedOpacity(
                            opacity: frame == null ? 0 : 1,
                            duration: const Duration(milliseconds: 400),
                            child: child,
                          );
                        },
                        errorBuilder: (_, __, ___) => Container(
                          height: context.responsive.sp(102),
                          width: context.responsive.wp(68),
                          color: const Color(0xFF1E233D),
                          child: Icon(Icons.book,
                              color: Colors.white24,
                              size: context.responsive.sp(28)),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: context.responsive.wp(14)),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row with action buttons
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.book.title,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: context.responsive.sp(15),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.2,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: context.responsive.sp(3)),
                                Text(
                                  widget.book.author,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.45),
                                    fontSize: context.responsive.sp(12),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // ENHANCED UI: Action buttons
                          Row(
                            children: [
                              // ENHANCED UI: Animated favorite button
                              GestureDetector(
                                onTap: () => ref
                                    .read(favoriteBooksProvider.notifier)
                                    .toggleFavorite(widget.book.id),
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 250),
                                  padding: EdgeInsets.all(
                                      context.responsive.sp(7)),
                                  decoration: BoxDecoration(
                                    color: isFavorite
                                        ? Colors.redAccent.withOpacity(0.15)
                                        : Colors.white.withOpacity(0.05),
                                    shape: BoxShape.circle,
                                  ),
                                  child: AnimatedSwitcher(
                                    duration:
                                        const Duration(milliseconds: 250),
                                    transitionBuilder: (child, anim) =>
                                        ScaleTransition(
                                            scale: anim, child: child),
                                    child: Icon(
                                      isFavorite
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                      key: ValueKey(isFavorite),
                                      color: isFavorite
                                          ? Colors.redAccent
                                          : Colors.white38,
                                      size: context.responsive.sp(18),
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(width: context.responsive.wp(6)),

                              GestureDetector(
                                onTap: () =>
                                    _showDeleteConfirm(context, ref),
                                child: Container(
                                  padding: EdgeInsets.all(
                                      context.responsive.sp(7)),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.white30,
                                    size: context.responsive.sp(18),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      SizedBox(height: context.responsive.sp(14)),

                      // ENHANCED UI: Status badge
                      _StatusBadge(status: widget.book.status),

                      SizedBox(height: context.responsive.sp(10)),

                      // ENHANCED UI: Enhanced progress bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: context.responsive.sp(11),
                            ),
                          ),
                          Text(
                            '${widget.book.progressPercent}%',
                            style: TextStyle(
                              color: const Color(0xFFB062FF),
                              fontSize: context.responsive.sp(11),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: context.responsive.sp(6)),

                      // ENHANCED UI: Gradient progress bar
                      Stack(
                        children: [
                          Container(
                            height: context.responsive.sp(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor:
                                widget.book.progressPercent / 100,
                            child: Container(
                              height: context.responsive.sp(4),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [
                                  Color(0xFFB062FF),
                                  Color(0xFF7B2FFF),
                                ]),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFB062FF)
                                        .withOpacity(0.4),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: context.responsive.sp(10)),

                      // ENHANCED UI: Continue button
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => context
                              .push('/book_detail/${widget.book.id}'),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.responsive.wp(14),
                              vertical: context.responsive.sp(6),
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF9146FF), Color(0xFF3861FB)],
                              ),
                              borderRadius: BorderRadius.circular(
                                  context.responsive.sp(20)),
                            ),
                            child: Text(
                              'Continue',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: context.responsive.sp(11),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: EdgeInsets.all(context.responsive.wp(16)),
        padding: EdgeInsets.all(context.responsive.sp(24)),
        decoration: BoxDecoration(
          color: const Color(0xFF1E233D),
          borderRadius:
              BorderRadius.circular(context.responsive.sp(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: context.responsive.sp(20)),
            Icon(Icons.delete_forever_rounded,
                color: Colors.redAccent, size: context.responsive.sp(36)),
            SizedBox(height: context.responsive.sp(16)),
            Text(
              'Remove Book?',
              style: TextStyle(
                color: Colors.white,
                fontSize: context.responsive.sp(18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: context.responsive.sp(8)),
            Text(
              'This will remove "${widget.book.title}" from your library.',
              style: TextStyle(
                  color: Colors.white54,
                  fontSize: context.responsive.sp(13)),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.responsive.sp(24)),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          vertical: context.responsive.sp(14)),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(
                            context.responsive.sp(14)),
                      ),
                      child: Text('Cancel',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                            fontSize: context.responsive.sp(14),
                          )),
                    ),
                  ),
                ),
                SizedBox(width: context.responsive.wp(12)),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      ref
                          .read(deletedBooksProvider.notifier)
                          .deleteBook(widget.book.id);
                      Navigator.of(ctx).pop();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          vertical: context.responsive.sp(14)),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(
                            context.responsive.sp(14)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent.withOpacity(0.3),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Text('Remove',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: context.responsive.sp(14),
                          )),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ENHANCED UI: Status badge widget
class _StatusBadge extends StatelessWidget {
  final LibraryStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case LibraryStatus.inProgress:
        color = const Color(0xFF2196F3);
        label = 'In Progress';
        icon = Icons.auto_stories_rounded;
        break;
      case LibraryStatus.completed:
        color = Colors.greenAccent;
        label = 'Completed';
        icon = Icons.check_circle_rounded;
        break;
      case LibraryStatus.notStarted:
        color = Colors.white38;
        label = 'Not Started';
        icon = Icons.bookmark_border_rounded;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.responsive.wp(8),
        vertical: context.responsive.sp(3),
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(context.responsive.sp(6)),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: context.responsive.sp(10)),
          SizedBox(width: context.responsive.wp(4)),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: context.responsive.sp(10),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ENHANCED UI: Shimmer placeholder
class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  const _ShimmerBox({required this.width, required this.height});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
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
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
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
