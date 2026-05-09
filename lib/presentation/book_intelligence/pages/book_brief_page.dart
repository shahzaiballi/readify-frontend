import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/intelligence_providers.dart';

class BookBriefPage extends ConsumerWidget {
  final String bookId;

  const BookBriefPage({super.key, required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final briefAsync = ref.watch(bookBriefProvider(bookId));

    return Scaffold(
      backgroundColor: const Color(0xFF0F1626),
      appBar: AppBar(
        title: const Text('The Book Brief'),
        backgroundColor: const Color(0xFF0F1626),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: briefAsync.when(
        data: (brief) {
          if (brief == null) {
            return _buildGeneratingState();
          }
          return _buildBriefContent(brief);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
      ),
    );
  }

  Widget _buildGeneratingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.blueAccent),
          SizedBox(height: 24),
          Text(
            'Generating Book Brief...',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'This report is generated once and cached forever.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBriefContent(BookBrief brief) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSection('What it is about', brief.whatItsAbout, Icons.info_outline_rounded),
        const SizedBox(height: 24),
        _buildSection('Who it is for', brief.whoItsFor, Icons.group_rounded),
        const SizedBox(height: 24),
        _buildSection('Core Argument', brief.coreArgument, Icons.lightbulb_outline_rounded),
        const SizedBox(height: 24),
        
        // Top 5 Ideas
        Row(
          children: [
            const Icon(Icons.format_list_numbered_rounded, color: Colors.blueAccent),
            const SizedBox(width: 8),
            const Text('Top 5 Ideas', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        ...brief.top5Ideas.map((idea) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('•', style: TextStyle(color: Colors.blueAccent, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(child: Text(idea, style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5))),
            ],
          ),
        )).toList(),
        
        const SizedBox(height: 24),
        _buildSection('The Verdict', brief.verdict, Icons.gavel_rounded),
      ],
    );
  }

  Widget _buildSection(String title, String content, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E233D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(content, style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5)),
        ],
      ),
    );
  }
}
