import 'package:flutter/material.dart';
import 'package:gasosa_app/theme/app_colors.dart';
import 'package:gasosa_app/theme/app_spacing.dart';
import 'package:gasosa_app/theme/app_typography.dart';
import 'package:intl/intl.dart';

class GasosaDatePickerField extends StatelessWidget {
  const GasosaDatePickerField({
    super.key,
    required this.label,
    this.initialDate,
    this.onChanged,
  });

  final String label;
  final DateTime? initialDate;
  final Function(DateTime)? onChanged;

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime>(
      initialValue: initialDate,
      builder: (state) {
        final formattedDate = state.value != null ? DateFormat('dd/MM/yyyy', 'pt_BR').format(state.value!) : '';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.md,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            GestureDetector(
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: state.value ?? DateTime.now(),
                  firstDate: DateTime(now.year - 5),
                  lastDate: DateTime(now.year + 5),
                  builder: (context, child) => Theme(data: Theme.of(context), child: child!),
                );
                if (picked != null) {
                  state.didChange(picked);
                  onChanged?.call(picked);
                }
              },
              // child: Text(state.value?.toLocal().toString() ?? 'Selecione uma data'),
              child: AbsorbPointer(
                child: TextField(
                  controller: TextEditingController(text: formattedDate),
                  decoration: InputDecoration(
                    hintText: 'Selecione uma data',
                    hintStyle: AppTypography.textSmRegular.copyWith(color: AppColors.text.withValues(alpha: .75)),
                    suffixIcon: const Icon(Icons.calendar_today_rounded),
                    border: const OutlineInputBorder(),
                    errorText: state.errorText,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
