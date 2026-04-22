// ENHANCED UI: Premium bottom navigation bar with fluid animations,
// pill indicator, icon glow effects, and smooth transitions
import 'package:flutter/material.dart';
import '../../../../core/utils/responsive_utils.dart';

class CustomBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavBar(
      {super.key, required this.currentIndex, required this.onTap});

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar>
    with TickerProviderStateMixin {
  // ENHANCED UI: Per-tab animation controllers for icon bounce
  final List<AnimationController> _tabControllers = [];
  final List<Animation<double>> _tabScales = [];

  final List<_NavItem> _items = const [
    _NavItem(
        icon: Icons.home_rounded,
        activeIcon: Icons.home_rounded,
        label: 'Home'),
    _NavItem(
        icon: Icons.library_books_outlined,
        activeIcon: Icons.library_books_rounded,
        label: 'Library'),
    _NavItem(
        icon: Icons.chat_bubble_outline_rounded,
        activeIcon: Icons.chat_bubble_rounded,
        label: 'Community'),
    _NavItem(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _items.length; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      );
      final scale = TweenSequence<double>([
        TweenSequenceItem(
            tween: Tween<double>(begin: 1.0, end: 1.25), weight: 40),
        TweenSequenceItem(
            tween: Tween<double>(begin: 1.25, end: 1.0), weight: 60),
      ]).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOut));
      _tabControllers.add(ctrl);
      _tabScales.add(scale);
    }
  }

  @override
  void dispose() {
    for (final ctrl in _tabControllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _handleTap(int index) {
    if (index != widget.currentIndex) {
      _tabControllers[index].forward(from: 0);
    }
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // ENHANCED UI: Glassmorphic nav bar
      decoration: BoxDecoration(
        color: const Color(0xFF0D1124),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.07),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: context.responsive.sp(60),
          child: Row(
            children: List.generate(
              _items.length,
              (i) => Expanded(
                child: _NavBarItem(
                  item: _items[i],
                  isSelected: widget.currentIndex == i,
                  scaleAnimation: _tabScales[i],
                  onTap: () => _handleTap(i),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final Animation<double> scaleAnimation;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.scaleAnimation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: scaleAnimation,
        builder: (_, child) =>
            Transform.scale(scale: scaleAnimation.value, child: child),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ENHANCED UI: Active indicator pill + icon with glow
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? context.responsive.wp(16) : context.responsive.wp(8),
                vertical: context.responsive.sp(6),
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFB062FF).withOpacity(0.18)
                    : Colors.transparent,
                borderRadius:
                    BorderRadius.circular(context.responsive.sp(14)),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isSelected ? item.activeIcon : item.icon,
                  key: ValueKey(isSelected),
                  color: isSelected
                      ? const Color(0xFFB062FF)
                      : Colors.white.withOpacity(0.35),
                  size: context.responsive.sp(22),
                  shadows: isSelected
                      ? [
                          Shadow(
                            color:
                                const Color(0xFFB062FF).withOpacity(0.6),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),
              ),
            ),

            SizedBox(height: context.responsive.sp(2)),

            // ENHANCED UI: Animated label
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFFB062FF)
                    : Colors.white.withOpacity(0.35),
                fontSize: context.responsive.sp(10),
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
