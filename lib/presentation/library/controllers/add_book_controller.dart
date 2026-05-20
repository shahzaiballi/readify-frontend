import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../../data/network/api_client.dart';

// ── Upload flow states ────────────────────────────────────────────────────────

sealed class UploadFlowState {
  const UploadFlowState();
}

class UploadIdle extends UploadFlowState {
  const UploadIdle();
}

class UploadInProgress extends UploadFlowState {
  final String stage;
  final double progress;
  const UploadInProgress({required this.stage, this.progress = 0.0});
}

class UploadAwaitingConfirm extends UploadFlowState {
  final String uploadId;
  final String bookId;
  final List<Map<String, dynamic>> chapters;
  const UploadAwaitingConfirm({
    required this.uploadId,
    required this.bookId,
    required this.chapters,
  });
}

class UploadBuildingSchedule extends UploadFlowState {
  final String bookId;
  const UploadBuildingSchedule({required this.bookId});
}

class UploadComplete extends UploadFlowState {
  final String bookId;
  final String bookTitle;
  const UploadComplete({required this.bookId, required this.bookTitle});
}

class UploadFailed extends UploadFlowState {
  final String message;
  const UploadFailed({required this.message});
}

// ── Controller ────────────────────────────────────────────────────────────────

class AddBookController extends Notifier<UploadFlowState> {
  Timer? _pollTimer;

  @override
  UploadFlowState build() {
    ref.onDispose(() => _pollTimer?.cancel());
    return const UploadIdle();
  }

  void reset() {
    _pollTimer?.cancel();
    state = const UploadIdle();
  }

  Future<void> uploadBook({
    required String title,
    required String author,
    String? filePath,
    Uint8List? fileBytes,
    String? fileName,
    required String readingMode,
    required int pagesPerDay,
  }) async {
    state = const UploadInProgress(stage: 'Uploading your PDF...', progress: 0.1);

    try {
      final response = await ApiClient.instance.uploadFile(
        endpoint: '/api/v1/books/upload/',
        fieldName: 'pdf_file',
        filePath: filePath,
        fileBytes: fileBytes,
        fileName: fileName ?? 'book.pdf',
        fields: {
          'title': title,
          if (author.trim().isNotEmpty) 'author': author.trim(),
          'reading_mode': readingMode,
          'pages_per_day': pagesPerDay.toString(),
        },
      );

      debugPrint('📤 Upload response: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 202) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final uploadId = data['id'].toString();
        state = UploadInProgress(
          stage: 'Extracting text from PDF...',
          progress: 0.25,
        );
        _startPolling(uploadId);
      } else {
        final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        final msg = body['title']?.first ?? body['detail'] ?? body['error'] ?? 'Upload failed';
        state = UploadFailed(message: msg.toString());
      }
    } catch (e) {
      debugPrint('❌ Upload error: $e');
      state = UploadFailed(message: e.toString());
    }
  }

  void _startPolling(String uploadId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      await _checkStatus(uploadId);
    });
  }

  Future<void> _checkStatus(String uploadId) async {
    try {
      final data = await ApiClient.instance.get(
        '/api/v1/books/upload/$uploadId/status/',
      ) as Map<String, dynamic>;

      final processingStatus = data['processingStatus'] as String? ?? '';
      final processingStage = data['processingStage'] as String? ?? '';
      final bookId = data['bookId'] as String?;

      switch (processingStatus) {
        case 'processing':
          state = UploadInProgress(
            stage: _stageLabel(processingStage),
            progress: _stageProgress(processingStage),
          );

        case 'awaiting_confirm':
          _pollTimer?.cancel();
          if (bookId != null) {
            final chapters = await _fetchAIChapters(bookId);
            state = UploadAwaitingConfirm(
              uploadId: uploadId,
              bookId: bookId,
              chapters: chapters,
            );
          }

        case 'scheduling':
          state = UploadBuildingSchedule(bookId: bookId ?? '');

        case 'completed':
          _pollTimer?.cancel();
          state = UploadComplete(
            bookId: bookId ?? '',
            bookTitle: data['title'] ?? '',
          );

        case 'failed':
          _pollTimer?.cancel();
          state = UploadFailed(
            message: data['error_message'] ?? 'Processing failed. Please try again.',
          );
      }
    } catch (e) {
      debugPrint('⚠️ Poll error (will retry): $e');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAIChapters(String bookId) async {
    try {
      final data = await ApiClient.instance.get(
        '/api/v1/intelligence/books/$bookId/chapters/',
      ) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  Future<void> confirmChapters({
    required String bookId,
    required List<Map<String, dynamic>> editedChapters,
    String readingMode = 'deep',
    int pagesPerDay = 10,
  }) async {
    if (state is! UploadAwaitingConfirm) return;
    final current = state as UploadAwaitingConfirm;

    state = UploadBuildingSchedule(bookId: bookId);

    try {
      await ApiClient.instance.post(
        '/api/v1/intelligence/books/$bookId/chapters/confirm/',
        body: {
          'chapters': editedChapters,
          'reading_mode': readingMode,
          'pages_per_day': pagesPerDay,
        },
      );
      // Restart polling for schedule completion
      _startPolling(current.uploadId);
    } catch (e) {
      state = UploadFailed(message: 'Failed to confirm chapters: $e');
    }
  }

  String _stageLabel(String stage) {
    switch (stage) {
      case 'extracting':
        return 'Extracting text from PDF...';
      case 'detecting_bookmarks':
      case 'detecting_toc':
      case 'detecting_chapters':
        return 'Detecting chapter structure...';
      case 'awaiting_confirm':
        return 'Chapters detected — review needed';
      case 'building_schedule':
        return 'Building your reading schedule...';
      case 'generating_brief':
        return 'Generating book brief...';
      default:
        return 'Processing your book...';
    }
  }

  double _stageProgress(String stage) {
    switch (stage) {
      case 'extracting':
        return 0.3;
      case 'detecting_bookmarks':
      case 'detecting_toc':
      case 'detecting_chapters':
        return 0.55;
      case 'building_schedule':
        return 0.75;
      case 'generating_brief':
        return 0.9;
      default:
        return 0.4;
    }
  }
}

final addBookControllerProvider = NotifierProvider<AddBookController, UploadFlowState>(
  AddBookController.new,
);
