import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../auth/widgets/custom_text_field.dart';
import '../controllers/add_book_controller.dart';
import '../controllers/library_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

// ── Processing stage model ────────────────────────────────────────────────────

class _ProcessingStage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _ProcessingStage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

const _processingStages = [
  _ProcessingStage(
    title: 'Uploading PDF',
    description: 'Securely uploading your book to the server...',
    icon: Icons.cloud_upload_outlined,
    color: Color(0xFFB062FF),
  ),
  _ProcessingStage(
    title: 'AI Chapter Detection',
    description: 'Claude reads your PDF and identifies chapters...',
    icon: Icons.auto_awesome_outlined,
    color: Color(0xFF3861FB),
  ),
  _ProcessingStage(
    title: 'Building Reading Chunks',
    description: 'Splitting content into bite-sized reading sessions...',
    icon: Icons.layers_outlined,
    color: Color(0xFF00B4D8),
  ),
  _ProcessingStage(
    title: 'Generating Summaries',
    description: 'Creating chapter summaries and key takeaways...',
    icon: Icons.description_outlined,
    color: Color(0xFF10B981),
  ),
  _ProcessingStage(
    title: 'Creating Flashcards',
    description: 'Building personalised flashcards for retention...',
    icon: Icons.style_outlined,
    color: Color(0xFFE83E8C),
  ),
];

// ── What happens next features ────────────────────────────────────────────────

class _FeatureItem {
  final String emoji;
  final String title;
  final String description;

  const _FeatureItem({
    required this.emoji,
    required this.title,
    required this.description,
  });
}

const _featureItems = [
  _FeatureItem(
    emoji: '🤖',
    title: 'AI Chapters',
    description: 'Auto-detected from your PDF',
  ),
  _FeatureItem(
    emoji: '⏱️',
    title: '5-min Chunks',
    description: 'Bite-sized, never overwhelming',
  ),
  _FeatureItem(
    emoji: '🧠',
    title: 'Flashcards',
    description: 'Key concepts, auto-generated',
  ),
  _FeatureItem(
    emoji: '📝',
    title: 'Summaries',
    description: 'Chapter insights at a glance',
  ),
];

// ── Main Page ─────────────────────────────────────────────────────────────────

class AddBookPage extends ConsumerStatefulWidget {
  const AddBookPage({super.key});

  @override
  ConsumerState<AddBookPage> createState() => _AddBookPageState();
}

