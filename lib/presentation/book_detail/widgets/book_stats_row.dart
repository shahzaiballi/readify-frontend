import 'package:flutter/material.dart';
import '../../../../domain/entities/book_detail_entity.dart';
import '../../../../core/utils/responsive_utils.dart';

class BookStatsRow extends StatelessWidget {
  final BookDetailEntity book;

  const BookStatsRow({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final daysLabel = book.daysLeftToFinish > 0
        ? '${book.daysLeftToFinish}d'
        : '—';

    return Row(
      children: [
         Expanded(child: _statBox(value: book.pagesLeft.toString(), label: 'Pages Left', context: context)),
         SizedBox(width: context.responsive.wp(12)),
         Expanded(child: _statBox(value: book.flashcardsCount.toString(), label: 'Flashcards', context: context)),
         SizedBox(width: context.responsive.wp(12)),
         Expanded(child: _statBox(value: daysLabel, label: 'To Finish', context: context)),
      ],
    );
  }

  Widget _statBox({required String value, required String label, required BuildContext context}) {
     return Container(
       padding: EdgeInsets.symmetric(vertical: context.responsive.sp(16)),
       decoration: BoxDecoration(
          color: const Color(0xFF1E233D),
          borderRadius: BorderRadius.circular(context.responsive.sp(12)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
       ),
       child: Column(
         children: [
            Text(value, style: TextStyle(color: Colors.white, fontSize: context.responsive.sp(20), fontWeight: FontWeight.bold)),
            SizedBox(height: context.responsive.sp(4)),
            Text(label, style: TextStyle(color: Colors.white54, fontSize: context.responsive.sp(11)), maxLines: 1, overflow: TextOverflow.ellipsis),
         ],
       ),
     );
  }
}

