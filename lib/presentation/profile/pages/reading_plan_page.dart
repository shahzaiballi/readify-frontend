import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../controllers/reading_plan_controller.dart';

class ReadingPlanPage extends ConsumerStatefulWidget {
  const ReadingPlanPage({super.key});

  @override
  ConsumerState<ReadingPlanPage> createState() => _ReadingPlanPageState();
}

class _ReadingPlanPageState extends ConsumerState<ReadingPlanPage> {
   late double _pagesPerDay;
  late int _daysPerWeek;
  late String _preferredTime;
  late String _readingMode;

  @override
  void initState() {
    super.initState();
    final currentPlan = ref.read(readingPlanProvider);
      _pagesPerDay = currentPlan.pagesPerDay.toDouble();
    _daysPerWeek = currentPlan.daysPerWeek;
    _preferredTime = currentPlan.preferredTime;
    _readingMode = currentPlan.readingMode;
  }

  void _savePlan() {
    ref.read(readingPlanProvider.notifier).updatePlan(
         pagesPerDay: _pagesPerDay.toInt(),
      daysPerWeek: _daysPerWeek,
      preferredTime: _preferredTime,
      readingMode: _readingMode,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reading plan saved successfully!'), backgroundColor: Colors.green),
    );
    
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
     return Scaffold(
        backgroundColor: const Color(0xFF0F1626),
        appBar: AppBar(
           backgroundColor: const Color(0xFF0F1626),
           elevation: 0,
           leading: IconButton(
              icon: Container(
                 padding: EdgeInsets.all(context.responsive.sp(8)),
                 decoration: const BoxDecoration(
                    color: Color(0xFF1E233D),
                    shape: BoxShape.circle,
                 ),
                 child: Icon(Icons.arrow_back, color: Colors.white, size: context.responsive.sp(18)),
              ),
              onPressed: () => context.pop(), 
           ),
           title: Text('Reading Plan', style: TextStyle(color: Colors.white, fontSize: context.responsive.sp(16), fontWeight: FontWeight.bold)),
           centerTitle: false,
        ),
        body: SafeArea(
           child: SingleChildScrollView(
              padding: EdgeInsets.all(context.responsive.wp(20)),
              child: Column(
                 crossAxisAlignment: CrossAxisAlignment.stretch,
                 children: [
                    // Daily Reading Goal
                    _buildSectionContainer(
                       context: context,
                       icon: Icons.menu_book_rounded,
                       title: 'Daily Reading Goal',
                       subtitle: 'How many pages can you read each day?',
                       child: Column(
                          children: [
                             Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                   Text('Pages per day', style: TextStyle(color: Colors.white54, fontSize: context.responsive.sp(13))),
                                   Text('${_pagesPerDay.toInt()} pages', style: TextStyle(color: Colors.white, fontSize: context.responsive.sp(18), fontWeight: FontWeight.bold)),
                                ],
                             ),
                             SizedBox(height: context.responsive.sp(8)),
                             SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                   activeTrackColor: const Color(0xFFB062FF),
                                   inactiveTrackColor: Colors.white12,
                                   thumbColor: const Color(0xFFB062FF),
                                   overlayColor: const Color(0xFFB062FF).withValues(alpha: 0.2),
                                   trackHeight: context.responsive.sp(4),
                                ),
                                child: Slider(
                                   value: _pagesPerDay,
                                   min: 1,
                                   max: 100,
                                   divisions: 99,
                                   onChanged: (val) {
                                      setState(() => _pagesPerDay = val);
                                   },
                                ),
                             ),
                             Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                   Text('1 pg', style: TextStyle(color: Colors.white24, fontSize: context.responsive.sp(11))),
                                   Text('100 pg', style: TextStyle(color: Colors.white24, fontSize: context.responsive.sp(11))),
                                ],
                             )
                          ],
                       )
                    ),

                    SizedBox(height: context.responsive.sp(20)),

