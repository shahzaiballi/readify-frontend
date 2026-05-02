// lib/presentation/community/pages/create_community_page.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../domain/entities/community_entity.dart';
import '../controllers/community_controller.dart';

class CreateCommunityPage extends ConsumerStatefulWidget {
  const CreateCommunityPage({super.key});

  @override
  ConsumerState<CreateCommunityPage> createState() =>
      _CreateCommunityPageState();
}

class _CreateCommunityPageState extends ConsumerState<CreateCommunityPage> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String _type = 'general';
  String _privacy = 'public';
  String _emoji = '📚';
  bool _isSubmitting = false;

  final _emojis = ['📚', '📖', '🎯', '💡', '🔥', '🌟', '🎨', '🧠'];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isSubmitting = true);

    final result = await ref
        .read(communityActionProvider.notifier)
        .createCommunity(CreateCommunityParams(
          name: _nameController.text.trim(),
          description: _descController.text.trim(),
          communityType: _type,
          privacy: _privacy,
          coverEmoji: _emoji,
        ));

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result != null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Community "${result.name}" created!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create community. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1626),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.responsive.sp(24)),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            context.responsive.sp(24),
        top: context.responsive.sp(12),
        left: context.responsive.wp(24),
        right: context.responsive.wp(24),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: context.responsive.wp(40),
                height: context.responsive.sp(4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            SizedBox(height: context.responsive.sp(20)),

            Center(
              child: Text(
                'Create Community',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: context.responsive.sp(18),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: context.responsive.sp(24)),

            // Emoji picker
            Text(
              'Pick an emoji',
              style: TextStyle(color: Colors.white70, fontSize: context.responsive.sp(12)),
            ),
            SizedBox(height: context.responsive.sp(10)),
            Wrap(
              spacing: context.responsive.wp(10),
              runSpacing: context.responsive.sp(8),
              children: _emojis.map((e) {
                final selected = e == _emoji;
                return GestureDetector(
                  onTap: () => setState(() => _emoji = e),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.all(context.responsive.sp(10)),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFB062FF).withOpacity(0.2)
                          : const Color(0xFF1A223B),
                      borderRadius: BorderRadius.circular(context.responsive.sp(10)),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFFB062FF)
                            : Colors.white12,
                      ),
                    ),
                    child: Text(e, style: TextStyle(fontSize: context.responsive.sp(20))),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: context.responsive.sp(20)),

            // Name
            _Label('Community Name', context),
            SizedBox(height: context.responsive.sp(8)),
            _TextField(
              controller: _nameController,
              hint: 'e.g. Sci-Fi Lovers',
              context: context,
            ),
            SizedBox(height: context.responsive.sp(16)),

            // Description
            _Label('Description (optional)', context),
            SizedBox(height: context.responsive.sp(8)),
            _TextField(
              controller: _descController,
              hint: 'What is this community about?',
              context: context,
              maxLines: 3,
            ),
            SizedBox(height: context.responsive.sp(20)),

            // Type toggle
            _Label('Type', context),
            SizedBox(height: context.responsive.sp(10)),
            _SegmentRow(
              options: const {'general': 'General', 'book': 'Book Group'},
              selected: _type,
              onSelect: (v) => setState(() => _type = v),
              context: context,
            ),
            SizedBox(height: context.responsive.sp(16)),

            // Privacy toggle
            _Label('Privacy', context),
            SizedBox(height: context.responsive.sp(10)),
            _SegmentRow(
              options: const {'public': '🌍 Public', 'private': '🔒 Private'},
              selected: _privacy,
              onSelect: (v) => setState(() => _privacy = v),
              context: context,
            ),
            SizedBox(height: context.responsive.sp(28)),

            // Submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB062FF),
                  padding: EdgeInsets.symmetric(
                    vertical: context.responsive.sp(15),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.responsive.sp(12)),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Create Community',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: context.responsive.sp(15),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _Label(String text, BuildContext context) => Text(
        text,
        style: TextStyle(
          color: Colors.white70,
          fontSize: context.responsive.sp(12),
          fontWeight: FontWeight.w500,
        ),
      );
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final BuildContext context;
  final int maxLines;

  const _TextField({
    required this.controller,
    required this.hint,
    required this.context,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext _) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A223B),
        borderRadius: BorderRadius.circular(context.responsive.sp(12)),
        border: Border.all(color: Colors.white12),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(color: Colors.white, fontSize: context.responsive.sp(14)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white38,
            fontSize: context.responsive.sp(13),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(context.responsive.sp(14)),
        ),
      ),
    );
  }
}

class _SegmentRow extends StatelessWidget {
  final Map<String, String> options;
  final String selected;
  final ValueChanged<String> onSelect;
  final BuildContext context;

  const _SegmentRow({
    required this.options,
    required this.selected,
    required this.onSelect,
    required this.context,
  });

  @override
  Widget build(BuildContext _) {
    return Row(
      children: options.entries.map((e) {
        final isSelected = e.key == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(e.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(
                right: e.key == options.keys.first
                    ? context.responsive.wp(8)
                    : 0,
              ),
              padding: EdgeInsets.symmetric(
                vertical: context.responsive.sp(12),
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFB062FF)
                    : const Color(0xFF1A223B),
                borderRadius: BorderRadius.circular(context.responsive.sp(10)),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFB062FF)
                      : Colors.white12,
                ),
              ),
              child: Text(
                e.value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontSize: context.responsive.sp(13),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}