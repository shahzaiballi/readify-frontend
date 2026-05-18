import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/book_detail_entity.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../profile/controllers/reading_plan_controller.dart';

class BookStatsRow extends ConsumerWidget {
  final BookDetailEntity book;

  const BookStatsRow({super.key, required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readingPlan = ref.watch(readingPlanProvider);
    
    // Calculate days left: assume 1.5 minutes per page
    final totalMinutesLeft = book.pagesLeft * 1.5;
    final dailyMinutes = readingPlan.dailyMinutes > 0 ? readingPlan.dailyMinutes : 45;
    final daysLeft = (totalMinutesLeft / dailyMinutes).ceil();

    return Row(
      children: [
         Expanded(child: _StatBox(value: book.pagesLeft.toString(), label: 'Pages Left', context: context)),
         SizedBox(width: context.responsive.wp(12)),
         Expanded(child: _StatBox(value: book.flashcardsCount.toString(), label: 'Flashcards', context: context)),
         SizedBox(width: context.responsive.wp(12)),
         Expanded(child: _StatBox(value: '$daysLeft days', label: 'To Finish', context: context)),
      ],
    );
  }

  Widget _StatBox({required String value, required String label, required BuildContext context}) {
     return Container(
       padding: EdgeInsets.symmetric(vertical: context.responsive.sp(16)),
       decoration: BoxDecoration(
          color: const Color(0xFF1E233D),
          borderRadius: BorderRadius.circular(context.responsive.sp(12)),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
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

