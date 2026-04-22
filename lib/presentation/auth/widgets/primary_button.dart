// ENHANCED UI: Premium gradient primary button with smooth press animation,
// shimmer loading state, and polished typography
import 'package:flutter/material.dart';

class PrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scale;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
    _glow = Tween<double>(begin: 1.0, end: 0.4).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:
          widget.isLoading ? null : (_) => _pressCtrl.forward(),
      onTapUp: widget.isLoading
          ? null
          : (_) {
              _pressCtrl.reverse();
              widget.onPressed();
            },
      onTapCancel:
          widget.isLoading ? null : () => _pressCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _pressCtrl,
        builder: (_, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: AnimatedBuilder(
          animation: _glow,
          builder: (_, child) => Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              // ENHANCED UI: Premium gradient button
              gradient: widget.isLoading
                  ? const LinearGradient(
                      colors: [Color(0xFF5A2AA0), Color(0xFF1A4090)],
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF9B4FFF), Color(0xFF3277FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: widget.isLoading
                  ? []
                  : [
                      BoxShadow(
                        color: const Color(0xFF7B2FFF)
                            .withOpacity(0.4 * _glow.value),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: const Color(0xFF3277FF)
                            .withOpacity(0.2 * _glow.value),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
            ),
            child: child,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              splashColor: Colors.white.withOpacity(0.1),
              onTap: null, // handled by GestureDetector
              child: Center(
                child: widget.isLoading
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                  Colors.white.withOpacity(0.7)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Please wait...',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        widget.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
