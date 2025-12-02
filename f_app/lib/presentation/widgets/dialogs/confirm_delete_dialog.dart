import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';

class ConfirmDeleteDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final VoidCallback onConfirm;

  const ConfirmDeleteDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Delete',
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error),
          const SizedBox(width: 12),
          Text(title),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, true);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }
}

Future<bool?> showConfirmDeleteDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmText = 'Delete',
  required VoidCallback onConfirm,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => ConfirmDeleteDialog(
      title: title,
      message: message,
      confirmText: confirmText,
      onConfirm: onConfirm,
    ),
  );
}
