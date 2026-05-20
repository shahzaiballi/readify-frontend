import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/today_reading_entity.dart';
import '../../../data/repositories/book_repository_impl.dart';
import '../../../core/providers/progress_refresh_provider.dart';

final todayReadingRepoProvider =
    Provider<BookRepositoryImpl>((ref) => BookRepositoryImpl());

class TodayReadingState {
  final TodayReadingEntity reading;
  final int currentChunkIndex;
  final int elapsedSeconds;
  final bool isComplete;
  final TodayCompleteResult? completeResult;

  const TodayReadingState({
    required this.reading,
    this.currentChunkIndex = 0,
    this.elapsedSeconds = 0,
    this.isComplete = false,
    this.completeResult,
  });

  List<TodayChunkEntity> get chunks => reading.allChunks;

  TodayChunkEntity? get currentChunk =>
      chunks.isNotEmpty ? chunks[currentChunkIndex] : null;

  bool get isOnLastChunk =>
      chunks.isNotEmpty && currentChunkIndex == chunks.length - 1;

  double get chunkProgress =>
      chunks.isNotEmpty ? (currentChunkIndex + 1) / chunks.length : 0.0;

  TodayReadingState copyWith({
    TodayReadingEntity? reading,
    int? currentChunkIndex,
    int? elapsedSeconds,
    bool? isComplete,
    TodayCompleteResult? completeResult,
  }) {
    return TodayReadingState(
      reading: reading ?? this.reading,
      currentChunkIndex: currentChunkIndex ?? this.currentChunkIndex,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isComplete: isComplete ?? this.isComplete,
      completeResult: completeResult ?? this.completeResult,
    );
  }
}

class TodayReadingController
    extends AutoDisposeFamilyAsyncNotifier<TodayReadingState, String> {
  Timer? _timer;
  int _elapsedSeconds = 0;

  @override
  FutureOr<TodayReadingState> build(String bookId) async {
    ref.onDispose(() => _timer?.cancel());

    final reading =
        await ref.read(todayReadingRepoProvider).getTodayReading(bookId);

    // If the user already completed today's reading, go straight to the
    // completion view without re-running the timer or re-calling the API.
    if (reading.isTodayComplete || reading.isBookComplete) {
      return TodayReadingState(
        reading: reading,
        isComplete: true,
        currentChunkIndex: reading.allChunks.isEmpty
            ? 0
            : reading.allChunks.length - 1,
      );
    }

    _startTimer();
    return TodayReadingState(reading: reading);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.hasValue || state.value!.isComplete) return;
      _elapsedSeconds++;
      final current = state.value!;
      state = AsyncData(current.copyWith(elapsedSeconds: _elapsedSeconds));
    });
  }

  void nextPage() {
    if (!state.hasValue) return;
    final current = state.value!;
    if (current.isComplete) return;

    final nextIndex = current.currentChunkIndex + 1;
    if (nextIndex < current.chunks.length) {
      state = AsyncData(current.copyWith(currentChunkIndex: nextIndex));
    } else {
      _finishReading(current);
    }
  }

  void previousPage() {
    if (!state.hasValue) return;
    final current = state.value!;
    final prevIndex = current.currentChunkIndex - 1;
    if (prevIndex >= 0) {
      state = AsyncData(current.copyWith(currentChunkIndex: prevIndex));
    }
  }

  Future<void> finishToday() async {
    if (!state.hasValue) return;
    await _finishReading(state.value!);
  }

  Future<void> _finishReading(TodayReadingState current) async {
    _timer?.cancel();
    final repo = ref.read(todayReadingRepoProvider);
    try {
      final result = await repo.completeTodayReading(
        arg,
        _elapsedSeconds,
      );
      state = AsyncData(current.copyWith(
        isComplete: true,
        completeResult: result,
      ));
    } catch (e) {
      state = AsyncData(current.copyWith(isComplete: true));
    }
    ref.triggerProgressRefresh();
  }

}

final todayReadingControllerProvider = AsyncNotifierProvider.autoDispose
    .family<TodayReadingController, TodayReadingState, String>(
  TodayReadingController.new,
);
