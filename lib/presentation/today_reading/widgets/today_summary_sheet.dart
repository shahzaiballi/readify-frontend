import 'package:flutter/material.dart';

// AI summary sheet removed — reading screen uses page-based navigation only.
class TodaySummarySheet extends StatelessWidget {
  final String bookId;
  final VoidCallback onSkimComplete;

  const TodaySummarySheet({
    super.key,
    required this.bookId,
    required this.onSkimComplete,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

