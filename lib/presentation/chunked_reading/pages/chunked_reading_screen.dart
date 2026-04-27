import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/reading_session_controller.dart';
import '../controllers/reading_session_state.dart';
import '../widgets/chunk_timer_overlay.dart';
import '../widgets/chunk_settings_overlay.dart';
import '../widgets/session_complete_card.dart';
import '../widgets/chunk_content_page.dart';
import '../../../core/services/notification_service.dart';

class ChunkedReadingScreen extends ConsumerStatefulWidget {
  final String bookId;
  final String chapterId;
  final int initialChunkIndex;

  const ChunkedReadingScreen({
    super.key,
    required this.bookId,
    required this.chapterId,
    this.initialChunkIndex = 0,
  });

  @override
  ConsumerState<ChunkedReadingScreen> createState() =>
      _ChunkedReadingScreenState();
}

class _ChunkedReadingScreenState extends ConsumerState<ChunkedReadingScreen> {
  late final ReadingSessionParams _params;

  @override
  void initState() {
    super.initState();
    _params = ReadingSessionParams(
      bookId: widget.bookId,
      chapterId: widget.chapterId,
      initialChunkIndex: widget.initialChunkIndex,
    );
  }

  Color _getBackgroundColor(ThemeModeType theme) {
    switch (theme) {
      case ThemeModeType.midnight:
        return const Color(0xFF0F1626);
      case ThemeModeType.sepia:
        return const Color(0xFFF4ECD8);
      case ThemeModeType.pureDark:
        return const Color(0xFF000000);
    }
  }

  Color _getTextColor(ThemeModeType theme) {
    switch (theme) {
      case ThemeModeType.midnight:
        return Colors.white;
      case ThemeModeType.sepia:
        return const Color(0xFF423B2A);
      case ThemeModeType.pureDark:
        return Colors.white;
    }
  }

  Color _getIconColor(ThemeModeType theme) {
    if (theme == ThemeModeType.sepia) return const Color(0xFF423B2A);
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(readingSessionControllerProvider(_params));
    final controller =
        ref.read(readingSessionControllerProvider(_params).notifier);

    // Schedule a "next chunk" notification whenever the chunk changes
    ref.listen<AsyncValue<ReadingSessionState>>(
      readingSessionControllerProvider(_params),
      (prev, next) {
        final state = next.valueOrNull;
        if (state == null) return;
        final currentIdx = state.currentChunkIndex;
        if (currentIdx + 1 < state.chunks.length) {
          final nextChunkPreview = state.chunks[currentIdx + 1].text;
          ref.read(notificationServiceProvider).scheduleReadingReminder(
                widget.bookId,
                widget.chapterId,
                currentIdx + 1,
                nextChunkPreview,
              );
        }
      },
    );

    return asyncState.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF0F1626),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: const Color(0xFF0F1626),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: BackButton(color: Colors.white),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    color: Colors.redAccent, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Failed to load reading content.\n${err.toString().replaceAll('Exception: ', '')}',
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
      data: (state) {
        final bgColor = _getBackgroundColor(state.themeMode);
        final textColor = _getTextColor(state.themeMode);
        final iconColor = _getIconColor(state.themeMode);

        // Progress is based on current chunk position within the chapter
        final progress = state.chunks.isNotEmpty
            ? (state.currentChunkIndex + 1) / state.chunks.length
            : 0.0;

        // True only when user has tapped "next" on the very last chunk
        // (isSessionComplete is set by the controller after nextChunk() on last chunk)
        final bool isOnLastChunk = state.chunks.isNotEmpty &&
            state.currentChunkIndex == state.chunks.length - 1;

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double horizontalPadding =
                    constraints.maxWidth > 600 ? 64.0 : 16.0;

                return Column(
                  children: [
                    // Top progress bar showing position within chapter
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: Colors.transparent,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFB062FF)),
                    ),

