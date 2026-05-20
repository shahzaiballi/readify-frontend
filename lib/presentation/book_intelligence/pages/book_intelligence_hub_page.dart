import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/intelligence_providers.dart';

class BookIntelligenceHubPage extends ConsumerWidget {
  final String bookId;

  const BookIntelligenceHubPage({super.key, required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(intelligenceStatusProvider(bookId));

    return Scaffold(
      backgroundColor: const Color(0xFF0F1626),
      appBar: AppBar(
        title: const Text('Book Intelligence'),
        backgroundColor: const Color(0xFF0F1626),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: statusAsync.when(
        data: (status) {
          if (status.status == 'not_started') {
            return _buildNotStartedState(context, ref);
          }
          if (status.status != 'ready' && status.status != 'failed') {
            return _buildProcessingState(context, status.status);
          }
          return _buildHubContent(context, status);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
      ),
    );
  }

  Widget _buildNotStartedState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome_rounded, size: 64, color: Colors.amber.withValues(alpha: 0.8)),
            const SizedBox(height: 24),
            const Text(
              'Unlock Book Intelligence',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Analyze this book to generate smart chapter summaries, get daily insights, and ask questions directly to the book.',
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                ref.read(triggerAnalysisProvider(bookId));
              },
              child: const Text('Analyze Book Now', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingState(BuildContext context, String statusStr) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.amber),
          const SizedBox(height: 24),
          const Text(
            'Analyzing Book...',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Current step: ${statusStr.toUpperCase()}',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 24),
          const Text(
            'This might take a minute depending on the book length.\nYou can safely leave this screen.',
            style: TextStyle(color: Colors.white54, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHubContent(BuildContext context, IntelligenceStatus status) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildActionCard(
          context: context,
          title: 'The Book Brief',
          subtitle: 'A single-page intelligence report summarizing the core arguments and top ideas.',
          icon: Icons.article_rounded,
          color: Colors.blueAccent,
          onTap: () => context.push('/book_intelligence/$bookId/brief'),
        ),
        const SizedBox(height: 16),
        _buildActionCard(
          context: context,
          title: 'Reading Modes',
          subtitle: 'View chapter summaries in Skim, Concept, Deep, or Exam modes.',
          icon: Icons.menu_book_rounded,
          color: Colors.purpleAccent,
          onTap: () => context.push('/book_intelligence/$bookId/modes'),
        ),
        const SizedBox(height: 16),
        _buildActionCard(
          context: context,
          title: 'Ask Your Book',
          subtitle: 'Ask any question and get answers grounded directly in the text.',
          icon: Icons.forum_rounded,
          color: Colors.greenAccent,
          onTap: () => context.push('/book_intelligence/$bookId/qa'),
        ),
        const SizedBox(height: 16),
        _buildActionCard(
          context: context,
          title: 'Daily Insights',
          subtitle: 'Four timed insights pushed to you daily, even on days you don\'t read.',
          icon: Icons.notifications_active_rounded,
          color: Colors.orangeAccent,
          onTap: () => context.push('/book_intelligence/$bookId/notifications'),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E233D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withValues(alpha: 0.3), size: 16),
          ],
        ),
      ),
    );
  }
}