class _AddBookPageState extends ConsumerState<AddBookPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();

  String? _selectedFilePath;
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;

  // Processing animation state
  bool _isProcessing = false;
  int _currentStageIndex = 0;
  double _overallProgress = 0.0;

  // Animation controllers
  late AnimationController _progressAnimController;
  late AnimationController _stageAnimController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;

  late Animation<double> _progressAnim;
  late Animation<double> _stageAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();

    _progressAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _progressAnim = CurvedAnimation(
      parent: _progressAnimController,
      curve: Curves.easeOutCubic,
    );

    _stageAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _stageAnim = CurvedAnimation(
      parent: _stageAnimController,
      curve: Curves.easeOut,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _shimmerAnim = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _progressAnimController.dispose();
    _stageAnimController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  // ── Simulated processing stages ─────────────────────────────────────────────

  Future<void> _simulateProcessing() async {
    setState(() => _isProcessing = true);

    final stagesCount = _processingStages.length;

    for (int i = 0; i < stagesCount; i++) {
      if (!mounted) return;

      setState(() => _currentStageIndex = i);
      _stageAnimController.forward(from: 0);

      // Animate progress bar to this stage
      final targetProgress = (i + 1) / stagesCount;
      _progressAnim = Tween<double>(
        begin: _overallProgress,
        end: targetProgress,
      ).animate(CurvedAnimation(
        parent: _progressAnimController,
        curve: Curves.easeOutCubic,
      ));
      _progressAnimController.forward(from: 0);
      setState(() => _overallProgress = targetProgress);

      // Wait for each stage — long enough for the user to read and feel the progress
      final stageDurations = [
        const Duration(milliseconds: 4500), // Uploading
        const Duration(milliseconds: 5500), // AI Chapter Detection
        const Duration(milliseconds: 4000), // Building Chunks
        const Duration(milliseconds: 5000), // Summaries
        const Duration(milliseconds: 4000), // Flashcards
      ];
      await Future.delayed(stageDurations[i]);
    }
  }

  // ── File picker ──────────────────────────────────────────────────────────────

  Future<void> _handleFileUpload() async {
    if (!kIsWeb) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        final mediaStatus = await Permission.manageExternalStorage.request();
        if (!mediaStatus.isGranted && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Storage access is required to upload PDF books.'),
              backgroundColor: Color(0xFF1E152A),
            ),
          );
          return;
        }
      }
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && mounted) {
      final file = result.files.single;
      const maxBytes = 50 * 1024 * 1024;

      if (file.size > maxBytes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF is too large. Maximum size is 50MB.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      setState(() {
        _selectedFilePath = file.path;
        _selectedFileBytes = file.bytes;
        _selectedFileName = file.name;
      });
    }
  }

  // ── Submit ───────────────────────────────────────────────────────────────────

  Future<void> _submitForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedFilePath == null && _selectedFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a PDF file to upload.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    // Start the simulated processing animation in parallel with the real upload
    _simulateProcessing();

    await ref.read(addBookControllerProvider.notifier).uploadBook(
          title: _titleController.text.trim(),
          author: _authorController.text.trim(),
          filePath: _selectedFilePath,
          fileBytes: _selectedFileBytes,
          fileName: _selectedFileName,
        );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _formatFileSize(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  bool get _hasFile =>
      _selectedFilePath != null || _selectedFileBytes != null;

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(addBookControllerProvider, (previous, next) {
      if (!next.isLoading && next.hasValue && previous is AsyncLoading) {
        ref.invalidate(rawLibraryProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '📚 Book uploaded! It will appear in your library once AI processing completes.',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
          Navigator.of(context).pop();
        }
      } else if (next.hasError && !next.isLoading) {
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload failed: ${next.error}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    });

    final isLoading = ref.watch(addBookControllerProvider).isLoading;
    final showProcessing = _isProcessing || isLoading;

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
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: showProcessing
            ? _ProcessingView(
                key: const ValueKey('processing'),
                currentStageIndex: _currentStageIndex,
                overallProgress: _overallProgress,
                progressAnim: _progressAnim,
                stageAnim: _stageAnim,
                pulseAnim: _pulseAnim,
                shimmerAnim: _shimmerAnim,
              )
            : _UploadFormView(
                key: const ValueKey('form'),
                formKey: _formKey,
                titleController: _titleController,
                authorController: _authorController,
                hasFile: _hasFile,
                selectedFileName: _selectedFileName,
                onPickFile: _handleFileUpload,
                onSubmit: _submitForm,
              ),
      ),
    );
  }
}

// ── Processing View ────────────────────────────────────────────────────────────

class _ProcessingView extends StatelessWidget {
  final int currentStageIndex;
  final double overallProgress;
  final Animation<double> progressAnim;
  final Animation<double> stageAnim;
  final Animation<double> pulseAnim;
  final Animation<double> shimmerAnim;

  const _ProcessingView({
    super.key,
    required this.currentStageIndex,
    required this.overallProgress,
    required this.progressAnim,
    required this.stageAnim,
    required this.pulseAnim,
    required this.shimmerAnim,
  });

