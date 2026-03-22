import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/condition.dart';

class ConditionCard extends StatelessWidget {
  final int nightNumber;
  final Condition condition;
  final bool isCompleted;
  final bool isCurrent;
  final VoidCallback? onTap;

  const ConditionCard({
    super.key,
    required this.nightNumber,
    required this.condition,
    this.isCompleted = false,
    this.isCurrent = false,
    this.onTap,
  });

  IconData get _conditionIcon {
    switch (condition) {
      case Condition.control:
        return Icons.bedtime;
      case Condition.fixed:
        return Icons.calendar_view_day;
      case Condition.personalized:
        return Icons.auto_awesome;
    }
  }

  Color get _borderColor {
    if (isCompleted) return AppTheme.accentGreen;
    if (isCurrent) return AppTheme.primaryPurple;
    return AppTheme.borderColor;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _borderColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _conditionIcon,
                color: _borderColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Night $nightNumber',
                    style: AppTheme.caption,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    condition.displayName,
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (isCompleted)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
