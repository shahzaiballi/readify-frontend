import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/repositories/book_repository.dart';
import '../../../data/repositories/book_repository_impl.dart';
import 'reading_session_state.dart';

final bookRepositoryProvider =
    Provider<BookRepository>((ref) => BookRepositoryImpl());

class ReadingSessionParams {
  final String bookId;
  final String chapterId;
  final int initialChunkIndex;

  const ReadingSessionParams({
    required this.bookId,
    required this.chapterId,
    required this.initialChunkIndex,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingSessionParams &&
          runtimeType == other.runtimeType &&
          bookId == other.bookId &&
          chapterId == other.chapterId &&
          initialChunkIndex == other.initialChunkIndex;

  @override
  int get hashCode => Object.hash(bookId, chapterId, initialChunkIndex);
}

class ReadingSessionController
    extends AutoDisposeFamilyAsyncNotifier<ReadingSessionState, ReadingSessionParams> {
  Timer? _timer;

  /// Wall-clock seconds elapsed in the current chunk (for session recording).
  int _elapsedSeconds = 0;

  @override
  FutureOr<ReadingSessionState> build(ReadingSessionParams arg) async {
    ref.onDispose(() {
      _timer?.cancel();
    });

    final chunks = await ref
        .read(bookRepositoryProvider)
        .getChunks(arg.bookId, arg.chapterId);

    final safeIndex = arg.initialChunkIndex.clamp(
      0,
      chunks.isEmpty ? 0 : chunks.length - 1,
    );

    final initialChunk =
        chunks.isNotEmpty ? chunks[safeIndex] : null;
    final initialSeconds = (initialChunk?.estimatedMinutes ?? 2) * 60;

    final initialState = ReadingSessionState(
      chunks: chunks,
      currentChunkIndex: safeIndex,
      remainingSeconds: initialSeconds,
    );

    _elapsedSeconds = 0;
    _startTimer();
    return initialState;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!state.hasValue || state.value!.isSessionComplete) {
        timer.cancel();
        return;
      }
      final current = state.value!;
      _elapsedSeconds++;
      if (current.remainingSeconds > 0) {
        state = AsyncData(
          current.copyWith(remainingSeconds: current.remainingSeconds - 1),
        );
      }
      // Timer reaching zero is purely cosmetic — don't auto-advance.
    });
  }

  void pauseTimer() => _timer?.cancel();

  void resumeTimer() {
    if (state.hasValue && state.value!.remainingSeconds > 0) {
      _startTimer();
    }
  }

  void goToChunk(int index) {
    if (!state.hasValue) return;
    final current = state.value!;
    if (index >= 0 && index < current.chunks.length) {
      final newChunk = current.chunks[index];
      _elapsedSeconds = 0;
      state = AsyncData(current.copyWith(
        currentChunkIndex: index,
        remainingSeconds: newChunk.estimatedMinutes * 60,
      ));
      _startTimer();
    }
  }

  Future<void> nextChunk() async {
    if (!state.hasValue) return;
    final current = state.value!;
    final previousIndex = current.currentChunkIndex;

    // Increment global daily chunk counter
    ref.read(dailyChunkGoalProvider.notifier).state++;

    // ── Record the session on the backend ──────────────────────────────────
    // Fire-and-forget: don't block the UI on a network call.
    _recordSession(
      chunkIndex: previousIndex,
      durationSeconds: _elapsedSeconds,
      chunksCompleted: 1,
    );

    final nextIndex = previousIndex + 1;
    if (nextIndex < current.chunks.length) {
      goToChunk(nextIndex);
    } else {
      // Last chunk — mark the chapter complete on the backend
      _recordSession(
        chunkIndex: previousIndex,
        durationSeconds: _elapsedSeconds,
        chunksCompleted: 1,
        isLastChunk: true,
      );
      _timer?.cancel();
      state = AsyncData(current.copyWith(isSessionComplete: true));
    }
  }

  void backChunk() {
    if (!state.hasValue) return;
    final current = state.value!;
    final prevIndex = current.currentChunkIndex - 1;
    if (prevIndex >= 0) {
      goToChunk(prevIndex);
    }
  }

  void updateFontSize(double newSize) {
    if (state.hasValue) {
      state = AsyncData(state.value!.copyWith(fontSize: newSize));
    }
  }

  void updateChunkMode(ChunkSizeMode mode) {
    if (state.hasValue) {
      state = AsyncData(state.value!.copyWith(chunkMode: mode));
    }
  }

  void updateThemeMode(ThemeModeType mode) {
    if (state.hasValue) {
      state = AsyncData(state.value!.copyWith(themeMode: mode));
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  void _recordSession({
    required int chunkIndex,
    required int durationSeconds,
    required int chunksCompleted,
    bool isLastChunk = false,
  }) {
    // Use the last-chunk index when finishing so the backend marks the chapter
    // complete (chunk_index >= total_chunks - 1).
    final repo = ref.read(bookRepositoryProvider) as BookRepositoryImpl;
    repo
        .recordReadingSession(
          bookId: arg.bookId,
          chapterId: arg.chapterId,
          chunkIndex: chunkIndex,
          durationSeconds: durationSeconds,
          chunksCompleted: chunksCompleted,
        )
        .catchError(
          (e) => null, // Silently ignore — don't crash reading over a network hiccup
        );
  }
}

final readingSessionControllerProvider = AsyncNotifierProvider.autoDispose
    .family<ReadingSessionController, ReadingSessionState, ReadingSessionParams>(
  ReadingSessionController.new,
);