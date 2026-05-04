// lib/presentation/community/pages/create_community_page.dart
// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../domain/entities/community_entity.dart';
import '../controllers/community_controller.dart';

class CreateCommunityPage extends ConsumerStatefulWidget {
  const CreateCommunityPage({super.key});

  @override
  ConsumerState<CreateCommunityPage> createState() =>
      _CreateCommunityPageState();
}

class _CreateCommunityPageState extends ConsumerState<CreateCommunityPage>
    with SingleTickerProviderStateMixin {
  late TabController _typeTabController;

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _bookNameController = TextEditingController();
  final _bookAuthorController = TextEditingController();

  String _privacy = 'public';

  // Image state
  File? _pickedImageFile;
  Uint8List? _pickedImageBytes;
  String? _pickedImageName;

  @override
  void initState() {
    super.initState();
    _typeTabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(communityActionProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _typeTabController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _bookNameController.dispose();
    _bookAuthorController.dispose();
    super.dispose();
  }

  String get _communityType =>
      _typeTabController.index == 0 ? 'general' : 'book';

  Future<void> _pickImage() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ImageSourceSheet(),
    );

    if (source == null) return;

    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked == null) return;

      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _pickedImageBytes = bytes;
          _pickedImageName = picked.name;
        });
      } else {
        setState(() {
          _pickedImageFile = File(picked.path);
          _pickedImageName = picked.name;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick image: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  bool get _hasImage => _pickedImageFile != null || _pickedImageBytes != null;

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Community name is required'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    if (_communityType == 'book' && _bookNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a book name'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final result = await ref.read(communityActionProvider.notifier)
        .createCommunityWithImage(
      params: CreateCommunityParams(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        communityType: _communityType,
        privacy: _privacy,
        coverEmoji: '📚',
        bookName: _bookNameController.text.trim(),
        bookAuthor: _bookAuthorController.text.trim(),
      ),
      imagePath: _pickedImageFile?.path,
      imageBytes: _pickedImageBytes,
      imageName: _pickedImageName,
    );

    if (!mounted) return;

    if (result != null && _privacy == 'public') {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Community "${result.name}" created!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(communityActionProvider);
    final isLoading = actionState.isLoading;
    final createdCommunity = actionState.createdCommunity;

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
                'New Community',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: context.responsive.sp(18),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: context.responsive.sp(24)),

            // ── Community Type Tabs ────────────────────────────────────────
            Container(
              height: context.responsive.sp(42),
              decoration: BoxDecoration(
                color: const Color(0xFF161B2E),
                borderRadius: BorderRadius.circular(context.responsive.sp(12)),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: TabBar(
                controller: _typeTabController,
                onTap: (_) => setState(() {}),
                indicator: BoxDecoration(
                  color: const Color(0xFFB062FF),
                  borderRadius: BorderRadius.circular(context.responsive.sp(10)),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white38,
                labelStyle: TextStyle(
                  fontSize: context.responsive.sp(13),
                  fontWeight: FontWeight.bold,
                ),
                padding: EdgeInsets.all(context.responsive.sp(4)),
                tabs: const [Tab(text: '💬 General'), Tab(text: '📖 Book Group')],
              ),
            ),

            SizedBox(height: context.responsive.sp(24)),

            // ── Avatar Picker ──────────────────────────────────────────────
            Center(
              child: GestureDetector(
                onTap: isLoading ? null : _pickImage,
                child: Stack(
                  children: [
                    Container(
                      width: context.responsive.sp(80),
                      height: context.responsive.sp(80),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1A223B),
                        border: Border.all(
                          color: _hasImage
                              ? const Color(0xFFB062FF)
                              : Colors.white12,
                          width: 2,
                        ),
                        image: _hasImage
                            ? DecorationImage(
                                image: kIsWeb && _pickedImageBytes != null
                                    ? MemoryImage(_pickedImageBytes!) as ImageProvider
                                    : FileImage(_pickedImageFile!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _hasImage
                          ? null
                          : Icon(
                              Icons.groups_rounded,
                              color: Colors.white38,
                              size: context.responsive.sp(36),
                            ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(context.responsive.sp(6)),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB062FF),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFF0F1626), width: 2),
                        ),
                        child: Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: context.responsive.sp(13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: context.responsive.sp(6)),
            Center(
              child: Text(
                _hasImage ? 'Tap to change' : 'Add photo',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: context.responsive.sp(12),
                ),
              ),
            ),

            SizedBox(height: context.responsive.sp(20)),

            // ── Community Name ─────────────────────────────────────────────
            _FieldLabel('Community Name', context),
            SizedBox(height: context.responsive.sp(8)),
            _StyledTextField(
              controller: _nameController,
              hint: _communityType == 'book'
                  ? 'e.g. Atomic Habits Readers'
                  : 'e.g. Sci-Fi Lovers',
              enabled: !isLoading,
            ),
            SizedBox(height: context.responsive.sp(16)),

            // ── Book-specific fields ───────────────────────────────────────
            if (_communityType == 'book') ...[
              _FieldLabel('Book Title', context),
              SizedBox(height: context.responsive.sp(8)),
              _StyledTextField(
                controller: _bookNameController,
                hint: 'e.g. Atomic Habits',
                enabled: !isLoading,
                prefixIcon: Icons.menu_book_rounded,
              ),
              SizedBox(height: context.responsive.sp(12)),

              _FieldLabel('Author (optional)', context),
              SizedBox(height: context.responsive.sp(8)),
              _StyledTextField(
                controller: _bookAuthorController,
                hint: 'e.g. James Clear',
                enabled: !isLoading,
                prefixIcon: Icons.person_outline_rounded,
              ),
              SizedBox(height: context.responsive.sp(16)),
            ],

            // ── Description ────────────────────────────────────────────────
            _FieldLabel('Description (optional)', context),
            SizedBox(height: context.responsive.sp(8)),
            _StyledTextField(
              controller: _descController,
              hint: 'What is this community about?',
              maxLines: 3,
              enabled: !isLoading,
            ),

            SizedBox(height: context.responsive.sp(20)),

            // ── Privacy ────────────────────────────────────────────────────
            _FieldLabel('Privacy', context),
            SizedBox(height: context.responsive.sp(10)),
            Row(
              children: [
                Expanded(
                  child: _PrivacyOption(
                    label: '🌍 Public',
                    subtitle: 'Anyone can join',
                    isSelected: _privacy == 'public',
                    onTap: isLoading ? null : () => setState(() => _privacy = 'public'),
                  ),
                ),
                SizedBox(width: context.responsive.wp(10)),
                Expanded(
                  child: _PrivacyOption(
                    label: '🔒 Private',
                    subtitle: 'Invite-only',
                    isSelected: _privacy == 'private',
                    onTap: isLoading ? null : () => setState(() => _privacy = 'private'),
                  ),
                ),
              ],
            ),

            if (_privacy == 'private') ...[
              SizedBox(height: context.responsive.sp(10)),
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
                        'You\'ll get a shareable invite link after creation.',
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

            // ── Error ──────────────────────────────────────────────────────
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

            SizedBox(height: context.responsive.sp(24)),

            // ── Create Button ──────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB062FF),
                  disabledBackgroundColor: const Color(0xFFB062FF).withOpacity(0.5),
                  padding: EdgeInsets.symmetric(vertical: context.responsive.sp(15)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.responsive.sp(12)),
                  ),
                ),
                child: isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
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

  Widget _FieldLabel(String text, BuildContext context) => Text(
        text,
        style: TextStyle(
          color: Colors.white70,
          fontSize: context.responsive.sp(12),
          fontWeight: FontWeight.w500,
        ),
      );
}

// ── Image Source Sheet ────────────────────────────────────────────────────────

class _ImageSourceSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(context.responsive.wp(16)),
      decoration: BoxDecoration(
        color: const Color(0xFF1A223B),
        borderRadius: BorderRadius.circular(context.responsive.sp(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(context.responsive.sp(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: context.responsive.sp(16)),
              Text(
                'Community Photo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: context.responsive.sp(16),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: context.responsive.sp(16)),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(context.responsive.sp(10)),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB062FF).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.camera_alt_outlined,
                      color: const Color(0xFFB062FF), size: context.responsive.sp(20)),
                ),
                title: Text('Take a photo',
                    style: TextStyle(color: Colors.white, fontSize: context.responsive.sp(14))),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(context.responsive.sp(10)),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB062FF).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.photo_library_outlined,
                      color: const Color(0xFFB062FF), size: context.responsive.sp(20)),
                ),
                title: Text('Choose from gallery',
                    style: TextStyle(color: Colors.white, fontSize: context.responsive.sp(14))),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Styled Text Field ──────────────────────────────────────────────────────────

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final bool enabled;
  final IconData? prefixIcon;

  const _StyledTextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.enabled = true,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
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
          hintStyle: TextStyle(color: Colors.white38, fontSize: context.responsive.sp(13)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(context.responsive.sp(14)),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: Colors.white38, size: context.responsive.sp(18))
              : null,
        ),
      ),
    );
  }
}

