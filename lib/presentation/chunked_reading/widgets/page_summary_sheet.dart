import 'package:flutter/material.dart';
import '../../../../data/network/api_client.dart';

class PageSummarySheet extends StatefulWidget {
  final String bookId;
  final String chapterId;
  final String chunkId; // Actually an integer passed as string

  const PageSummarySheet({
    super.key,
    required this.bookId,
    required this.chapterId,
    required this.chunkId,
  });

  @override
  State<PageSummarySheet> createState() => _PageSummarySheetState();
}

class _PageSummarySheetState extends State<PageSummarySheet> {
  bool _isLoading = true;
  String? _summary;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    try {
      final res = await ApiClient.instance.get(
        '/api/v1/books/${widget.bookId}/chapters/${widget.chapterId}/chunks/${widget.chunkId}/summary/',
      );
      if (mounted) {
        setState(() {
          _summary = res['summary'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1E233D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.purpleAccent),
                const SizedBox(width: 8),
                const Text(
                  'Page Summary',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: Colors.purpleAccent),
                ),
              )
            else if (_error != null)
              Center(
                child: Text(
                  'Error: $_error',
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              )
            else
              Text(
                _summary ?? 'No summary available.',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
