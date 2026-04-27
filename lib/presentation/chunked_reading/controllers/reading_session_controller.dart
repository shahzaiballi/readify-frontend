import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/repositories/book_repository.dart';
import '../../../data/repositories/book_repository_impl.dart';
import '../../../core/providers/progress_refresh_provider.dart';
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
      // FIX: never start in session-complete state, even if loaded at last chunk
      isSessionComplete: false,
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
        // FIX: navigating to any chunk (including last) never auto-completes
        isSessionComplete: false,
      ));
      _startTimer();
    }
  }

  /// Called when the user taps the forward/check FAB.
  /// 
  /// FIX: The session only completes AFTER the user taps "next" on the
  /// last chunk — not simply by being ON the last chunk. This means:
  /// - Chunks 0..N-2 → navigate forward
  /// - Chunk N-1 (last) → record session + mark complete → show SessionCompleteCard
  Future<void> nextChunk() async {
    if (!state.hasValue) return;
    final current = state.value!;
    final currentIndex = current.currentChunkIndex;

    // Increment global daily chunk counter
    ref.read(dailyChunkGoalProvider.notifier).state++;

    // Record session for the chunk just completed
    await _recordSession(
      chunkIndex: currentIndex,
      durationSeconds: _elapsedSeconds,
      chunksCompleted: 1,
    );

    final nextIndex = currentIndex + 1;

    if (nextIndex < current.chunks.length) {
      // ── More chunks remain — navigate forward ──────────────────────────────
      goToChunk(nextIndex);
    } else {
      // ── User tapped next on the LAST chunk — chapter is done ───────────────
      // Only NOW do we mark the session as complete and show the completion card.
      _timer?.cancel();
      state = AsyncData(current.copyWith(isSessionComplete: true));
    }

    // Trigger real-time UI refresh (progress bar, chapter list, etc.)
    ref.triggerProgressRefresh();
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

  Future<void> _recordSession({
    required int chunkIndex,
    required int durationSeconds,
    required int chunksCompleted,
  }) async {
    final repo = ref.read(bookRepositoryProvider) as BookRepositoryImpl;
    try {
      await repo.recordReadingSession(
        bookId: arg.bookId,
        chapterId: arg.chapterId,
        chunkIndex: chunkIndex,
        durationSeconds: durationSeconds,
        chunksCompleted: chunksCompleted,
      );
    } catch (_) {
      // Silently ignore — don't crash reading over a network hiccup
    }
  }
}

final readingSessionControllerProvider = AsyncNotifierProvider.autoDispose
    .family<ReadingSessionController, ReadingSessionState, ReadingSessionParams>(
  ReadingSessionController.new,
);