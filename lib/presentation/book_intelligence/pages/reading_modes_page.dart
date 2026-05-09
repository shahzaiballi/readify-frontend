import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/intelligence_providers.dart';

class ReadingModesPage extends ConsumerStatefulWidget {
  final String bookId;

  const ReadingModesPage({super.key, required this.bookId});

  @override
  ConsumerState<ReadingModesPage> createState() => _ReadingModesPageState();
}

class _ReadingModesPageState extends ConsumerState<ReadingModesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AIChapter? _selectedChapter;
  final List<String> _modes = ['skim', 'concept', 'deep', 'exam'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chaptersAsync = ref.watch(aiChaptersProvider(widget.bookId));

    return Scaffold(
      backgroundColor: const Color(0xFF0F1626),
      appBar: AppBar(
        title: const Text('Reading Modes'),
        backgroundColor: const Color(0xFF0F1626),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.purpleAccent,
          labelColor: Colors.purpleAccent,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Skim'),
            Tab(text: 'Concept'),
            Tab(text: 'Deep'),
            Tab(text: 'Exam'),
          ],
        ),
      ),
      body: chaptersAsync.when(
        data: (chapters) {
          if (chapters.isEmpty) {
            return const Center(child: Text('No chapters available.', style: TextStyle(color: Colors.white)));
          }

          _selectedChapter ??= chapters.first;

          return Column(
            children: [
              // Chapter Selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: const Color(0xFF1A1F36),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<AIChapter>(
                    value: _selectedChapter,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1E233D),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
                    items: chapters.map((ch) {
                      return DropdownMenuItem(
                        value: ch,
                        child: Text(ch.title, style: const TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedChapter = val);
                    },
                  ),
                ),
              ),

              // Mode Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: _modes.map((mode) {
                    return _ModeContent(
                      bookId: widget.bookId,
                      chapterId: _selectedChapter!.id,
                      mode: mode,
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
      ),
    );
  }
}

class _ModeContent extends ConsumerWidget {
  final String bookId;
  final String chapterId;
  final String mode;

  const _ModeContent({required this.bookId, required this.chapterId, required this.mode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final req = ChapterModeRequest(bookId, chapterId, mode);
    final contentAsync = ref.watch(chapterModeProvider(req));

    return contentAsync.when(
      data: (content) {
        if (content == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.purpleAccent),
                SizedBox(height: 16),
                Text('Generating summary...', style: TextStyle(color: Colors.white)),
              ],
            ),
          );
        }

        return _buildContentForMode(content);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
    );
  }

  Widget _buildContentForMode(Map<String, dynamic> content) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (mode == 'skim') ...[
          _buildCard('The One-Liner', content['one_liner'] ?? '', Icons.flash_on_rounded),
        ] else if (mode == 'concept') ...[
          const Text('Key Concepts', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...?((content['concepts'] as List?)?.map((c) => _buildCard(c['name'], c['description'], Icons.lightbulb_outline_rounded))),
        ] else if (mode == 'deep') ...[
          _buildCard('Overview', content['overview'] ?? '', Icons.menu_book_rounded),
          const SizedBox(height: 16),
          const Text('Key Points', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...?((content['key_points'] as List?)?.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(color: Colors.purpleAccent, fontSize: 18)),
                Expanded(child: Text(p, style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5))),
              ],
            ),
          ))),
          const SizedBox(height: 16),
          _buildCard('Analogy', content['analogy'] ?? '', Icons.compare_arrows_rounded),
          const SizedBox(height: 16),
          _buildCard('Why it matters', content['why_it_matters'] ?? '', Icons.stars_rounded),
        ] else if (mode == 'exam') ...[
          const Text('Practice Questions', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...?((content['qa_pairs'] as List?)?.map((qa) => _buildCard('Q: ${qa['question']}', 'A: ${qa['answer']}', Icons.question_answer_rounded))),
        ]
      ],
    );
  }

  Widget _buildCard(String title, String body, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              Icon(icon, color: Colors.purpleAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 12),
          Text(body, style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5)),
        ],
      ),
    );
  }
}
