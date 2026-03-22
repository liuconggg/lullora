import 'package:flutter/material.dart';
import '../config/theme.dart';

class ProgressIndicatorWidget extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double height;
  final bool showPercentage;

  const ProgressIndicatorWidget({
    super.key,
    required this.progress,
    this.height = 8,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).toInt();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showPercentage) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall Progress',
                style: AppTheme.bodyMedium,
              ),
              Text(
                '$percentage%',
                style: AppTheme.heading3.copyWith(
                  color: AppTheme.primaryPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: height,
            backgroundColor: AppTheme.borderColor,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.primaryPurple,
            ),
          ),
        ),
      ],
    );
  }
}
