import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/network/api_client.dart';
import '../providers/intelligence_providers.dart';

class AskYourBookPage extends ConsumerStatefulWidget {
  final String bookId;

  const AskYourBookPage({super.key, required this.bookId});

  @override
  ConsumerState<AskYourBookPage> createState() => _AskYourBookPageState();
}

class _AskYourBookPageState extends ConsumerState<AskYourBookPage> {
  final TextEditingController _ctrl = TextEditingController();
  bool _isAsking = false;

  Future<void> _askQuestion() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _isAsking = true);

    try {
      await ApiClient.instance.post(
        '/api/v1/intelligence/books/${widget.bookId}/qa/',
        body: {'question': text},
      );
      _ctrl.clear();
      ref.invalidate(qaHistoryProvider(widget.bookId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isAsking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(qaHistoryProvider(widget.bookId));

    return Scaffold(
      backgroundColor: const Color(0xFF0F1626),
      appBar: AppBar(
        title: const Text('Ask Your Book'),
        backgroundColor: const Color(0xFF0F1626),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: historyAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'Ask any question about the book.\nThe AI will find the answer in the text.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Question (User)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8, left: 40),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.withOpacity(0.2),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                              ),
                            ),
                            child: Text(msg.question, style: const TextStyle(color: Colors.white, fontSize: 15)),
                          ),
                        ),
                        // Answer (AI)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 24, right: 40),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E233D),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                              border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                            ),
                            child: Text(msg.answer, style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5)),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
            ),
          ),
          
          // Input Field
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1A1F36),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Ask something...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xFF0F1626),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      onSubmitted: (_) => _askQuestion(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _isAsking ? null : _askQuestion,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                      child: _isAsking
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : const Icon(Icons.send_rounded, color: Colors.black, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