  @override
  Widget build(BuildContext context) {
    final stage = _processingStages[currentStageIndex.clamp(
      0,
      _processingStages.length - 1,
    )];
    final progressPercent = (overallProgress * 100).toInt();

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: context.responsive.wp(24),
        vertical: context.responsive.sp(8),
      ),
      child: Column(
        children: [
          // Drag handle
          _DragHandle(),
          SizedBox(height: context.responsive.sp(24)),

          // Animated icon
          AnimatedBuilder(
            animation: pulseAnim,
            builder: (_, child) => Transform.scale(
              scale: pulseAnim.value,
              child: child,
            ),
            child: Container(
              width: context.responsive.sp(80),
              height: context.responsive.sp(80),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    stage.color.withValues(alpha: 0.3),
                    stage.color.withValues(alpha: 0.08),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: stage.color.withValues(alpha: 0.35),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Icon(
                stage.icon,
                color: stage.color,
                size: context.responsive.sp(36),
              ),
            ),
          ),

          SizedBox(height: context.responsive.sp(20)),

          // Stage title
          AnimatedBuilder(
            animation: stageAnim,
            builder: (_, child) => Opacity(
              opacity: stageAnim.value.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, 12 * (1 - stageAnim.value.clamp(0.0, 1.0))),
                child: child,
              ),
            ),
            child: Text(
              stage.title,
              style: TextStyle(
                color: Colors.white,
                fontSize: context.responsive.sp(20),
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          SizedBox(height: context.responsive.sp(8)),

          AnimatedBuilder(
            animation: stageAnim,
            builder: (_, child) => Opacity(
              opacity: stageAnim.value.clamp(0.0, 1.0),
              child: child,
            ),
            child: Text(
              stage.description,
              style: TextStyle(
                color: Colors.white54,
                fontSize: context.responsive.sp(13),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          SizedBox(height: context.responsive.sp(32)),

          // Progress bar with shimmer
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Processing your book...',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: context.responsive.sp(12),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  AnimatedBuilder(
                    animation: progressAnim,
                    builder: (_, __) => Text(
                      '${(progressAnim.value.clamp(0.0, 1.0) * 100).toInt()}%',
                      style: TextStyle(
                        color: stage.color,
                        fontSize: context.responsive.sp(13),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.responsive.sp(10)),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: Container(
                  height: context.responsive.sp(8),
                  color: Colors.white.withValues(alpha: 0.08),
                  child: AnimatedBuilder(
                    animation: progressAnim,
                    builder: (_, __) => FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progressAnim.value.clamp(0.0, 1.0),
                      child: AnimatedBuilder(
                        animation: shimmerAnim,
                        builder: (_, child) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                stage.color,
                                stage.color.withValues(alpha: 0.7),
                                Colors.white.withValues(alpha: 0.9),
                                stage.color.withValues(alpha: 0.7),
                                stage.color,
                              ],
                              stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                              begin: Alignment(shimmerAnim.value - 1, 0),
                              end: Alignment(shimmerAnim.value, 0),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: context.responsive.sp(28)),

          // Stage steps
          ..._processingStages.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            final isCompleted = i < currentStageIndex;
            final isCurrent = i == currentStageIndex;
            final isPending = i > currentStageIndex;

            return _StageStepRow(
              stage: s,
              isCompleted: isCompleted,
              isCurrent: isCurrent,
              isPending: isPending,
              pulseAnim: pulseAnim,
            );
          }),

          SizedBox(height: context.responsive.sp(20)),

          // Disclaimer
          Container(
            padding: EdgeInsets.all(context.responsive.sp(14)),
            decoration: BoxDecoration(
              color: const Color(0xFFB062FF).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(context.responsive.sp(12)),
              border: Border.all(
                color: const Color(0xFFB062FF).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: const Color(0xFFB062FF),
                  size: context.responsive.sp(16),
                ),
                SizedBox(width: context.responsive.wp(10)),
                Expanded(
                  child: Text(
                    'Your book will appear in your library once AI processing is complete. You can close this and it will continue in the background.',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: context.responsive.sp(11.5),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: context.responsive.sp(8)),
        ],
      ),
    );
  }
}

// ── Stage Step Row ─────────────────────────────────────────────────────────────

class _StageStepRow extends StatelessWidget {
  final _ProcessingStage stage;
  final bool isCompleted;
  final bool isCurrent;
  final bool isPending;
  final Animation<double> pulseAnim;

  const _StageStepRow({
    required this.stage,
    required this.isCompleted,
    required this.isCurrent,
    required this.isPending,
    required this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.responsive.sp(10)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(
          horizontal: context.responsive.wp(14),
          vertical: context.responsive.sp(10),
        ),
        decoration: BoxDecoration(
          color: isCurrent
              ? stage.color.withValues(alpha: 0.1)
              : const Color(0xFF1E233D).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(context.responsive.sp(10)),
          border: Border.all(
            color: isCurrent
                ? stage.color.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            // Status indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: context.responsive.sp(28),
              height: context.responsive.sp(28),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? Colors.green.withValues(alpha: 0.15)
                    : isCurrent
                        ? stage.color.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.04),
              ),
              child: isCompleted
                  ? Icon(
                      Icons.check_rounded,
                      color: Colors.green,
                      size: context.responsive.sp(14),
                    )
                  : isCurrent
                      ? AnimatedBuilder(
                          animation: pulseAnim,
                          builder: (_, __) => Icon(
                            stage.icon,
                            color: stage.color,
                            size: context.responsive.sp(14),
                          ),
                        )
                      : Icon(
                          stage.icon,
                          color: Colors.white24,
                          size: context.responsive.sp(14),
                        ),
            ),

            SizedBox(width: context.responsive.wp(12)),

            // Title
            Expanded(
              child: Text(
                stage.title,
                style: TextStyle(
                  color: isCompleted
                      ? Colors.green
                      : isCurrent
                          ? Colors.white
                          : Colors.white30,
                  fontSize: context.responsive.sp(12.5),
                  fontWeight:
                      isCurrent ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),

            // Status text
            if (isCompleted)
              Text(
                'Done',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: context.responsive.sp(11),
                  fontWeight: FontWeight.w600,
                ),
              )
            else if (isCurrent)
              _DotsLoader(color: stage.color)
            else
              Text(
                'Waiting',
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: context.responsive.sp(11),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Animated dots loader ───────────────────────────────────────────────────────

class _DotsLoader extends StatefulWidget {
  final Color color;
  const _DotsLoader({required this.color});

  @override
  State<_DotsLoader> createState() => _DotsLoaderState();
}

class _DotsLoaderState extends State<_DotsLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final frame = (_ctrl.value * 4).floor() % 4;
        final dots = '.' * (frame + 1);
        return Text(
          dots,
          style: TextStyle(
            color: widget.color,
            fontSize: context.responsive.sp(14),
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        );
      },
    );
  }
}

// ── Upload Form View ───────────────────────────────────────────────────────────

class _UploadFormView extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController authorController;
  final bool hasFile;
  final String? selectedFileName;
  final VoidCallback onPickFile;
  final VoidCallback onSubmit;

  const _UploadFormView({
    super.key,
    required this.formKey,
    required this.titleController,
    required this.authorController,
    required this.hasFile,
    required this.selectedFileName,
    required this.onPickFile,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: context.responsive.wp(24),
        vertical: context.responsive.sp(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          _DragHandle(),
          SizedBox(height: context.responsive.sp(16)),

          // Title
          Center(
            child: Text(
              'Add Book to Library',
              style: TextStyle(
                color: Colors.white,
                fontSize: context.responsive.sp(18),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          SizedBox(height: context.responsive.sp(24)),

          // ── What Happens Next panel — shown FIRST so user reads before uploading
          _WhatHappensNextPanel(),

          SizedBox(height: context.responsive.sp(24)),

          // ── PDF Upload Section ──────────────────────────────────────────────
          GestureDetector(
            onTap: onPickFile,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: EdgeInsets.all(context.responsive.sp(24)),
              decoration: BoxDecoration(
                color: hasFile
                    ? const Color(0xFFB062FF).withValues(alpha: 0.1)
                    : const Color(0xFF1E233D),
                borderRadius: BorderRadius.circular(context.responsive.sp(16)),
                border: Border.all(
                  color: hasFile
                      ? const Color(0xFFB062FF).withValues(alpha: 0.5)
                      : Colors.white10,
                  width: hasFile ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(context.responsive.sp(16)),
                    decoration: BoxDecoration(
                      color: hasFile
                          ? const Color(0xFFB062FF).withValues(alpha: 0.2)
                          : const Color(0xFF381A5D),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      hasFile
                          ? Icons.check_circle_outline
                          : Icons.file_upload_outlined,
                      color: const Color(0xFFB062FF),
                      size: context.responsive.sp(24),
                    ),
                  ),
                  SizedBox(height: context.responsive.sp(12)),
                  if (hasFile) ...[
                    Text(
                      selectedFileName ?? 'PDF Selected',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: context.responsive.sp(14),
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: context.responsive.sp(4)),
                    Text(
                      'Tap to select a different file',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: context.responsive.sp(12),
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Upload PDF',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: context.responsive.sp(16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: context.responsive.sp(4)),
                    Text(
                      'Tap to browse for your PDF file',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: context.responsive.sp(12),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: context.responsive.sp(4)),
                    Text(
                      'Max 50MB — AI will create chapters automatically',
                      style: TextStyle(
                        color: Colors.white30,
                        fontSize: context.responsive.sp(10),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),

          SizedBox(height: context.responsive.sp(20)),

          // ── Book Details Form ───────────────────────────────────────────────
          Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Book Title',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: context.responsive.sp(12),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: context.responsive.sp(8)),
                CustomTextField(
                  controller: titleController,
                  hintText: 'Enter book title',
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Title is required' : null,
                ),

                SizedBox(height: context.responsive.sp(16)),

                Text(
                  'Author (optional)',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: context.responsive.sp(12),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: context.responsive.sp(8)),
                CustomTextField(
                  controller: authorController,
                  hintText: 'Enter author name',
                ),

                SizedBox(height: context.responsive.sp(24)),

                // ── Upload Button ─────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onSubmit,
                    icon: const Icon(
                      Icons.cloud_upload_outlined,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Upload & Process Book',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB062FF),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: context.responsive.sp(16),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(context.responsive.sp(12)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: context.responsive.sp(8)),
        ],
      ),
    );
  }
}

// ── What Happens Next Panel ───────────────────────────────────────────────────

class _WhatHappensNextPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ────────────────────────────────────────────────────
        Row(
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFB062FF), Color(0xFF3861FB)],
              ).createShader(bounds),
              child: Text(
                '✦',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: context.responsive.sp(14),
                ),
              ),
            ),
            SizedBox(width: context.responsive.wp(8)),
            Text(
              'What you unlock instantly',
              style: TextStyle(
                color: Colors.white,
                fontSize: context.responsive.sp(15),
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),

        SizedBox(height: context.responsive.sp(12)),

        // ── Feature cards — 2 × 2 ─────────────────────────────────────────────
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: context.responsive.wp(10),
          mainAxisSpacing: context.responsive.sp(10),
          childAspectRatio: 1.55,
          children: _featureItems
              .map((item) => _FeatureChip(item: item))
              .toList(),
        ),

        SizedBox(height: context.responsive.sp(14)),

        // ── Tips card ─────────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(context.responsive.sp(14)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFFB800).withValues(alpha: 0.10),
                const Color(0xFFFF6B00).withValues(alpha: 0.06),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(context.responsive.sp(14)),
            border: Border.all(
              color: const Color(0xFFFFB800).withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon bubble
              Container(
                width: context.responsive.sp(32),
                height: context.responsive.sp(32),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB800).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(context.responsive.sp(8)),
                ),
                child: Center(
                  child: Text(
                    '\u{1F4A1}',
                    style: TextStyle(fontSize: context.responsive.sp(15)),
                  ),
                ),
              ),
              SizedBox(width: context.responsive.wp(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pro tip for best results',
                      style: TextStyle(
                        color: const Color(0xFFFFB800),
                        fontSize: context.responsive.sp(11.5),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                    ),
                    SizedBox(height: context.responsive.sp(3)),
                    Text(
                      'Use a searchable PDF with a Table of Contents \u2014 AI chapter detection works like magic. Processing takes ~1\u20132 min.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: context.responsive.sp(11),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Feature Chip (redesigned) ─────────────────────────────────────────────────

const _chipGradients = [
  [Color(0xFFB062FF), Color(0xFF6E3FD1)],
  [Color(0xFF3861FB), Color(0xFF2146CC)],
  [Color(0xFF10B981), Color(0xFF0D8F64)],
  [Color(0xFFE83E8C), Color(0xFFC0246E)],
];

class _FeatureChip extends StatelessWidget {
  final _FeatureItem item;
  const _FeatureChip({required this.item});

  @override
  Widget build(BuildContext context) {
    final index = _featureItems.indexOf(item);
    final gradColors =
        _chipGradients[index.clamp(0, _chipGradients.length - 1)];

    return Container(
      padding: EdgeInsets.all(context.responsive.sp(12)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gradColors[0].withValues(alpha: 0.14),
            gradColors[1].withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(context.responsive.sp(14)),
        border: Border.all(
          color: gradColors[0].withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Emoji badge
          Container(
            padding: EdgeInsets.all(context.responsive.sp(6)),
            decoration: BoxDecoration(
              color: gradColors[0].withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(context.responsive.sp(8)),
            ),
            child: Text(
              item.emoji,
              style: TextStyle(fontSize: context.responsive.sp(16)),
            ),
          ),
          // Text block
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: context.responsive.sp(12),
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: context.responsive.sp(2)),
              Text(
                item.description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: context.responsive.sp(10),
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Drag Handle ────────────────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: context.responsive.wp(40),
        height: context.responsive.sp(4),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}