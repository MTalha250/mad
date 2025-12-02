import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';

class PriorityBadge extends StatelessWidget {
  final String priority;
  final double? fontSize;

  const PriorityBadge({
    super.key,
    required this.priority,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getPriorityColors(priority);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: colors.text,
          fontSize: fontSize ?? 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  _PriorityColors _getPriorityColors(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return _PriorityColors(
          background: AppColors.priorityLowBg,
          text: AppColors.priorityLowText,
        );
      case 'medium':
        return _PriorityColors(
          background: AppColors.priorityMediumBg,
          text: AppColors.priorityMediumText,
        );
      case 'high':
        return _PriorityColors(
          background: AppColors.priorityHighBg,
          text: AppColors.priorityHighText,
        );
      default:
        return _PriorityColors(
          background: AppColors.background,
          text: AppColors.textSecondary,
        );
    }
  }
}

class _PriorityColors {
  final Color background;
  final Color text;

  _PriorityColors({required this.background, required this.text});
}
