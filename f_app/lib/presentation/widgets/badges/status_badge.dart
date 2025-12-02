import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double? fontSize;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getStatusColors(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: colors.text,
          fontSize: fontSize ?? 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  _StatusColors _getStatusColors(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return _StatusColors(
          background: AppColors.statusPendingBg,
          text: AppColors.statusPendingText,
        );
      case 'in progress':
        return _StatusColors(
          background: AppColors.statusInProgressBg,
          text: AppColors.statusInProgressText,
        );
      case 'completed':
        return _StatusColors(
          background: AppColors.statusCompletedBg,
          text: AppColors.statusCompletedText,
        );
      case 'cancelled':
        return _StatusColors(
          background: AppColors.statusCancelledBg,
          text: AppColors.statusCancelledText,
        );
      case 'approved':
        return _StatusColors(
          background: AppColors.statusCompletedBg,
          text: AppColors.statusCompletedText,
        );
      case 'rejected':
        return _StatusColors(
          background: AppColors.statusCancelledBg,
          text: AppColors.statusCancelledText,
        );
      default:
        return _StatusColors(
          background: AppColors.background,
          text: AppColors.textSecondary,
        );
    }
  }
}

class _StatusColors {
  final Color background;
  final Color text;

  _StatusColors({required this.background, required this.text});
}
