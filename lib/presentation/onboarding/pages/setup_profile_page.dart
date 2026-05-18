import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/navigation/app_router.dart';

// Reuse components if possible, or define simple ones here
import '../../auth/widgets/primary_button.dart';

class SetupProfilePage extends ConsumerStatefulWidget {
  const SetupProfilePage({super.key});

  @override
  ConsumerState<SetupProfilePage> createState() => _SetupProfilePageState();
}

class _SetupProfilePageState extends ConsumerState<SetupProfilePage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  void _nextPage() {
    if (_currentIndex < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishSetup();
    }
  }

  void _finishSetup() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('needsProfileSetup', false);
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1626),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _nextPage,
            child: Text(
              'Skip',
              style: TextStyle(
                color: Colors.white54,
                fontSize: context.responsive.sp(14),
              ),
            ),
          ),
          SizedBox(width: context.responsive.wp(8)),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.responsive.wp(24)),
              child: Row(
                children: List.generate(3, (index) {
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: context.responsive.wp(4)),
                      height: 4,
                      decoration: BoxDecoration(
                        color: _currentIndex >= index
                            ? const Color(0xFFB062FF)
                            : Colors.white12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            SizedBox(height: context.responsive.sp(32)),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Force using buttons
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                children: [
                  _UploadPictureStep(onNext: _nextPage),
                  _ReadingPlanStep(onNext: _nextPage),
                  _InterestsStep(onNext: _finishSetup),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 1: Upload Picture ──────────────────────────────────────────────────
class _UploadPictureStep extends StatelessWidget {
  final VoidCallback onNext;
  const _UploadPictureStep({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(context.responsive.wp(24)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Add a Profile Picture',
            style: TextStyle(
              color: Colors.white,
              fontSize: context.responsive.sp(24),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: context.responsive.sp(12)),
          Text(
            'Help your friends find you in communities.',
            style: TextStyle(
              color: Colors.white54,
              fontSize: context.responsive.sp(14),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.responsive.sp(48)),
          
          Container(
            width: context.responsive.sp(120),
            height: context.responsive.sp(120),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1E233D),
              border: Border.all(color: const Color(0xFFB062FF).withOpacity(0.3), width: 2),
            ),
            child: Icon(
              Icons.camera_alt_outlined,
              color: const Color(0xFFB062FF),
              size: context.responsive.sp(40),
            ),
          ),
          
          const Spacer(),
          PrimaryButton(
            text: 'Choose Photo',
            onPressed: () {
              // Real implementation would open image picker
              // For now, just proceed to next step
              onNext();
            },
          ),
          SizedBox(height: context.responsive.sp(16)),
        ],
      ),
    );
  }
}

// ── Step 2: Reading Plan ────────────────────────────────────────────────────
class _ReadingPlanStep extends StatelessWidget {
  final VoidCallback onNext;
  const _ReadingPlanStep({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(context.responsive.wp(24)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Set Your Reading Plan',
            style: TextStyle(
              color: Colors.white,
              fontSize: context.responsive.sp(24),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: context.responsive.sp(12)),
          Text(
            'How much time do you want to spend reading daily?',
            style: TextStyle(
              color: Colors.white54,
              fontSize: context.responsive.sp(14),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.responsive.sp(48)),

          _PlanOption(title: 'Casual', subtitle: '15 mins / day', isSelected: false),
          SizedBox(height: context.responsive.sp(16)),
          _PlanOption(title: 'Regular', subtitle: '30 mins / day', isSelected: true),
          SizedBox(height: context.responsive.sp(16)),
          _PlanOption(title: 'Avid', subtitle: '60+ mins / day', isSelected: false),

          const Spacer(),
          PrimaryButton(
            text: 'Continue',
            onPressed: onNext,
          ),
          SizedBox(height: context.responsive.sp(16)),
        ],
      ),
    );
  }
}

class _PlanOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;

  const _PlanOption({required this.title, required this.subtitle, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.responsive.sp(20)),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFB062FF).withOpacity(0.15) : const Color(0xFF1E233D),
        borderRadius: BorderRadius.circular(context.responsive.sp(16)),
        border: Border.all(
          color: isSelected ? const Color(0xFFB062FF) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.responsive.sp(16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: context.responsive.sp(4)),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: context.responsive.sp(13),
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            Icon(Icons.check_circle_rounded, color: const Color(0xFFB062FF), size: context.responsive.sp(24))
          else
            Icon(Icons.circle_outlined, color: Colors.white24, size: context.responsive.sp(24)),
        ],
      ),
    );
  }
}

// ── Step 3: Interests ───────────────────────────────────────────────────────
class _InterestsStep extends StatelessWidget {
  final VoidCallback onNext;
  const _InterestsStep({required this.onNext});

  @override
  Widget build(BuildContext context) {
    final interests = [
      'Fiction', 'Non-Fiction', 'Science', 'Technology',
      'History', 'Biography', 'Self-Help', 'Business',
      'Fantasy', 'Mystery', 'Philosophy', 'Psychology'
    ];

    return Padding(
      padding: EdgeInsets.all(context.responsive.wp(24)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'What do you like to read?',
            style: TextStyle(
              color: Colors.white,
              fontSize: context.responsive.sp(24),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: context.responsive.sp(12)),
          Text(
            'Select your favorite genres to get better recommendations.',
            style: TextStyle(
              color: Colors.white54,
              fontSize: context.responsive.sp(14),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.responsive.sp(32)),

          Wrap(
            spacing: context.responsive.wp(12),
            runSpacing: context.responsive.sp(12),
            children: interests.map((interest) {
              final isSelected = ['Science', 'Technology', 'Self-Help'].contains(interest);
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsive.wp(16),
                  vertical: context.responsive.sp(10),
                ),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFB062FF) : const Color(0xFF1E233D),
                  borderRadius: BorderRadius.circular(context.responsive.sp(20)),
                ),
                child: Text(
                  interest,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.responsive.sp(13),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),

          const Spacer(),
          PrimaryButton(
            text: 'Finish Setup',
            onPressed: onNext,
          ),
          SizedBox(height: context.responsive.sp(16)),
        ],
      ),
    );
  }
}