// ── Privacy Option ──────────────────────────────────────────────────────────────

class _PrivacyOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback? onTap;

  const _PrivacyOption({
    required this.label,
    required this.subtitle,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          vertical: context.responsive.sp(14),
          horizontal: context.responsive.wp(12),
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFB062FF).withOpacity(0.12)
              : const Color(0xFF1A223B),
          borderRadius: BorderRadius.circular(context.responsive.sp(10)),
          border: Border.all(
            color: isSelected ? const Color(0xFFB062FF) : Colors.white12,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFFB062FF) : Colors.white,
                fontSize: context.responsive.sp(13),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            SizedBox(height: context.responsive.sp(2)),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white38,
                fontSize: context.responsive.sp(10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Invite Link Sheet (shown after private community creation) ─────────────────

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
          Center(
            child: Container(
              width: context.responsive.wp(40),
              height: context.responsive.sp(4),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)),
            ),
          ),
          SizedBox(height: context.responsive.sp(28)),

          Container(
            width: context.responsive.sp(72),
            height: context.responsive.sp(72),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Color(0xFFB062FF), Color(0xFF7B3FF2)]),
              boxShadow: [BoxShadow(color: const Color(0xFFB062FF).withOpacity(0.35), blurRadius: 24, spreadRadius: 4)],
            ),
            child: Icon(Icons.check_rounded, color: Colors.white, size: context.responsive.sp(36)),
          ),

          SizedBox(height: context.responsive.sp(20)),

          Text(
            community.name,
            style: TextStyle(color: Colors.white, fontSize: context.responsive.sp(20), fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: context.responsive.sp(6)),
          Text('Your private community is ready!',
              style: TextStyle(color: Colors.white54, fontSize: context.responsive.sp(13))),

          if (inviteLink != null) ...[
            SizedBox(height: context.responsive.sp(24)),
            Container(
              padding: EdgeInsets.all(context.responsive.sp(14)),
              decoration: BoxDecoration(
                color: const Color(0xFF1A223B),
                borderRadius: BorderRadius.circular(context.responsive.sp(12)),
                border: Border.all(color: const Color(0xFFB062FF).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      inviteLink,
                      style: TextStyle(color: Colors.white60, fontSize: context.responsive.sp(11)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: inviteLink));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copied!'), backgroundColor: Color(0xFFB062FF)),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: context.responsive.wp(10), vertical: context.responsive.sp(6)),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB062FF).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(context.responsive.sp(6)),
                      ),
                      child: Text('Copy',
                          style: TextStyle(color: const Color(0xFFB062FF), fontSize: context.responsive.sp(12), fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: context.responsive.sp(16)),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB062FF),
                padding: EdgeInsets.symmetric(vertical: context.responsive.sp(14)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.responsive.sp(12))),
              ),
              child: Text('Go to Community',
                  style: TextStyle(color: Colors.white, fontSize: context.responsive.sp(15), fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}