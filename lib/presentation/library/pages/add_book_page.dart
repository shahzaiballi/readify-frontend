import 'dart:io';
import 'dart:typed_data'; // ✅ Added for Uint8List
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

class AddBookPage extends ConsumerStatefulWidget {
  const AddBookPage({super.key});

  @override
  ConsumerState<AddBookPage> createState() => _AddBookPageState();
}

class _AddBookPageState extends ConsumerState<AddBookPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();

  /// ✅ Fixed: Handle both file path (mobile) AND bytes (web)
  String? _selectedFilePath;
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  Future<void> _handleFileUpload() async {
    // ✅ Only request permissions on mobile (NOT web)
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

    // ✅ Works on ALL platforms (including web)
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
        _selectedFilePath = file.path; // null on web ✅
        _selectedFileBytes = file.bytes; // ✅ bytes on web/mobile
        _selectedFileName = file.name;
      });
    }
  }

  /// ✅ Fixed: Check BOTH path and bytes for web support
  Future<void> _submitForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // ✅ Fixed validation for web/mobile
    if (_selectedFilePath == null && _selectedFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a PDF file to upload.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    await ref.read(addBookControllerProvider.notifier).uploadBook(
      title: _titleController.text.trim(),
      author: _authorController.text.trim(),
      filePath: _selectedFilePath,
      fileBytes: _selectedFileBytes,
      fileName: _selectedFileName,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(addBookControllerProvider, (previous, next) {
      if (!next.isLoading && next.hasValue && previous is AsyncLoading) {
        // ✅ Trigger library refresh so the new book appears immediately
        ref.invalidate(rawLibraryProvider);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '📚 Upload started! Your book will appear in your library in 1-2 minutes '
              'once AI processing is complete.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
        context.pop();
      } else if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${next.error}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    });

    final isLoading = ref.watch(addBookControllerProvider).isLoading;
    final hasFile = _selectedFilePath != null || _selectedFileBytes != null; // ✅ Fixed UI state

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1626),
        borderRadius: BorderRadius.vertical(top: Radius.circular(context.responsive.sp(24))),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + context.responsive.sp(24),
        top: context.responsive.sp(24),
        left: context.responsive.wp(24),
        right: context.responsive.wp(24),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              width: context.responsive.wp(40),
              height: context.responsive.sp(4),
              margin: EdgeInsets.only(bottom: context.responsive.sp(24)),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            // Title
            Text(
              'Add Book to Library',
              style: TextStyle(
                color: Colors.white,
                fontSize: context.responsive.sp(18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: context.responsive.sp(24)),

            // ── PDF Upload Section ──
            GestureDetector(
              onTap: isLoading ? null : _handleFileUpload,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: EdgeInsets.all(context.responsive.sp(24)),
                decoration: BoxDecoration(
                  color: hasFile ? const Color(0xFFB062FF).withOpacity(0.1) : const Color(0xFF1E233D),
                  borderRadius: BorderRadius.circular(context.responsive.sp(16)),
                  border: Border.all(
                    color: hasFile ? const Color(0xFFB062FF).withOpacity(0.5) : Colors.white10,
                    width: hasFile ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(context.responsive.sp(16)),
                      decoration: BoxDecoration(
                        color: hasFile ? const Color(0xFFB062FF).withOpacity(0.2) : const Color(0xFF381A5D),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        hasFile ? Icons.check_circle_outline : Icons.file_upload_outlined,
                        color: const Color(0xFFB062FF),
                        size: context.responsive.sp(24),
                      ),
                    ),
                    SizedBox(height: context.responsive.sp(12)),

                    if (hasFile) ...[
                      Text(
                        _selectedFileName ?? 'PDF Selected',
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

            SizedBox(height: context.responsive.sp(24)),

            // ── Book Details Form ──
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Book Title',
                    style: TextStyle(color: Colors.white70, fontSize: context.responsive.sp(12)),
                  ),
                  SizedBox(height: context.responsive.sp(8)),
                  CustomTextField(
                    controller: _titleController,
                    hintText: 'Enter book title',
                    validator: (value) => value == null || value.isEmpty ? 'Title is required' : null,
                  ),

                  SizedBox(height: context.responsive.sp(16)),

                  Text(
                    'Author (optional)',
                    style: TextStyle(color: Colors.white70, fontSize: context.responsive.sp(12)),
                  ),
                  SizedBox(height: context.responsive.sp(8)),
                  CustomTextField(
                    controller: _authorController,
                    hintText: 'Enter author name',
                  ),

                  SizedBox(height: context.responsive.sp(24)),

                  // Upload Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : _submitForm,
                      icon: isLoading
                          ? SizedBox(
                              width: context.responsive.sp(18),
                              height: context.responsive.sp(18),
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: context.responsive.sp(2),
                              ),
                            )
                          : Icon(Icons.cloud_upload_outlined, size: context.responsive.sp(18)),
                      label: Text(
                        isLoading ? 'Uploading...' : 'Upload & Process Book',
                        style: TextStyle(
                          fontSize: context.responsive.sp(14),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB062FF),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFB062FF).withOpacity(0.5),
                        padding: EdgeInsets.symmetric(vertical: context.responsive.sp(16)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(context.responsive.sp(12)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
