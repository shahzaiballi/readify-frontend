import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../domain/entities/book_detail_entity.dart';
import '../../../../core/utils/responsive_utils.dart';

class BookDetailHeader extends StatelessWidget {
  final BookDetailEntity book;

  const BookDetailHeader({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Navigation Bar
        Row(
          children: [
            Container(
               decoration: const BoxDecoration(color: Color(0xFF1E233D), shape: BoxShape.circle),
               child: IconButton(
                 icon: Icon(Icons.arrow_back, color: Colors.white70, size: context.responsive.sp(20)),
                 onPressed: () => context.pop(),
               ),
            ),
            SizedBox(width: context.responsive.wp(16)),
            Text('Book Details', style: TextStyle(color: Colors.white, fontSize: context.responsive.sp(18), fontWeight: FontWeight.bold)),
          ],
        ),
        SizedBox(height: context.responsive.sp(32)),

        // Cover and Info Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(context.responsive.sp(12)),
              child: Image.network(
                 book.imageUrl,
                 height: context.responsive.sp(150),
                 width: context.responsive.wp(100),
                 fit: BoxFit.cover,
                 errorBuilder: (context, error, stackTrace) => Container(
                    height: context.responsive.sp(150), width: context.responsive.wp(100), color: Colors.white10),
              )
            ),
            SizedBox(width: context.responsive.wp(24)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                     book.title,
                     style: TextStyle(color: Colors.white, fontSize: context.responsive.sp(22), fontWeight: FontWeight.bold),
                     maxLines: 2,
                     overflow: TextOverflow.ellipsis,
                   ),
                   SizedBox(height: context.responsive.sp(8)),
                   Text(
                     'by ${book.author}',
                     style: TextStyle(color: Colors.white54, fontSize: context.responsive.sp(14)),
                     maxLines: 1,
                     overflow: TextOverflow.ellipsis,
                   ),
                   SizedBox(height: context.responsive.sp(16)),
                   if (book.progressPercent > 0) ...[  
                     Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                           Text('Progress', style: TextStyle(color: Colors.white54, fontSize: context.responsive.sp(12))),
                           Text('${book.progressPercent}%', style: TextStyle(color: const Color(0xFFB062FF), fontSize: context.responsive.sp(12), fontWeight: FontWeight.bold)),
                        ],
                     ),
                     SizedBox(height: context.responsive.sp(8)),
                     ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: book.progressPercent / 100,
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFB062FF)),
                          minHeight: context.responsive.sp(6),
                        ),
                     ),
                     SizedBox(height: context.responsive.sp(12)),
                     Row(
                       children: [
                         Icon(Icons.calendar_today_outlined, color: Colors.white54, size: context.responsive.sp(14)),
                         SizedBox(width: context.responsive.wp(8)),
                         Text('${book.daysLeftToFinish}d left', style: TextStyle(color: Colors.white54, fontSize: context.responsive.sp(12))),
                       ],
                     ),
                   ] else ...[  
                     Wrap(
                       spacing: context.responsive.wp(8),
                       runSpacing: context.responsive.sp(6),
                       children: [
                         _buildChip(context, Icons.menu_book_rounded, '${book.totalChapters} Chapters'),
                         _buildChip(context, Icons.star_rounded, book.rating.toStringAsFixed(1), color: Colors.amber),
                         _buildChip(context, Icons.local_offer_outlined, book.category),
                       ],
                     ),
                   ]
                ],
              ),
            )
          ],
        )
      ],
    );
  }

  Widget _buildChip(BuildContext context, IconData icon, String label, {Color? color}) {
    final c = color ?? const Color(0xFFB062FF);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.responsive.wp(10),
        vertical: context.responsive.sp(5),
      ),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(context.responsive.sp(20)),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: c, size: context.responsive.sp(12)),
          SizedBox(width: context.responsive.wp(5)),
          Text(
            label,
            style: TextStyle(
              color: c,
              fontSize: context.responsive.sp(11),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

