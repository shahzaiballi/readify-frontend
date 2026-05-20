import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/entities/chapter_entity.dart';
import '../../../../core/utils/responsive_utils.dart';

class ChapterListItem extends StatelessWidget {
  final ChapterEntity chapter;
  final String bookId;

  const ChapterListItem({super.key, required this.chapter, required this.bookId});

  @override
  Widget build(BuildContext context) {
    if (chapter.isActive) {
      return _buildActiveChapter(context);
    } else if (chapter.isCompleted) {
      return _buildCompletedChapter(context);
    } else if (chapter.isLocked) {
      return _buildLockedChapter(context);
    } else {
      return _buildUpcomingChapter(context);
    }
  }

  // Active highlighted style (e.g. Current Chapter 4)
  Widget _buildActiveChapter(BuildContext context) {
    return Container(
       margin: EdgeInsets.only(bottom: context.responsive.sp(12)),
       decoration: BoxDecoration(
          color: const Color(0xFF1E233D),
          borderRadius: BorderRadius.circular(context.responsive.sp(12)),
          border: Border.all(color: const Color(0xFFB062FF), width: 1.5), // Highlight border
       ),
       child: Padding(
          padding: EdgeInsets.all(context.responsive.sp(16)),
          child: Column(
            children: [
               Row(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    _buildIconBox(Icons.play_arrow, const Color(0xFFB062FF), context),
                    SizedBox(width: context.responsive.wp(16)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text(
                             'Chapter ${chapter.chapterNumber}: ${chapter.title}', 
                             style: TextStyle(color: const Color(0xFFB062FF), fontSize: context.responsive.sp(14), fontWeight: FontWeight.bold)
                           ),
                           SizedBox(height: context.responsive.sp(8)),
                           Row(
                              children: [
                                 Icon(Icons.schedule, color: Colors.white54, size: context.responsive.sp(12)),
                                 SizedBox(width: context.responsive.wp(4)),
                                 Text('${chapter.pagesCount > 0 ? chapter.pagesCount : chapter.pageRange.isNotEmpty ? chapter.pageRange : '—'} ${chapter.pagesCount > 0 ? 'pages' : ''}  •  ${chapter.pageRange}', style: TextStyle(color: Colors.white54, fontSize: context.responsive.sp(11))),
                              ],
                           )
                        ],
                      ),
                    )
                 ],
               ),
               SizedBox(height: context.responsive.sp(16)),
               // Action button that forwards to Details
               SizedBox(
                 width: double.infinity,
                 child: ElevatedButton(
                    onPressed: () {
                         context.push('/today-reading/$bookId');
                    },
                    style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.transparent,
                       shadowColor: Colors.transparent,
                       padding: EdgeInsets.zero,
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.responsive.sp(8))),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                         gradient: const LinearGradient(colors: [Color(0xFF9146FF), Color(0xFF3861FB)]),
                         borderRadius: BorderRadius.circular(context.responsive.sp(8))
                      ),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: context.responsive.sp(12)),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_arrow, color: Colors.white, size: context.responsive.sp(16)),
                            SizedBox(width: context.responsive.wp(8)),
                            Text('Continue Reading', style: TextStyle(color: Colors.white, fontSize: context.responsive.sp(12), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    ),
                 ),
               )
            ],
          ),
       ),
    );
  }

  // Completed style (Green checkmark, dimmed text)
  Widget _buildCompletedChapter(BuildContext context) {
    return _buildStandardRow(
      iconWidget: _buildIconBox(Icons.check_circle_outline, Colors.teal, context),
      titleColor: Colors.white70,
      context: context,
    );
  }

  // Upcoming style (Numbered circle, dimmed text)
  Widget _buildUpcomingChapter(BuildContext context) {
    return _buildStandardRow(
      iconWidget: Container(
         padding: EdgeInsets.all(context.responsive.sp(10)),
         decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
         child: Text('${chapter.chapterNumber}', style: TextStyle(color: Colors.white54, fontSize: context.responsive.sp(12), fontWeight: FontWeight.bold)),
      ),
      titleColor: Colors.white,
      context: context,
    );
  }

  Widget _buildLockedChapter(BuildContext context) {
    return _buildStandardRow(
      iconWidget: _buildIconBox(Icons.lock_outline, Colors.white38, context),
      titleColor: Colors.white38,
      context: context,
    );
  }

  // Shared row style for completed and upcoming
  Widget _buildStandardRow({required Widget iconWidget, required Color titleColor, required BuildContext context}) {
     return InkWell(
       onTap: () {
         if (chapter.isLocked) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This chapter is currently locked.')));
         } else {
             context.push('/today-reading/$bookId');
         }
       },
       borderRadius: BorderRadius.circular(context.responsive.sp(12)),
       child: Container(
         margin: EdgeInsets.only(bottom: context.responsive.sp(12)),
         padding: EdgeInsets.all(context.responsive.sp(16)),
         decoration: BoxDecoration(
            color: const Color(0xFF1E233D),
            borderRadius: BorderRadius.circular(context.responsive.sp(12)),
         ),
         child: Row(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
              iconWidget,
              SizedBox(width: context.responsive.wp(16)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text(
                       'Chapter ${chapter.chapterNumber}: ${chapter.title}', 
                       style: TextStyle(color: titleColor, fontSize: context.responsive.sp(13), fontWeight: FontWeight.bold)
                     ),
                     SizedBox(height: context.responsive.sp(8)),
                     Row(
                        children: [
                           Icon(Icons.schedule, color: Colors.white54, size: context.responsive.sp(12)),
                           SizedBox(width: context.responsive.wp(4)),
                           Text('${chapter.pagesCount > 0 ? '${chapter.pagesCount} pages' : chapter.pageRange.isNotEmpty ? chapter.pageRange : '—'}  •  ${chapter.pageRange}', style: TextStyle(color: Colors.white54, fontSize: context.responsive.sp(11))),
                        ],
                     )
                  ],
                ),
              )
           ],
         ),
       ),
     );
  }

  Widget _buildIconBox(IconData icon, Color color, BuildContext context) {
     return Container(
         padding: EdgeInsets.all(context.responsive.sp(8)),
         decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
         child: Icon(icon, color: color, size: context.responsive.sp(18)),
     );
  }
}

