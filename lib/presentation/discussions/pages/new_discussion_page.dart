import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../auth/widgets/custom_text_field.dart';
import '../../auth/widgets/primary_button.dart';
import '../controllers/discussion_controller.dart';
import '../../../data/repositories/discussion_repository_impl.dart';

class NewDiscussionPage extends ConsumerStatefulWidget {
  final String? initialText;

  const NewDiscussionPage({super.key, this.initialText});

  @override
  ConsumerState<NewDiscussionPage> createState() =>
      _NewDiscussionPageState();
}

class _NewDiscussionPageState extends ConsumerState<NewDiscussionPage> {
  final _chapterController = TextEditingController();
  final _titleController = TextEditingController();
  final _thoughtsController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialText != null) {
      _thoughtsController.text = widget.initialText!;
    }
  }

  @override
  void dispose() {
    _chapterController.dispose();
    _titleController.dispose();
    _thoughtsController.dispose();
    super.dispose();
  }

  Future<void> _submitDiscussion() async {
    if (_titleController.text.trim().isEmpty ||
        _thoughtsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a title and your thoughts.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await DiscussionRepositoryImpl().createPost(
        title: _titleController.text.trim(),
        content: _thoughtsController.text.trim(),
        chapterTag: _chapterController.text.trim(),
      );

      // Refresh the discussions feed so the new post appears
      ref.invalidate(discussionControllerProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Discussion posted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1626),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1626),
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(context.responsive.sp(8)),
            decoration: const BoxDecoration(
              color: Color(0xFF1E233D),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: context.responsive.sp(18),
            ),
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'New Discussion',
          style: TextStyle(
            color: Colors.white,
            fontSize: context.responsive.sp(16),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(context.responsive.wp(24)),
          child: Container(
            padding: EdgeInsets.all(context.responsive.wp(20)),
            decoration: BoxDecoration(
              color: const Color(0xFF1E233D),
              borderRadius:
                  BorderRadius.circular(context.responsive.sp(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Chapter (optional)', context),
                CustomTextField(
                  controller: _chapterController,
                  hintText: 'e.g. Chapter 3',
                  label: '',
                ),
                SizedBox(height: context.responsive.sp(16)),

                _buildLabel('Discussion Title', context),
                CustomTextField(
                  controller: _titleController,
                  hintText: 'What do you want to discuss?',
                ),
                SizedBox(height: context.responsive.sp(16)),

                _buildLabel('Your Thoughts', context),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1626),
                    borderRadius: BorderRadius.circular(
                      context.responsive.sp(12),
                    ),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: TextField(
                    controller: _thoughtsController,
                    maxLines: 6,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.responsive.sp(14),
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Share your insights, questions, or ideas...',
                      hintStyle: TextStyle(
                        color: Colors.white54,
                        fontSize: context.responsive.sp(14),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(
                        context.responsive.sp(16),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: context.responsive.sp(24)),

                SizedBox(
                  width: double.infinity,
                  height: context.responsive.sp(50),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF9146FF), Color(0xFF3861FB)],
                      ),
                      borderRadius: BorderRadius.circular(
                        context.responsive.sp(12),
                      ),
                    ),
                    child: ElevatedButton.icon(
                      onPressed:
                          _isSubmitting ? null : _submitDiscussion,
                      icon: _isSubmitting
                          ? SizedBox(
                              width: context.responsive.sp(20),
                              height: context.responsive.sp(20),
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              Icons.send,
                              color: Colors.white,
                              size: context.responsive.sp(18),
                            ),
                      label: Text(
                        _isSubmitting
                            ? 'Posting...'
                            : 'Start Discussion',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: context.responsive.sp(15),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            context.responsive.sp(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.responsive.sp(8)),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white70,
          fontSize: context.responsive.sp(13),
        ),
      ),
    );
  }
}