                    // Days Per Week
                    _buildSectionContainer(
                       context: context,
                       icon: Icons.calendar_month,
                       title: 'Days Per Week',
                       subtitle: 'How many days a week can you commit?',
                       child: Column(
                          children: [
                             Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: List.generate(7, (index) {
                                   int day = index + 1;
                                   bool isSelected = day <= _daysPerWeek;
                                   return GestureDetector(
                                      onTap: () => setState(() => _daysPerWeek = day),
                                      child: Container(
                                         width: context.responsive.sp(36),
                                         height: context.responsive.sp(36),
                                         decoration: BoxDecoration(
                                            color: isSelected ? const Color(0xFFB062FF) : const Color(0xFF0F1626),
                                            borderRadius: BorderRadius.circular(context.responsive.sp(8)),
                                            border: Border.all(color: isSelected ? Colors.transparent : Colors.white12),
                                         ),
                                         child: Center(
                                            child: Text(
                                               '$day',
                                               style: TextStyle(
                                                  color: isSelected ? Colors.white : Colors.white54,
                                                  fontSize: context.responsive.sp(14),
                                                  fontWeight: FontWeight.bold,
                                               ),
                                            )
                                         ),
                                      ),
                                   );
                                }),
                             ),
                             SizedBox(height: context.responsive.sp(16)),
                             Text(
                                'Selected $_daysPerWeek days/week',
                                style: TextStyle(color: const Color(0xFFB062FF), fontSize: context.responsive.sp(12), fontWeight: FontWeight.bold),
                             )
                          ],
                       )
                    ),

                    SizedBox(height: context.responsive.sp(20)),

                    // Reading Mode
                    _buildSectionContainer(
                       context: context,
                       icon: Icons.auto_stories,
                       title: 'Reading Mode',
                       subtitle: 'How deeply do you want to engage?',
                       child: Column(
                          children: [
                             _ReadingModeOption(
                               mode: 'skim',
                               label: 'Skim',
                               description: 'Key points only — fast overview',
                               emoji: '⚡',
                               selected: _readingMode == 'skim',
                               onTap: () => setState(() => _readingMode = 'skim'),
                             ),
                             SizedBox(height: context.responsive.sp(8)),
                             _ReadingModeOption(
                               mode: 'concept',
                               label: 'Concept',
                               description: 'Core ideas and connections',
                               emoji: '💡',
                               selected: _readingMode == 'concept',
                               onTap: () => setState(() => _readingMode = 'concept'),
                             ),
                             SizedBox(height: context.responsive.sp(8)),
                             _ReadingModeOption(
                               mode: 'deep',
                               label: 'Deep',
                               description: 'Full comprehension — default',
                               emoji: '🧠',
                               selected: _readingMode == 'deep',
                               onTap: () => setState(() => _readingMode = 'deep'),
                             ),
                             SizedBox(height: context.responsive.sp(8)),
                             _ReadingModeOption(
                               mode: 'exam',
                               label: 'Exam',
                               description: 'Heavy recall + flashcard focus',
                               emoji: '🎯',
                               selected: _readingMode == 'exam',
                               onTap: () => setState(() => _readingMode = 'exam'),
                             ),
                          ],
                       ),
                    ),

                    SizedBox(height: context.responsive.sp(24)),
                    Text('Preferred Reading Time', style: TextStyle(color: Colors.white, fontSize: context.responsive.sp(15), fontWeight: FontWeight.bold)),
                    SizedBox(height: context.responsive.sp(12)),

                    // Choice Chips
                    _buildTimeChoice(context, 'Morning', '5AM - 12PM', Icons.wb_sunny_outlined),
                    _buildTimeChoice(context, 'Afternoon', '12PM - 6PM', Icons.wb_twilight),
                    _buildTimeChoice(context, 'Evening', '6PM - 12AM', Icons.nights_stay_outlined),

                    SizedBox(height: context.responsive.sp(32)),

                    // Save Plan Button
                    SizedBox(
                       width: double.infinity,
                       height: context.responsive.sp(52),
                       child: DecoratedBox(
                          decoration: BoxDecoration(
                             gradient: const LinearGradient(colors: [Color(0xFF9146FF), Color(0xFF3861FB)]),
                             borderRadius: BorderRadius.circular(context.responsive.sp(12)),
                          ),
                          child: ElevatedButton.icon(
                             onPressed: _savePlan,
                             icon: Icon(Icons.save_outlined, color: Colors.white, size: context.responsive.sp(18)),
                             label: Text('Save Reading Plan', style: TextStyle(color: Colors.white, fontSize: context.responsive.sp(15), fontWeight: FontWeight.bold)),
                             style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.responsive.sp(12))),
                             ),
                          ),
                       ),
                    ),
                    SizedBox(height: context.responsive.sp(40)),
                 ],
              )
           ),
        ),
     );
  }

  Widget _buildTimeChoice(BuildContext context, String title, String range, IconData icon) {
     bool isSelected = _preferredTime == title;
     return GestureDetector(
        onTap: () => setState(() => _preferredTime = title),
        child: Container(
           margin: EdgeInsets.only(bottom: context.responsive.sp(12)),
           padding: EdgeInsets.all(context.responsive.sp(16)),
           decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFB062FF).withValues(alpha: 0.15) : const Color(0xFF1E233D),
              borderRadius: BorderRadius.circular(context.responsive.sp(12)),
              border: Border.all(color: isSelected ? const Color(0xFFB062FF) : Colors.transparent, width: 1.5),
           ),
           child: Row(
              children: [
                 Icon(icon, color: isSelected ? const Color(0xFFB062FF) : Colors.white54, size: context.responsive.sp(20)),
                 SizedBox(width: context.responsive.wp(16)),
                 Expanded(
                    child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                          Text(title, style: TextStyle(color: isSelected ? const Color(0xFFB062FF) : Colors.white, fontSize: context.responsive.sp(14), fontWeight: FontWeight.bold)),
                          Text(range, style: TextStyle(color: Colors.white54, fontSize: context.responsive.sp(12))),
                       ],
                    ),
                 ),
                 if (isSelected) 
                    Icon(Icons.check_circle, color: const Color(0xFFB062FF), size: context.responsive.sp(20))
              ],
           ),
        ),
     );
  }


  Widget _buildSectionContainer({required BuildContext context, required IconData icon, required String title, required String subtitle, required Widget child}) {
     return Container(
        padding: EdgeInsets.all(context.responsive.sp(20)),
        decoration: BoxDecoration(color: const Color(0xFF1E233D), borderRadius: BorderRadius.circular(context.responsive.sp(16))),
        child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
              Row(
                 children: [
                    Container(
                       padding: EdgeInsets.all(context.responsive.sp(8)),
                       decoration: BoxDecoration(color: const Color(0xFF2A2F4C), borderRadius: BorderRadius.circular(context.responsive.sp(8))),
                       child: Icon(icon, color: const Color(0xFFB062FF), size: context.responsive.sp(16)),
                    ),
                    SizedBox(width: context.responsive.wp(12)),
                    Expanded(
                       child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Text(title, style: TextStyle(color: Colors.white, fontSize: context.responsive.sp(14), fontWeight: FontWeight.bold)),
                             Text(subtitle, style: TextStyle(color: Colors.white54, fontSize: context.responsive.sp(11))),
                          ],
                       ),
                    )
                 ],
              ),
              SizedBox(height: context.responsive.sp(20)),
              child,
           ],
        ),
     );
  }
}

// ── Reading Mode Option ────────────────────────────────────────────────────────

class _ReadingModeOption extends StatelessWidget {
  final String mode;
  final String label;
  final String description;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  const _ReadingModeOption({
    required this.mode,
    required this.label,
    required this.description,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: context.responsive.wp(14),
          vertical: context.responsive.sp(12),
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFB062FF).withValues(alpha: 0.12)
              : const Color(0xFF0F1626),
          borderRadius: BorderRadius.circular(context.responsive.sp(10)),
          border: Border.all(
            color: selected
                ? const Color(0xFFB062FF)
                : Colors.white.withValues(alpha: 0.08),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: TextStyle(fontSize: context.responsive.sp(20))),
            SizedBox(width: context.responsive.wp(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? const Color(0xFFB062FF) : Colors.white,
                      fontSize: context.responsive.sp(13),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: context.responsive.sp(11),
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(
                Icons.check_circle_rounded,
                color: const Color(0xFFB062FF),
                size: context.responsive.sp(18),
              ),
          ],
        ),
      ),
    );
  }
}

