// ENHANCED UI: Premium quick action card with animated press states,
// gradient icon containers, and glassmorphic design
import 'package:flutter/material.dart';
import '../../../../core/utils/responsive_utils.dart';

class QuickActionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final bool hasNotification;

  const QuickActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.hasNotification = false,
  });

  @override
  State<QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<QuickActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scale;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
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
      onTapDown: (_) {
        _pressCtrl.forward();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        _pressCtrl.reverse();
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () {
        _pressCtrl.reverse();
        setState(() => _isPressed = false);
      },
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.all(context.responsive.sp(16)),
          decoration: BoxDecoration(
            // ENHANCED UI: Dynamic border on press
            color: _isPressed
                ? const Color(0xFF1E233D).withOpacity(0.8)
                : const Color(0xFF1E233D),
            borderRadius:
                BorderRadius.circular(context.responsive.sp(16)),
            border: Border.all(
              color: _isPressed
                  ? widget.iconColor.withOpacity(0.3)
                  : Colors.white.withOpacity(0.06),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isPressed
                    ? widget.iconColor.withOpacity(0.08)
                    : Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              // ENHANCED UI: Colored shadow for primary action
              if (widget.iconColor == const Color(0xFFB062FF))
                BoxShadow(
                  color: widget.iconColor.withOpacity(0.08),
                  blurRadius: 24,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Row(
            children: [
              // ENHANCED UI: Gradient icon container with glow
              Container(
                padding: EdgeInsets.all(context.responsive.sp(11)),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      widget.iconColor.withOpacity(0.25),
                      widget.iconColor.withOpacity(0.1),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.iconColor.withOpacity(0.2),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon,
                  color: widget.iconColor,
                  size: context.responsive.sp(20),
                ),
              ),

              SizedBox(width: context.responsive.wp(16)),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: context.responsive.sp(15),
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.1,
                      ),
                    ),
                    SizedBox(height: context.responsive.sp(3)),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: context.responsive.sp(12),
                      ),
                    ),
                  ],
                ),
              ),

              // ENHANCED UI: Notification badge
              if (widget.hasNotification) ...[
                Container(
                  margin:
                      EdgeInsets.only(right: context.responsive.wp(10)),
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Text(
                    '1',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.responsive.sp(9),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],

              // ENHANCED UI: Animated chevron
              AnimatedSlide(
                duration: const Duration(milliseconds: 150),
                offset:
                    _isPressed ? const Offset(0.15, 0) : Offset.zero,
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withOpacity(0.25),
                  size: context.responsive.sp(14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
