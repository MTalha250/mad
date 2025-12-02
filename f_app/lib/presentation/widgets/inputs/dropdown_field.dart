import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';

class DropdownField<T> extends StatelessWidget {
  final String? label;
  final String? hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;
  final bool enabled;
  final IconData? prefixIcon;

  const DropdownField({
    super.key,
    this.label,
    this.hint,
    this.value,
    required this.items,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    // Find the selected item's child widget to display
    Widget? selectedChild;
    for (final item in items) {
      if (item.value == value) {
        selectedChild = item.child;
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        PopupMenuButton<T>(
          enabled: enabled,
          initialValue: value,
          onSelected: onChanged,
          offset: const Offset(0, 50),
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          itemBuilder: (context) => items
              .map((item) => PopupMenuItem<T>(
                    value: item.value,
                    child: item.child,
                  ))
              .toList(),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: prefixIcon != null ? 8 : 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: enabled ? AppColors.inputBackground : AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Row(
              children: [
                if (prefixIcon != null) ...[
                  Icon(prefixIcon, color: AppColors.textSecondary, size: 20),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: selectedChild ??
                      Text(
                        hint ?? 'Select',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                ),
                const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
