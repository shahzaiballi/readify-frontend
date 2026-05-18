import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../auth/widgets/custom_text_field.dart';
import '../controllers/add_book_controller.dart';
import '../controllers/library_controller.dart';
import '../../profile/controllers/reading_plan_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

// â”€â”€ What happens next features â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
    emoji: 'ðŸ¤–',
    title: 'AI Chapters',
    description: 'Auto-detected from your PDF',
  ),
  _FeatureItem(
    emoji: 'â±ï¸',
    title: '5-min Chunks',
    description: 'Bite-sized, never overwhelming',
  ),
  _FeatureItem(
    emoji: 'ðŸ§ ',
    title: 'Flashcards',
    description: 'Key concepts, auto-generated',
  ),
  _FeatureItem(
    emoji: 'ðŸ“',
    title: 'Summaries',
    description: 'Chapter insights at a glance',
  ),
];

// â”€â”€ Main Page â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class AddBookPage extends ConsumerStatefulWidget {
  const AddBookPage({super.key});

  @override
  ConsumerState<AddBookPage> createState() => _AddBookPageState();
}

class _AddBookPageState extends ConsumerState<AddBookPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();

  String? _selectedFilePath;
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  // â”€â”€ File picker â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

  // â”€â”€ Submit â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

    final plan = ref.read(readingPlanProvider);
    await ref.read(addBookControllerProvider.notifier).uploadBook(
      title: _titleController.text.trim(),
      author: _authorController.text.trim(),
      filePath: _selectedFilePath,
      fileBytes: _selectedFileBytes,
      fileName: _selectedFileName,
      readingMode: plan.readingMode,
      dailyMinutes: plan.dailyMinutes,
    );
  }

  // â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  bool get _hasFile =>
      _selectedFilePath != null || _selectedFileBytes != null;

  // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    final flowState = ref.watch(addBookControllerProvider);

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
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: switch (flowState) {
          UploadIdle() => _UploadFormView(
              key: const ValueKey('form'),
              formKey: _formKey,
              titleController: _titleController,
              authorController: _authorController,
              hasFile: _hasFile,
              selectedFileName: _selectedFileName,
              onPickFile: _handleFileUpload,
              onSubmit: _submitForm,
            ),
          UploadInProgress(stage: final stage, progress: final progress) =>
            _ProcessingStateView(
              key: const ValueKey('processing'),
              stageText: stage,
              progress: progress,
            ),
          UploadAwaitingConfirm(
            bookId: final bookId,
            uploadId: final uploadId,
            chapters: final chapters,
          ) =>
            _ConfirmChaptersView(
              key: const ValueKey('confirm'),
              bookId: bookId,
              uploadId: uploadId,
              chapters: chapters,
              onConfirm: (edited, mode, minutes) => ref
                  .read(addBookControllerProvider.notifier)
                  .confirmChapters(
                    bookId: bookId,
                    editedChapters: edited,
                    readingMode: mode,
                    dailyMinutes: minutes,
                  ),
            ),
          UploadBuildingSchedule() => _ProcessingStateView(
              key: const ValueKey('scheduling'),
              stageText: 'Building your reading schedule...',
              progress: 0.85,
            ),
          UploadComplete(bookId: final bookId, bookTitle: final title) =>
            _SuccessView(
              key: const ValueKey('success'),
              bookId: bookId,
              bookTitle: title,
              onOpen: () {
                ref.invalidate(rawLibraryProvider);
                Navigator.of(context).pop();
                context.push('/book_detail/$bookId');
              },
              onClose: () {
                ref.invalidate(rawLibraryProvider);
                ref
                    .read(addBookControllerProvider.notifier)
                    .reset();
                Navigator.of(context).pop();
              },
            ),
          UploadFailed(message: final msg) => _ErrorView(
              key: const ValueKey('error'),
              message: msg,
              onRetry: () =>
                  ref.read(addBookControllerProvider.notifier).reset(),
            ),
        },
      ),
    );
  }
}

// â”€â”€ Processing State View â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ProcessingStateView extends StatefulWidget {
  final String stageText;
  final double progress;

  const _ProcessingStateView({
    super.key,
    required this.stageText,
    required this.progress,
  });

  @override
  State<_ProcessingStateView> createState() => _ProcessingStateViewState();
}

