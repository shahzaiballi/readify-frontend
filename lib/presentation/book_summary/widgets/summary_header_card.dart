import 'package:flutter/material.dart';
import '../../../../domain/entities/book_detail_entity.dart';
import '../../../../core/utils/responsive_utils.dart';

class SummaryHeaderCard extends StatelessWidget {
  final BookDetailEntity book;

  const SummaryHeaderCard({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Container(
       padding: EdgeInsets.all(context.responsive.sp(20)),
       decoration: BoxDecoration(
          color: const Color(0xFF1E2A4F),
          borderRadius: BorderRadius.circular(context.responsive.sp(16)),
          gradient: const LinearGradient(
             colors: [Color(0xFF281E4B), Color(0xFF161E3A)], // Very subtle dark purple to navy gradient mimicking Figma
             begin: Alignment.topLeft,
             end: Alignment.bottomRight,
          )
       ),
       child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text('Book Overview', style: TextStyle(color: Colors.white, fontSize: context.responsive.sp(15), fontWeight: FontWeight.bold)),
             SizedBox(height: context.responsive.sp(12)),
             Text(
                book.description,
                style: TextStyle(color: Colors.white70, fontSize: context.responsive.sp(13), height: 1.4),
             ),
             SizedBox(height: context.responsive.sp(20)),
             Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   _buildStatBlock('${book.totalChapters}', 'Chapters', context),
                   _buildStatBlock('~${book.totalChapters * 3}', 'Min Read', context),
                   _buildStatBlock('${book.progressPercent}%', 'Complete', context),
                ],
             )
          ],
       ),
    );
  }

  Widget _buildStatBlock(String value, String label, BuildContext context) {
     return Container(
        padding: EdgeInsets.symmetric(horizontal: context.responsive.wp(16), vertical: context.responsive.sp(12)),
        decoration: BoxDecoration(
           color: const Color(0xFF0F1626).withValues(alpha: 0.5),
           borderRadius: BorderRadius.circular(context.responsive.sp(12)),
        ),
        child: Column(
           children: [
              Text(value, style: TextStyle(color: Colors.white, fontSize: context.responsive.sp(14), fontWeight: FontWeight.bold)),
              SizedBox(height: context.responsive.sp(4)),
              Text(label, style: TextStyle(color: Colors.white54, fontSize: context.responsive.sp(10))),
           ],
        ),
     );
  }
}

