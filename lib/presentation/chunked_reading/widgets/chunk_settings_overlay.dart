import 'package:flutter/material.dart';
import '../controllers/reading_session_state.dart';

class ChunkSettingsOverlay extends StatelessWidget {
  final double initialFontSize;
  final ChunkSizeMode initialChunkMode;
  final ThemeModeType initialThemeMode;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<ChunkSizeMode> onChunkModeChanged;
  final ValueChanged<ThemeModeType> onThemeModeChanged;

  const ChunkSettingsOverlay({
    super.key,
    required this.initialFontSize,
    required this.initialChunkMode,
    required this.initialThemeMode,
    required this.onFontSizeChanged,
    required this.onChunkModeChanged,
    required this.onThemeModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: const BoxDecoration(
        color: Color(0xFF1E152A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Reading Settings",
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: 24),
          
          _buildSectionTitle("Font Size"),
          const SizedBox(height: 12),
          _buildSegmentedControl<double>(
             selectedValue: initialFontSize,
             options: const [
               MapEntry('Small', 16.0),
               MapEntry('Medium', 18.0),
               MapEntry('Large', 22.0),
             ],
             onChanged: onFontSizeChanged,
          ),
          
          const SizedBox(height: 24),
          
          _buildSectionTitle("Chunk Mode"),
          const SizedBox(height: 12),
          _buildSegmentedControl<ChunkSizeMode>(
             selectedValue: initialChunkMode,
             options: const [
               MapEntry('Quick Read', ChunkSizeMode.quickRead),
               MapEntry('Deep Dive', ChunkSizeMode.deepDive),
             ],
             onChanged: onChunkModeChanged,
          ),

          const SizedBox(height: 24),
          
          _buildSectionTitle("Theme Options"),
          const SizedBox(height: 12),
          _buildSegmentedControl<ThemeModeType>(
             selectedValue: initialThemeMode,
             options: const [
               MapEntry('Midnight', ThemeModeType.midnight),
               MapEntry('Sepia', ThemeModeType.sepia),
               MapEntry('OLED Black', ThemeModeType.pureDark),
             ],
             onChanged: onThemeModeChanged,
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    ));
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildSegmentedControl<T>({
    required T selectedValue,
    required List<MapEntry<String, T>> options,
    required ValueChanged<T> onChanged,
  }) {
    return Row(
      children: options.map((entry) {
        final isSelected = entry.value == selectedValue;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(entry.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFB062FF) : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? const Color(0xFFB062FF) : Colors.white12,
                ),
              ),
              child: Center(
                child: Text(
                  entry.key,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

