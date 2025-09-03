import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:gasosa_app/theme/app_spacing.dart';
import 'package:gasosa_app/theme/app_typography.dart';

class GasosaDropdownField<T> extends StatelessWidget {
  const GasosaDropdownField({
    super.key,
    required this.label,
    this.value,
    this.items,
    required this.onChanged,
    this.isDense = true,
    this.isExpanded = true,
    this.enabled = true,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>>? items;
  final void Function(T?)? onChanged;
  final bool isDense;
  final bool isExpanded;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.sm,
      children: [
        Text(
          label,
          style: AppTypography.textSmBold,
        ),
        DropdownButtonFormField2<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isDense: isDense,
          isExpanded: isExpanded,
          buttonStyleData: const ButtonStyleData(
            height: 42,
            padding: EdgeInsets.only(left: AppSpacing.xs, right: AppSpacing.xs),
          ),
          decoration: InputDecoration(
            isDense: isDense,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.md)),
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.sm),
          ),
        ),
      ],
    );
  }
}
