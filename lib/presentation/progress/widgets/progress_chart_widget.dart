import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../domain/entities/user_stats_entity.dart';

class ProgressChartWidget extends StatelessWidget {
  final UserProgressEntity progress;

  const ProgressChartWidget({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.responsive.wp(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Currently Reading',
            style: TextStyle(
              color: Colors.white,
              fontSize: context.responsive.sp(18),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: context.responsive.sp(16)),
          Container(
            padding: EdgeInsets.all(context.responsive.sp(16)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFB062FF).withValues(alpha: 0.15),
                  const Color(0xFFB062FF).withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: const Color(0xFFB062FF).withValues(alpha: 0.3),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(context.responsive.sp(16)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: context.responsive.sp(60),
                      height: context.responsive.sp(80),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(context.responsive.sp(8)),
                        image: DecorationImage(
                          image: NetworkImage(progress.imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(width: context.responsive.sp(16)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            progress.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: context.responsive.sp(16),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: context.responsive.sp(4)),
                          Text(
                            'by ${progress.author}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: context.responsive.sp(12),
                            ),
                          ),
                          SizedBox(height: context.responsive.sp(12)),
                          Row(
                            children: [
                              Text(
                                '${progress.progressPercent}%',
                                style: TextStyle(
                                  color: const Color(0xFFB062FF),
                                  fontSize: context.responsive.sp(14),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: context.responsive.sp(8)),
                              Text(
                                'Complete',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: context.responsive.sp(12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.responsive.sp(16)),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(context.responsive.sp(8)),
                  child: LinearProgressIndicator(
                    value: progress.progressPercent / 100,
                    minHeight: context.responsive.sp(8),
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFB062FF)),
                  ),
                ),
                SizedBox(height: context.responsive.sp(12)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '0%',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: context.responsive.sp(11),
                      ),
                    ),
                    Text(
                      '100%',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: context.responsive.sp(11),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
