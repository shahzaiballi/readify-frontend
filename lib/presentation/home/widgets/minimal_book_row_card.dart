// ENHANCED UI: Premium book row card with animated press states,
// beautiful image loading, and polished typography
import 'package:flutter/material.dart';
import '../../../../domain/entities/book_entity.dart';
import '../../../../core/utils/responsive_utils.dart';
import 'package:go_router/go_router.dart';

class MinimalBookRowCard extends StatefulWidget {
  final BookEntity book;

  const MinimalBookRowCard({super.key, required this.book});

  @override
  State<MinimalBookRowCard> createState() => _MinimalBookRowCardState();
}

class _MinimalBookRowCardState extends State<MinimalBookRowCard>
    with SingleTickerProviderStateMixin {
  // ENHANCED UI: Tap animation
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
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
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
            vertical: context.responsive.sp(6),
          ),
          padding: EdgeInsets.all(context.responsive.sp(14)),
          decoration: BoxDecoration(
            color: const Color(0xFF161B2E),
            borderRadius:
                BorderRadius.circular(context.responsive.sp(18)),
            border: Border.all(
              color: Colors.white.withOpacity(0.06),
              width: 1,
            ),
            // ENHANCED UI: Subtle shadow for depth
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // ENHANCED UI: Book cover with shimmer placeholder
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(context.responsive.sp(10)),
                child: Stack(
                  children: [
                    // Shimmer placeholder
                    if (!_imageLoaded)
                      _ShimmerBox(
                        width: context.responsive.wp(60),
                        height: context.responsive.sp(88),
                      ),
                    Image.network(
                      widget.book.imageUrl,
                      height: context.responsive.sp(88),
                      width: context.responsive.wp(60),
                      fit: BoxFit.cover,
                      frameBuilder:
                          (context, child, frame, wasSynchronouslyLoaded) {
                        if (frame != null && !_imageLoaded) {
                          WidgetsBinding.instance.addPostFrameCallback(
                              (_) => setState(() => _imageLoaded = true));
                        }
                        return AnimatedOpacity(
                          opacity: frame == null ? 0 : 1,
                          duration: const Duration(milliseconds: 400),
                          child: child,
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        height: context.responsive.sp(88),
                        width: context.responsive.wp(60),
                        color: const Color(0xFF1E233D),
                        child: Icon(Icons.book,
                            color: Colors.white24,
                            size: context.responsive.sp(24)),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: context.responsive.wp(16)),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ENHANCED UI: Title with better typography
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
                    SizedBox(height: context.responsive.sp(5)),
                    Text(
                      widget.book.author,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: context.responsive.sp(12),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: context.responsive.sp(10)),

                    // ENHANCED UI: Polished stats row
                    Row(
                      children: [
                        // Star rating with glow
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.responsive.wp(8),
                            vertical: context.responsive.sp(3),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(
                                context.responsive.sp(6)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.star_rounded,
                                  color: Colors.amber,
                                  size: context.responsive.sp(12)),
                              SizedBox(width: context.responsive.wp(3)),
                              Text(
                                '${widget.book.rating}',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: context.responsive.sp(11),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(width: context.responsive.wp(8)),

                        // Readers count
                        Row(
                          children: [
                            Icon(Icons.people_outline,
                                color: Colors.white30,
                                size: context.responsive.sp(12)),
                            SizedBox(width: context.responsive.wp(3)),
                            Text(
                              '${widget.book.readersCount}',
                              style: TextStyle(
                                color: Colors.white30,
                                fontSize: context.responsive.sp(11),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    SizedBox(height: context.responsive.sp(8)),

                    // ENHANCED UI: Category pill
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.responsive.wp(10),
                        vertical: context.responsive.sp(3),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB062FF).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(
                            context.responsive.sp(20)),
                        border: Border.all(
                          color: const Color(0xFFB062FF).withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        widget.book.category,
                        style: TextStyle(
                          color: const Color(0xFFB062FF),
                          fontSize: context.responsive.sp(10),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ENHANCED UI: Chevron indicator
              Padding(
                padding:
                    EdgeInsets.only(left: context.responsive.wp(8)),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withOpacity(0.2),
                  size: context.responsive.sp(20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ENHANCED UI: Shimmer placeholder box
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
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
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
            colors: const [
              Color(0xFF1A1F36),
              Color(0xFF232840),
              Color(0xFF1A1F36),
            ],
          ),
        ),
      ),
    );
  }
}
