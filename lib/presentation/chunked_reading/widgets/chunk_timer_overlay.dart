import 'package:flutter/material.dart';

class ChunkTimerOverlay extends StatelessWidget {
  final int remainingSeconds;
  
  const ChunkTimerOverlay({super.key, required this.remainingSeconds});

  @override
  Widget build(BuildContext context) {
    if (remainingSeconds <= 0) return const SizedBox.shrink();

    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    final formattedTime = '$minutes:${seconds.toString().padLeft(2, '0')}';
    
    // We assume 120 seconds default for the circle fill, max bounded
    final progress = (remainingSeconds / 120).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 38,
            height: 38,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFB062FF)),
            ),
          ),
          Text(
            formattedTime,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

