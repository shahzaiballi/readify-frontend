// lib/presentation/community/pages/create_community_page.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  final _emojis = ['📚', '📖', '🎯', '💡', '🔥', '🌟', '🎨', '🧠'];

  @override
  void initState() {
    super.initState();
    // Reset action state when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(communityActionProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) return;

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

    if (result != null && _privacy == 'public') {
      // Public community: just close the sheet
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Community "${result.name}" created!'),
          backgroundColor: Colors.green,
        ),
      );
    }
    // Private community: the success UI is shown inline (see build method)
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(communityActionProvider);
    final isLoading = actionState.isLoading;
    final createdCommunity = actionState.createdCommunity;

    // Show invite link screen for private communities after creation
    if (createdCommunity != null && _privacy == 'private') {
      return _InviteLinkSheet(
        community: createdCommunity,
        onDone: () => Navigator.of(context).pop(),
      );
    }

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
            _Label('Pick an emoji', context),
            SizedBox(height: context.responsive.sp(10)),
            Wrap(
              spacing: context.responsive.wp(10),
              runSpacing: context.responsive.sp(8),
              children: _emojis.map((e) {
                final selected = e == _emoji;
                return GestureDetector(
                  onTap: isLoading ? null : () => setState(() => _emoji = e),
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
              enabled: !isLoading,
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
              enabled: !isLoading,
            ),
            SizedBox(height: context.responsive.sp(20)),

            // Type toggle
            _Label('Type', context),
            SizedBox(height: context.responsive.sp(10)),
            _SegmentRow(
              options: const {'general': 'General', 'book': 'Book Group'},
              selected: _type,
              onSelect: isLoading ? null : (v) => setState(() => _type = v),
              context: context,
            ),
            SizedBox(height: context.responsive.sp(16)),

            // Privacy toggle
            _Label('Privacy', context),
            SizedBox(height: context.responsive.sp(10)),
            _SegmentRow(
              options: const {'public': '🌍 Public', 'private': '🔒 Private'},
              selected: _privacy,
              onSelect: isLoading ? null : (v) => setState(() => _privacy = v),
              context: context,
            ),

            // Privacy info banner
            if (_privacy == 'private') ...[
              SizedBox(height: context.responsive.sp(12)),
              Container(
                padding: EdgeInsets.all(context.responsive.sp(12)),
                decoration: BoxDecoration(
                  color: const Color(0xFFB062FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(context.responsive.sp(10)),
                  border: Border.all(color: const Color(0xFFB062FF).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.link, color: const Color(0xFFB062FF), size: context.responsive.sp(16)),
                    SizedBox(width: context.responsive.wp(10)),
                    Expanded(
                      child: Text(
                        'After creating, you\'ll get a shareable invite link for your friends to join.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: context.responsive.sp(12),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Error display
            if (actionState.error != null) ...[
              SizedBox(height: context.responsive.sp(12)),
              Container(
                padding: EdgeInsets.all(context.responsive.sp(12)),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(context.responsive.sp(10)),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                    SizedBox(width: context.responsive.wp(8)),
                    Expanded(
                      child: Text(
                        actionState.error!.replaceAll('Exception: ', ''),
                        style: TextStyle(color: Colors.redAccent, fontSize: context.responsive.sp(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: context.responsive.sp(28)),

            // Submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB062FF),
                  disabledBackgroundColor: const Color(0xFFB062FF).withOpacity(0.5),
                  padding: EdgeInsets.symmetric(
                    vertical: context.responsive.sp(15),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.responsive.sp(12)),
                  ),
                ),
                child: isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: context.responsive.wp(10)),
                          Text(
                            'Creating...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: context.responsive.sp(15),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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

// ── Invite Link Sheet ─────────────────────────────────────────────────────────

class _InviteLinkSheet extends StatelessWidget {
  final CommunityEntity community;
  final VoidCallback onDone;

  const _InviteLinkSheet({required this.community, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final inviteToken = community.inviteToken;
    final inviteLink = inviteToken != null
        ? 'https://readify.app/community/join/$inviteToken'
        : null;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1626),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.responsive.sp(24)),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        context.responsive.wp(24),
        context.responsive.sp(12),
        context.responsive.wp(24),
        MediaQuery.of(context).padding.bottom + context.responsive.sp(32),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          SizedBox(height: context.responsive.sp(28)),

          // Success icon
          Container(
            width: context.responsive.sp(72),
            height: context.responsive.sp(72),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFB062FF), Color(0xFF7B3FF2)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFB062FF).withOpacity(0.35),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: context.responsive.sp(36),
            ),
          ),

          SizedBox(height: context.responsive.sp(20)),

          Text(
            '${community.coverEmoji} ${community.name}',
            style: TextStyle(
              color: Colors.white,
              fontSize: context.responsive.sp(20),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: context.responsive.sp(8)),

          Text(
            'Your private community is ready!',
            style: TextStyle(
              color: Colors.white54,
              fontSize: context.responsive.sp(14),
            ),
          ),

          SizedBox(height: context.responsive.sp(28)),

          if (inviteLink != null) ...[
            // Invite link section
            Container(
              padding: EdgeInsets.all(context.responsive.sp(16)),
              decoration: BoxDecoration(
                color: const Color(0xFF1A223B),
                borderRadius: BorderRadius.circular(context.responsive.sp(14)),
                border: Border.all(color: const Color(0xFFB062FF).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        color: const Color(0xFFB062FF),
                        size: context.responsive.sp(16),
                      ),
                      SizedBox(width: context.responsive.wp(8)),
                      Text(
                        'Private Invite Link',
                        style: TextStyle(
                          color: const Color(0xFFB062FF),
                          fontSize: context.responsive.sp(12),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.responsive.sp(10)),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.responsive.wp(12),
                      vertical: context.responsive.sp(10),
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1626),
                      borderRadius: BorderRadius.circular(context.responsive.sp(8)),
                    ),
                    child: Text(
                      inviteLink,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: context.responsive.sp(12),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  SizedBox(height: context.responsive.sp(12)),
                  Text(
                    'Share this link with friends to invite them to your private community.',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: context.responsive.sp(11),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: context.responsive.sp(16)),

            // Copy button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: inviteLink));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invite link copied to clipboard!'),
                      backgroundColor: Color(0xFFB062FF),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: Icon(
                  Icons.copy_rounded,
                  color: const Color(0xFFB062FF),
                  size: context.responsive.sp(18),
                ),
                label: Text(
                  'Copy Invite Link',
                  style: TextStyle(
                    color: const Color(0xFFB062FF),
                    fontSize: context.responsive.sp(14),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFB062FF)),
                  padding: EdgeInsets.symmetric(vertical: context.responsive.sp(14)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.responsive.sp(12)),
                  ),
                ),
              ),
            ),

            SizedBox(height: context.responsive.sp(12)),
          ],

          // Done button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB062FF),
                padding: EdgeInsets.symmetric(vertical: context.responsive.sp(14)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.responsive.sp(12)),
                ),
              ),
              child: Text(
                'Go to Community',
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
    );
  }
}

// ── Shared form widgets ────────────────────────────────────────────────────────

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final BuildContext context;
  final int maxLines;
  final bool enabled;

  const _TextField({
    required this.controller,
    required this.hint,
    required this.context,
    this.maxLines = 1,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext _) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFF1A223B) : const Color(0xFF141824),
        borderRadius: BorderRadius.circular(context.responsive.sp(12)),
        border: Border.all(color: Colors.white12),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        enabled: enabled,
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
  final ValueChanged<String>? onSelect;
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
        final isFirst = e.key == options.keys.first;
        return Expanded(
          child: GestureDetector(
            onTap: onSelect != null ? () => onSelect!(e.key) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(
                right: isFirst ? context.responsive.wp(8) : 0,
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