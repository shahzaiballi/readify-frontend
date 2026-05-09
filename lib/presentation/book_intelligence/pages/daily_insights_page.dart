import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/intelligence_providers.dart';

class DailyInsightsPage extends ConsumerWidget {
  final String bookId;

  const DailyInsightsPage({super.key, required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(dailyInsightsProvider(bookId));

    return Scaffold(
      backgroundColor: const Color(0xFF0F1626),
      appBar: AppBar(
        title: const Text('Daily Insights'),
        backgroundColor: const Color(0xFF0F1626),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: insightsAsync.when(
        data: (insights) {
          if (insights == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.orangeAccent),
                  SizedBox(height: 24),
                  Text(
                    'Generating Today\'s Insights...',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This happens once per day.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildInsightCard(
                'Morning Hook',
                '7:00 AM',
                insights.morningHook,
                Icons.wb_sunny_rounded,
                Colors.orangeAccent,
              ),
              const SizedBox(height: 16),
              _buildInsightCard(
                'Midday Concept',
                '12:00 PM',
                insights.middayConcept,
                Icons.lightbulb_rounded,
                Colors.amberAccent,
              ),
              const SizedBox(height: 16),
              _buildInsightCard(
                'Afternoon Story',
                '3:00 PM',
                insights.afternoonStory,
                Icons.auto_stories_rounded,
                Colors.deepOrangeAccent,
              ),
              const SizedBox(height: 16),
              _buildInsightCard(
                'Evening Recap',
                '8:00 PM',
                insights.eveningRecap,
                Icons.nights_stay_rounded,
                Colors.indigoAccent,
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
      ),
    );
  }

  Widget _buildInsightCard(String title, String time, String content, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E233D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(time, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(content, style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5)),
        ],
      ),
    );
  }
}
