import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class ChunkContentPage extends StatefulWidget {
  final String text;
  final double fontSize;
  final VoidCallback onNextChunk;
  final bool isLastChunk;
  final Color textColor;

  const ChunkContentPage({
    super.key,
    required this.text,
    required this.fontSize,
    required this.onNextChunk,
    this.isLastChunk = false,
    this.textColor = Colors.white,
  });

  @override
  State<ChunkContentPage> createState() => _ChunkContentPageState();
}

class _ChunkContentPageState extends State<ChunkContentPage> {
  bool _isSimplified = false;
  bool _isSimplifying = false;

  // Track whether user has scrolled to the bottom (optional UX hint)
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _triggerSimplify() async {
    setState(() {
      _isSimplifying = true;
    });

    // Simulate AI loading
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isSimplifying = false;
        _isSimplified = !_isSimplified;
      });
    }
  }

  String _getSimplifiedVersion(String original) {
    return "💡 AI Simplified:\n\n${original.split('. ').take(2).join('. ')}... In simple words, the main idea is to focus on quick wins.";
  }

  @override
  Widget build(BuildContext context) {
    final displayText =
        _isSimplified ? _getSimplifiedVersion(widget.text) : widget.text;

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        // AI Control Row
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (_isSimplifying)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFFB062FF)),
              )
            else
              Tooltip(
                message: _isSimplified ? "Show Original" : "AI Simplify",
                child: IconButton(
                  icon: Icon(
                    Icons.auto_awesome,
                    color: _isSimplified
                        ? const Color(0xFFB062FF)
                        : widget.textColor.withOpacity(0.5),
                    size: 20,
                  ),
                  onPressed: _triggerSimplify,
                ),
              ),
          ],
        ),

        // Selectable reading content
        SelectableText(
          displayText,
          textAlign: TextAlign.left,
          style: GoogleFonts.merriweather(
            fontSize: widget.fontSize,
            height: 1.8,
            color: widget.textColor,
          ),
          contextMenuBuilder:
              (BuildContext context, EditableTextState editableTextState) {
            final List<ContextMenuButtonItem> buttonItems = [
              ContextMenuButtonItem(
                label: 'Post to Discussion',
                onPressed: () {
                  final textSelection =
                      editableTextState.textEditingValue.selection;
                  final text = editableTextState.textEditingValue.text
                      .substring(
                        textSelection.start,
                        textSelection.end,
                      );
                  editableTextState.hideToolbar();
                  context.push('/new_discussion', extra: text);
                },
              ),
              ContextMenuButtonItem(
                label: 'Highlight',
                onPressed: () {
                  editableTextState.hideToolbar();
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saved to Highlights!')));
                },
              ),
              ContextMenuButtonItem(
                label: 'Translate',
                onPressed: () {
                  editableTextState.hideToolbar();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Translation arriving soon!')));
                },
              ),
            ];

            buttonItems.addAll(editableTextState.contextMenuButtonItems
                .where((item) => item.type == ContextMenuButtonType.copy));

            return AdaptiveTextSelectionToolbar.buttonItems(
              anchors: editableTextState.contextMenuAnchors,
              buttonItems: buttonItems,
            );
          },
        ),

        // Extra space so content isn't hidden behind FABs
        const SizedBox(height: 120),
      ],
    );
  }
}