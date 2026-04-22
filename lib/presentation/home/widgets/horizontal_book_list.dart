// ENHANCED UI: Premium horizontal book list with beautiful cards,
// animated badges, and smooth scroll behavior
import 'package:flutter/material.dart';
import '../../../../domain/entities/book_entity.dart';
import '../../../../core/utils/responsive_utils.dart';
import 'package:go_router/go_router.dart';

class HorizontalBookList extends StatelessWidget {
  final String title;
  final List<BookEntity> books;
  final bool showBadges;
  final bool showsAuthor;
  final VoidCallback? onViewAll;

  const HorizontalBookList({
    super.key,
    required this.title,
    required this.books,
    this.showBadges = false,
    this.showsAuthor = true,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ENHANCED UI: Section header
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: context.responsive.wp(20)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.responsive.sp(18),
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (showBadges) ...[
                    SizedBox(width: context.responsive.wp(8)),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.responsive.wp(8),
                        vertical: context.responsive.sp(3),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(
                            context.responsive.sp(8)),
                        border: Border.all(
                            color: Colors.orangeAccent.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.trending_up_rounded,
                              color: Colors.orangeAccent,
                              size: context.responsive.sp(12)),
                          SizedBox(width: context.responsive.wp(3)),
                          Text(
                            'HOT',
                            style: TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: context.responsive.sp(9),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              if (onViewAll != null)
                GestureDetector(
                  onTap: onViewAll,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.responsive.wp(12),
                      vertical: context.responsive.sp(6),
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB062FF).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(
                          context.responsive.sp(20)),
                      border: Border.all(
                        color: const Color(0xFFB062FF).withOpacity(0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'View All',
                          style: TextStyle(
                            color: const Color(0xFFB062FF),
                            fontSize: context.responsive.sp(12),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: context.responsive.wp(3)),
                        Icon(Icons.arrow_forward_ios_rounded,
                            color: const Color(0xFFB062FF),
                            size: context.responsive.sp(10)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        SizedBox(height: context.responsive.sp(14)),

        // ENHANCED UI: Horizontal scroll with premium cards
        SizedBox(
          height: context.responsive.sp(240),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
                horizontal: context.responsive.wp(16)),
            itemCount: books.length,
            itemBuilder: (context, index) {
              return _HorizontalBookCard(
                book: books[index],
                showBadge: showBadges,
                showAuthor: showsAuthor,
                index: index,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HorizontalBookCard extends StatefulWidget {
  final BookEntity book;
  final bool showBadge;
  final bool showAuthor;
  final int index;

  const _HorizontalBookCard({
    required this.book,
    required this.showBadge,
    required this.showAuthor,
    required this.index,
  });

  @override
  State<_HorizontalBookCard> createState() => _HorizontalBookCardState();
}

class _HorizontalBookCardState extends State<_HorizontalBookCard>
    with SingleTickerProviderStateMixin {
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
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
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
          width: context.responsive.wp(140),
          margin: EdgeInsets.symmetric(
              horizontal: context.responsive.wp(6)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ENHANCED UI: Book cover with badge and shadow
              Expanded(
                child: Stack(
                  children: [
                    // Shimmer placeholder
                    if (!_imageLoaded)
                      _ShimmerBox(
                        width: context.responsive.wp(140),
                        height: double.infinity,
                        borderRadius: context.responsive.sp(14),
                      ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                          context.responsive.sp(14)),
                      child: Image.network(
                        widget.book.imageUrl,
                        width: double.infinity,
                        height: double.infinity,
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
                          color: const Color(0xFF1E233D),
                          child: Icon(Icons.book,
                              color: Colors.white24,
                              size: context.responsive.sp(28)),
                        ),
                      ),
                    ),

                    // ENHANCED UI: Gradient overlay at bottom of cover
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: context.responsive.sp(60),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(
                                context.responsive.sp(14)),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.6),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ENHANCED UI: Ranking badge
                    if (widget.showBadge && widget.book.badge != null)
                      Positioned(
                        top: context.responsive.sp(8),
                        left: context.responsive.sp(8),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.responsive.wp(8),
                            vertical: context.responsive.sp(3),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange,
                            borderRadius: BorderRadius.circular(
                                context.responsive.sp(6)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.deepOrange.withOpacity(0.4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Text(
                            widget.book.badge!,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: context.responsive.sp(10),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                    // ENHANCED UI: Audio badge
                    if (widget.book.hasAudio)
                      Positioned(
                        top: context.responsive.sp(8),
                        right: context.responsive.sp(8),
                        child: Container(
                          padding: EdgeInsets.all(context.responsive.sp(5)),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white24, width: 0.5),
                          ),
                          child: Icon(
                            Icons.headphones_rounded,
                            color: Colors.white,
                            size: context.responsive.sp(12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              SizedBox(height: context.responsive.sp(8)),

              Text(
                widget.book.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: context.responsive.sp(13),
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.1,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              if (widget.showAuthor) ...[
                SizedBox(height: context.responsive.sp(2)),
                Text(
                  widget.book.author,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: context.responsive.sp(11),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ENHANCED UI: Shimmer placeholder
class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    this.borderRadius = 0,
  });

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
          borderRadius: BorderRadius.circular(widget.borderRadius),
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