                    // Header
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding, vertical: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Back button
                          Flexible(
                            child: IconButton(
                              icon: Icon(Icons.arrow_back, color: iconColor),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),

                          // Chunk position indicator — shows "Page X of Y"
                          if (state.chunks.isNotEmpty && !state.isSessionComplete)
                            Flexible(
                              flex: 3,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFB062FF)
                                      .withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Page ${state.currentChunkIndex + 1} of ${state.chunks.length}',
                                  style: TextStyle(
                                      color: iconColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),

                          // Timer + settings
                          Flexible(
                            flex: 3,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: ChunkTimerOverlay(
                                      remainingSeconds:
                                          state.remainingSeconds),
                                ),
                                Flexible(
                                  child: IconButton(
                                    icon: Text(
                                      'AA',
                                      style: TextStyle(
                                          color: iconColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                    onPressed: () => _showSettingsOverlay(
                                        context, controller, state),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Main content
                    Expanded(
                      child: state.isSessionComplete
                          ? SessionCompleteCard(
                              bookId: widget.bookId,
                              chapterId: widget.chapterId,
                            )
                          : AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, animation) {
                                final inAnimation = Tween<Offset>(
                                        begin: const Offset(0.2, 0.0),
                                        end: Offset.zero)
                                    .animate(animation);
                                final outAnimation = Tween<Offset>(
                                        begin: const Offset(-0.2, 0.0),
                                        end: Offset.zero)
                                    .animate(animation);
                                final slideAnim =
                                    child.key ==
                                            ValueKey(state.currentChunkIndex)
                                        ? inAnimation
                                        : outAnimation;
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                      position: slideAnim, child: child),
                                );
                              },
                              child: state.chunks.isEmpty
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(32),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.auto_stories_outlined,
                                                color: iconColor
                                                    .withOpacity(0.4),
                                                size: 48),
                                            const SizedBox(height: 16),
                                            Text(
                                              'No reading content available\nfor this chapter yet.',
                                              style: TextStyle(
                                                  color: textColor
                                                      .withOpacity(0.6),
                                                  fontSize: 15,
                                                  height: 1.5),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : ChunkContentPage(
                                      key: ValueKey(state.currentChunkIndex),
                                      text: state
                                          .chunks[state.currentChunkIndex]
                                          .text,
                                      fontSize: state.fontSize,
                                      textColor: textColor,
                                      onNextChunk: () =>
                                          controller.nextChunk(),
                                      isLastChunk: isOnLastChunk,
                                    ),
                            ),
                    ),

                    // Navigation arrows — shown when there are chunks and not complete
                    if (!state.isSessionComplete && state.chunks.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: 24.0,
                          left: horizontalPadding * 2,
                          right: horizontalPadding * 2,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Previous chunk button
                            FloatingActionButton(
                              heroTag: 'prevChunk',
                              mini: true,
                              elevation: 0,
                              backgroundColor:
                                  iconColor.withOpacity(0.1),
                              onPressed: state.currentChunkIndex > 0
                                  ? controller.backChunk
                                  : null,
                              child: Icon(
                                Icons.arrow_back_ios_new,
                                color: state.currentChunkIndex > 0
                                    ? iconColor
                                    : iconColor.withOpacity(0.2),
                                size: 16,
                              ),
                            ),

                            // Chunk counter badge in the middle
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: iconColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: iconColor.withOpacity(0.15),
                                ),
                              ),
                              child: Text(
                                '${state.currentChunkIndex + 1} / ${state.chunks.length}',
                                style: TextStyle(
                                  color: iconColor.withOpacity(0.7),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            // Next chunk / finish chapter button
                            // FIX: Only show checkmark AFTER reading the last chunk
                            // (i.e., never show checkmark as the default state of last chunk)
                            // The checkmark on last chunk invites premature completion.
                            // We always show forward arrow; the controller handles completion.
                            FloatingActionButton(
                              heroTag: 'nextChunk',
                              mini: true,
                              elevation: 0,
                              backgroundColor:
                                  const Color(0xFFB062FF).withOpacity(0.9),
                              onPressed: () => controller.nextChunk(),
                              child: Icon(
                                // Show checkmark only on the very last page
                                // so the user knows it's the final page — but
                                // tapping it completes the chapter (goes to SessionCompleteCard)
                                isOnLastChunk
                                    ? Icons.check_rounded
                                    : Icons.arrow_forward_ios,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showSettingsOverlay(BuildContext context,
      ReadingSessionController controller, ReadingSessionState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Consumer(
          builder: (context, consumerRef, _) {
            final currentState =
                consumerRef
                    .watch(readingSessionControllerProvider(_params))
                    .valueOrNull ??
                state;
            return ChunkSettingsOverlay(
              initialFontSize: currentState.fontSize,
              initialChunkMode: currentState.chunkMode,
              initialThemeMode: currentState.themeMode,
              onFontSizeChanged: controller.updateFontSize,
              onChunkModeChanged: controller.updateChunkMode,
              onThemeModeChanged: controller.updateThemeMode,
            );
          },
        );
      },
    );
  }
}