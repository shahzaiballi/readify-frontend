import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/today_reading_entity.dart';
import '../../../data/repositories/book_repository_impl.dart';

final _todaySummaryProvider =
    FutureProvider.autoDispose.family<TodaySummaryResult, String>(
  (ref, bookId) => BookRepositoryImpl().getTodaySummary(bookId),
);

class TodaySummarySheet extends ConsumerWidget {
  final String bookId;
  final VoidCallback onSkimComplete;

  const TodaySummarySheet({
    super.key,
    required this.bookId,
    required this.onSkimComplete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(_todaySummaryProvider(bookId));

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF131929),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text('⚡', style: TextStyle(fontSize: 22)),
                SizedBox(width: 8),
                Text(
                  "Today's AI Summary",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFF1E2640), height: 1),

          // Content
          Flexible(
            child: summaryAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFFB062FF)),
                    SizedBox(height: 16),
                    Text(
                      'Generating your summary…',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ],
                ),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.redAccent, size: 36),
                    const SizedBox(height: 12),
                    Text(
                      e.toString().contains('generating') ||
                              e.toString().contains('202')
                          ? 'Your AI summary is being prepared.\nCheck back in a moment!'
                          : 'Could not load summary. Please try again.',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () =>
                          ref.refresh(_todaySummaryProvider(bookId)),
                      child: const Text('Retry',
                          style: TextStyle(color: Color(0xFFB062FF))),
                    ),
                  ],
                ),
              ),
              data: (result) => result.isGenerating
                  ? const Padding(
                      padding: EdgeInsets.all(48),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Color(0xFFB062FF)),
                          SizedBox(height: 16),
                          Text(
                            'Your AI summary is being prepared…',
                            style:
                                TextStyle(color: Colors.white54, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : _SummaryContent(
                      result: result,
                      onDone: onSkimComplete,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryContent extends StatelessWidget {
  final TodaySummaryResult result;
  final VoidCallback onDone;
  const _SummaryContent({required this.result, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...result.summaries.map((s) => _SummaryItem(item: s)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB062FF),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: onDone,
              child: const Text(
                'Done',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final TodaySummaryItem item;
  const _SummaryItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E2640)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ch. ${item.chapterNumber}  ${item.chapterTitle}',
            style: const TextStyle(
              color: Color(0xFFB062FF),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            item.summaryContent,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          if (item.keyTakeaways.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Key Takeaways',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            ...item.keyTakeaways.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ',
                        style: TextStyle(color: Color(0xFFB062FF))),
                    Expanded(
                      child: Text(
                        t,
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

