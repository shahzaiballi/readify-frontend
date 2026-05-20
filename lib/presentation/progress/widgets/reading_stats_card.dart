import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';

class ReadingStatsCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color backgroundColor;

  const ReadingStatsCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.responsive.sp(16)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            backgroundColor.withValues(alpha: 0.2),
            backgroundColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: backgroundColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(context.responsive.sp(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(context.responsive.sp(8)),
            decoration: BoxDecoration(
              color: backgroundColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(context.responsive.sp(8)),
            ),
            child: Icon(
              icon,
              color: backgroundColor,
              size: context.responsive.sp(20),
            ),
          ),
          SizedBox(height: context.responsive.sp(12)),
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: context.responsive.sp(12),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: context.responsive.sp(4)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: context.responsive.sp(24),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: context.responsive.wp(4)),
              Text(
                unit,
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: context.responsive.sp(11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