class _ProcessingStateViewState extends State<_ProcessingStateView>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late Animation<double> _pulseAnim;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
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
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percent = (widget.progress * 100).toInt();
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: context.responsive.wp(24),
        vertical: context.responsive.sp(8),
      ),
      child: Column(
        children: [
          _DragHandle(),
          SizedBox(height: context.responsive.sp(32)),
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, child) =>
                Transform.scale(scale: _pulseAnim.value, child: child),
            child: Container(
              width: context.responsive.sp(80),
              height: context.responsive.sp(80),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFFB062FF).withValues(alpha: 0.3),
                  const Color(0xFFB062FF).withValues(alpha: 0.07),
                ]),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFB062FF).withValues(alpha: 0.35),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Icon(Icons.auto_awesome_rounded,
                  color: const Color(0xFFB062FF),
                  size: context.responsive.sp(36)),
            ),
          ),
          SizedBox(height: context.responsive.sp(20)),
          Text(
            'Processing your book',
            style: TextStyle(
              color: Colors.white,
              fontSize: context.responsive.sp(20),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.responsive.sp(6)),
          Text(
            widget.stageText,
            style: TextStyle(
                color: Colors.white60, fontSize: context.responsive.sp(13)),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.responsive.sp(32)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progress',
                  style: TextStyle(
                      color: Colors.white60,
                      fontSize: context.responsive.sp(12))),
              Text('$percent%',
                  style: TextStyle(
                      color: const Color(0xFFB062FF),
                      fontSize: context.responsive.sp(13),
                      fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: context.responsive.sp(10)),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Container(
              height: context.responsive.sp(8),
              color: Colors.white.withValues(alpha: 0.08),
              child: AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                widthFactor: widget.progress.clamp(0.0, 1.0),
                alignment: Alignment.centerLeft,
                child: AnimatedBuilder(
                  animation: _shimmerAnim,
                  builder: (_, _) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFB062FF),
                          const Color(0xFFB062FF).withValues(alpha: 0.7),
                          Colors.white.withValues(alpha: 0.9),
                          const Color(0xFFB062FF).withValues(alpha: 0.7),
                          const Color(0xFFB062FF),
                        ],
                        stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                        begin: Alignment(_shimmerAnim.value - 1, 0),
                        end: Alignment(_shimmerAnim.value, 0),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: context.responsive.sp(24)),
          Container(
            padding: EdgeInsets.all(context.responsive.sp(14)),
            decoration: BoxDecoration(
              color: const Color(0xFFB062FF).withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(context.responsive.sp(12)),
              border: Border.all(
                  color: const Color(0xFFB062FF).withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: const Color(0xFFB062FF),
                    size: context.responsive.sp(16)),
                SizedBox(width: context.responsive.wp(10)),
                Expanded(
                  child: Text(
                    'You can close this and the processing will continue in the background.',
                    style: TextStyle(
                        color: Colors.white60,
                        fontSize: context.responsive.sp(11.5),
                        height: 1.5),
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

// â”€â”€ Confirm Chapters View â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ConfirmChaptersView extends ConsumerStatefulWidget {
  final String bookId;
  final String uploadId;
  final List<Map<String, dynamic>> chapters;
  final Future<void> Function(
    List<Map<String, dynamic>> edited,
    String readingMode,
    int dailyMinutes,
  ) onConfirm;

  const _ConfirmChaptersView({
    super.key,
    required this.bookId,
    required this.uploadId,
    required this.chapters,
    required this.onConfirm,
  });

  @override
  ConsumerState<_ConfirmChaptersView> createState() =>
      _ConfirmChaptersViewState();
}

class _ConfirmChaptersViewState
    extends ConsumerState<_ConfirmChaptersView> {
  late List<TextEditingController> _titleControllers;
  bool _confirming = false;
  String _readingMode = 'deep';
  int _dailyMinutes = 30;

  @override
  void initState() {
    super.initState();
    _titleControllers = widget.chapters.map((ch) {
      return TextEditingController(text: ch['title']?.toString() ?? '');
    }).toList();
    final plan = ref.read(readingPlanProvider);
    _readingMode = plan.readingMode;
    _dailyMinutes = plan.dailyMinutes;
  }

  @override
  void dispose() {
    for (final c in _titleControllers) c.dispose();
    super.dispose();
  }

  Future<void> _onConfirm() async {
    setState(() => _confirming = true);
    final edited = widget.chapters.asMap().entries.map((e) {
      return {
        'chapter_number': e.value['chapterNumber'] ?? e.value['chapter_number'] ?? (e.key + 1),
        'title': _titleControllers[e.key].text.trim(),
      };
    }).toList();
    await widget.onConfirm(edited, _readingMode, _dailyMinutes);
  }

  @override
  Widget build(BuildContext context) {
    final source = widget.chapters.isNotEmpty
        ? (widget.chapters.first['chapterSource'] ?? widget.chapters.first['chapter_source'] ?? 'ai')
        : 'ai';

    final sourceLabel = switch (source) {
      'bookmarks' => 'detected from PDF bookmarks',
      'text_toc' => 'detected from Table of Contents',
      'ai_generated' => 'detected by AI analysis',
      _ => 'auto-detected',
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DragHandle(),
        SizedBox(height: context.responsive.sp(16)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.responsive.wp(24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(context.responsive.sp(8)),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_circle_outline,
                        color: const Color(0xFF10B981),
                        size: context.responsive.sp(20)),
                  ),
                  SizedBox(width: context.responsive.wp(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Review Your Chapters',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: context.responsive.sp(17),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.chapters.length} chapters $sourceLabel',
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: context.responsive.sp(12)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.responsive.sp(6)),
              Text(
                'Rename any chapter if needed, then confirm to build your reading schedule.',
                style: TextStyle(
                    color: Colors.white38, fontSize: context.responsive.sp(12)),
              ),
            ],
          ),
        ),
        SizedBox(height: context.responsive.sp(12)),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.38,
          ),
          child: ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.symmetric(
                horizontal: context.responsive.wp(24)),
            itemCount: widget.chapters.length,
            itemBuilder: (context, i) {
              final ch = widget.chapters[i];
              final num = ch['chapterNumber'] ?? ch['chapter_number'] ?? (i + 1);
              return Padding(
                padding: EdgeInsets.only(bottom: context.responsive.sp(8)),
                child: Row(
                  children: [
                    Container(
                      width: context.responsive.sp(28),
                      height: context.responsive.sp(28),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB062FF).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$num',
                          style: TextStyle(
                            color: const Color(0xFFB062FF),
                            fontSize: context.responsive.sp(11),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: context.responsive.wp(10)),
                    Expanded(
                      child: TextField(
                        controller: _titleControllers[i],
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: context.responsive.sp(13)),
                        decoration: InputDecoration(
                          hintText: 'Chapter $num',
                          hintStyle: const TextStyle(color: Colors.white30),
                          filled: true,
                          fillColor: const Color(0xFF1E233D),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: context.responsive.wp(12),
                            vertical: context.responsive.sp(10),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                context.responsive.sp(8)),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        SizedBox(height: context.responsive.sp(12)),
        _ReadingPrefsSelector(
          selectedMode: _readingMode,
          dailyMinutes: _dailyMinutes,
          onModeChanged: (m) => setState(() => _readingMode = m),
          onMinutesChanged: (v) => setState(() => _dailyMinutes = v),
        ),
        SizedBox(height: context.responsive.sp(12)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.responsive.wp(24)),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _confirming ? null : _onConfirm,
              icon: _confirming
                  ? SizedBox(
                      width: context.responsive.sp(16),
                      height: context.responsive.sp(16),
                      child: const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_rounded, color: Colors.white),
              label: Text(
                _confirming
                    ? 'Confirming...'
                    : 'Confirm & Build Reading Schedule',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding:
                    EdgeInsets.symmetric(vertical: context.responsive.sp(14)),
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(context.responsive.sp(12))),
              ),
            ),
          ),
        ),
        SizedBox(height: context.responsive.sp(8)),
      ],
    );
  }
}

// â”€â”€ Success View â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

// ── Reading Preferences Selector ──────────────────────────────────────────────

class _ReadingPrefsSelector extends StatelessWidget {
  final String selectedMode;
  final int dailyMinutes;
  final ValueChanged<String> onModeChanged;
  final ValueChanged<int> onMinutesChanged;

  const _ReadingPrefsSelector({
    required this.selectedMode,
    required this.dailyMinutes,
    required this.onModeChanged,
    required this.onMinutesChanged,
  });

  static const _modes = ['skim', 'concept', 'deep', 'exam'];
  static const _modeLabels = {
    'skim': 'Skim',
    'concept': 'Concept',
    'deep': 'Deep',
    'exam': 'Exam',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.responsive.wp(24)),
      child: Container(
        padding: EdgeInsets.all(context.responsive.sp(12)),
        decoration: BoxDecoration(
          color: const Color(0xFF1E233D),
          borderRadius: BorderRadius.circular(context.responsive.sp(12)),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reading Preferences',
              style: TextStyle(
                color: Colors.white70,
                fontSize: context.responsive.sp(12),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: context.responsive.sp(10)),
            Row(
              children: _modes.map((mode) {
                final selected = selectedMode == mode;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onModeChanged(mode),
                    child: Container(
                      margin: EdgeInsets.only(
                        right: mode != _modes.last
                            ? context.responsive.wp(6)
                            : 0,
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: context.responsive.sp(7),
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFB062FF)
                            : const Color(0xFF0F1626),
                        borderRadius:
                            BorderRadius.circular(context.responsive.sp(8)),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFFB062FF)
                              : Colors.white12,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _modeLabels[mode] ?? mode,
                          style: TextStyle(
                            color:
                                selected ? Colors.white : Colors.white54,
                            fontSize: context.responsive.sp(11),
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: context.responsive.sp(10)),
            Row(
              children: [
                Text(
                  'Daily reading:',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: context.responsive.sp(12),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    if (dailyMinutes > 5) onMinutesChanged(dailyMinutes - 5);
                  },
                  child: Container(
                    width: context.responsive.sp(28),
                    height: context.responsive.sp(28),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1626),
                      borderRadius:
                          BorderRadius.circular(context.responsive.sp(6)),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Icon(Icons.remove,
                        color: Colors.white54,
                        size: context.responsive.sp(14)),
                  ),
                ),
                SizedBox(width: context.responsive.wp(10)),
                Text(
                  '$dailyMinutes min',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.responsive.sp(13),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: context.responsive.wp(10)),
                GestureDetector(
                  onTap: () {
                    if (dailyMinutes < 180) onMinutesChanged(dailyMinutes + 5);
                  },
                  child: Container(
                    width: context.responsive.sp(28),
                    height: context.responsive.sp(28),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1626),
                      borderRadius:
                          BorderRadius.circular(context.responsive.sp(6)),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Icon(Icons.add,
                        color: Colors.white54,
                        size: context.responsive.sp(14)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final String bookId;
  final String bookTitle;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  const _SuccessView({
    super.key,
    required this.bookId,
    required this.bookTitle,
    required this.onOpen,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: context.responsive.wp(24),
        vertical: context.responsive.sp(8),
      ),
      child: Column(
        children: [
          _DragHandle(),
          SizedBox(height: context.responsive.sp(32)),
          Container(
            width: context.responsive.sp(80),
            height: context.responsive.sp(80),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(Icons.check_rounded,
                color: const Color(0xFF10B981),
                size: context.responsive.sp(40)),
          ),
          SizedBox(height: context.responsive.sp(20)),
          Text(
            'Book Ready!',
            style: TextStyle(
              color: Colors.white,
              fontSize: context.responsive.sp(22),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: context.responsive.sp(8)),
          Text(
            bookTitle.isNotEmpty
                ? '"$bookTitle" has been processed and added to your library.'
                : 'Your book has been processed and added to your library.',
            style: TextStyle(
                color: Colors.white60, fontSize: context.responsive.sp(13)),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.responsive.sp(32)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onOpen,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB062FF),
                padding:
                    EdgeInsets.symmetric(vertical: context.responsive.sp(14)),
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(context.responsive.sp(12))),
              ),
              child: const Text('Open Book',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          SizedBox(height: context.responsive.sp(10)),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onClose,
              child: Text('Go to Library',
                  style: TextStyle(
                      color: Colors.white54,
                      fontSize: context.responsive.sp(13))),
            ),
          ),
          SizedBox(height: context.responsive.sp(8)),
        ],
      ),
    );
  }
}

// â”€â”€ Error View â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: context.responsive.wp(24),
        vertical: context.responsive.sp(8),
      ),
      child: Column(
        children: [
          _DragHandle(),
          SizedBox(height: context.responsive.sp(32)),
          Container(
            width: context.responsive.sp(72),
            height: context.responsive.sp(72),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.redAccent.withValues(alpha: 0.12),
            ),
            child: Icon(Icons.error_outline_rounded,
                color: Colors.redAccent, size: context.responsive.sp(36)),
          ),
          SizedBox(height: context.responsive.sp(20)),
          Text(
            'Upload Failed',
            style: TextStyle(
              color: Colors.white,
              fontSize: context.responsive.sp(20),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: context.responsive.sp(10)),
          Text(
            message,
            style: TextStyle(
                color: Colors.white54, fontSize: context.responsive.sp(13)),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.responsive.sp(28)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: const Text('Try Again',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB062FF),
                padding:
                    EdgeInsets.symmetric(vertical: context.responsive.sp(14)),
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(context.responsive.sp(12))),
              ),
            ),
          ),
          SizedBox(height: context.responsive.sp(8)),
        ],
      ),
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

          // â”€â”€ What Happens Next panel â€” shown FIRST so user reads before uploading
          _WhatHappensNextPanel(),

          SizedBox(height: context.responsive.sp(24)),

          // â”€â”€ PDF Upload Section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                      'Max 50MB â€” AI will create chapters automatically',
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

          // â”€â”€ Book Details Form â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

                // â”€â”€ Upload Button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

// â”€â”€ What Happens Next Panel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _WhatHappensNextPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // â”€â”€ Section header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Row(
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFB062FF), Color(0xFF3861FB)],
              ).createShader(bounds),
              child: Text(
                'âœ¦',
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

        // â”€â”€ Feature cards â€” 2 Ã— 2 â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

        // â”€â”€ Tips card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

// â”€â”€ Feature Chip (redesigned) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

// â”€â”€ Drag Handle â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
