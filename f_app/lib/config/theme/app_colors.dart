import 'package:flutter/material.dart';

class AppColors {
  // Primary brand color (burgundy/maroon)
  static const Color primary = Color(0xFFA82F39);
  static const Color primaryLight = Color(0xFFD4636D);
  static const Color primaryDark = Color(0xFF7A1F29);

  // Background colors
  static const Color background = Color(0xFFF9FAFB); // gray-50
  static const Color surface = Colors.white;
  static const Color scaffoldBackground = Color(0xFFF3F4F6); // gray-100

  // Text colors
  static const Color textPrimary = Color(0xFF111827); // gray-900
  static const Color textSecondary = Color(0xFF6B7280); // gray-500
  static const Color textTertiary = Color(0xFF9CA3AF); // gray-400

  // Status colors
  static const Color success = Color(0xFF16A34A); // green-600
  static const Color error = Color(0xFFDC2626); // red-600
  static const Color warning = Color(0xFFF59E0B); // amber-500
  static const Color info = Color(0xFF3B82F6); // blue-500

  // Status badge backgrounds
  static const Color statusPendingBg = Color(0xFFFEF3C7); // yellow-100
  static const Color statusPendingText = Color(0xFF92400E); // yellow-800
  static const Color statusInProgressBg = Color(0xFFDBEAFE); // blue-100
  static const Color statusInProgressText = Color(0xFF1E40AF); // blue-800
  static const Color statusCompletedBg = Color(0xFFDCFCE7); // green-100
  static const Color statusCompletedText = Color(0xFF166534); // green-800
  static const Color statusCancelledBg = Color(0xFFFEE2E2); // red-100
  static const Color statusCancelledText = Color(0xFF991B1B); // red-800

  // Priority badge backgrounds
  static const Color priorityLowBg = Color(0xFFDBEAFE); // blue-100
  static const Color priorityLowText = Color(0xFF1E40AF); // blue-800
  static const Color priorityMediumBg = Color(0xFFFED7AA); // orange-100
  static const Color priorityMediumText = Color(0xFF9A3412); // orange-800
  static const Color priorityHighBg = Color(0xFFFEE2E2); // red-100
  static const Color priorityHighText = Color(0xFF991B1B); // red-800

  // Payment status colors
  static const Color paymentPendingBg = Color(0xFFFEF3C7);
  static const Color paymentPaidBg = Color(0xFFDCFCE7);
  static const Color paymentOverdueBg = Color(0xFFFEE2E2);

  // Value cell colors (for table cells)
  static const Color hasValueBg = Color(0xFFF0FDF4); // green-50
  static const Color noValueBg = Color(0xFFFEF2F2); // red-50

  // Border colors
  static const Color border = Color(0xFFE5E7EB); // gray-200
  static const Color borderLight = Color(0xFFF3F4F6); // gray-100

  // Gradient for auth screens
  static const List<Color> authGradient = [
    Colors.white,
    Color(0xFFE9F8FF),
  ];

  // Card shadow color
  static const Color shadow = Color(0x1A000000);

  // Input field colors
  static const Color inputBackground = Colors.white;
  static const Color inputBorder = Color(0xFFD1D5DB); // gray-300
  static const Color inputFocusBorder = primary;

  // Divider
  static const Color divider = Color(0xFFE5E7EB); // gray-200

  // Shimmer colors
  static const Color shimmerBase = Color(0xFFE5E7EB); // gray-200
  static const Color shimmerHighlight = Color(0xFFF9FAFB); // gray-50
}
