import 'package:flutter/material.dart';
import 'package:gasosa_app/core/app_strings.dart';
import 'package:gasosa_app/theme/app_spacing.dart';
import 'package:gasosa_app/theme/app_typography.dart';

class GasosaEditNameDialog extends StatefulWidget {
  const GasosaEditNameDialog({super.key, required this.currentName});

  final String currentName;

  @override
  State<GasosaEditNameDialog> createState() => _GasosaEditNameDialogState();
}

class _GasosaEditNameDialogState extends State<GasosaEditNameDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty) {
      setState(() => _error = ProfileStrings.errorNameEmpty);
      return;
    }
    if (trimmed.length > 50) {
      setState(() => _error = ProfileStrings.errorNameTooLong);
      return;
    }
    Navigator.of(context).pop(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: const RoundedRectangleBorder(borderRadius: AppSpacing.radiusMd),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Text(
        ProfileStrings.editNameDialogTitle,
        style: AppTypography.textSmBold,
        textAlign: TextAlign.center,
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        maxLength: 50,
        style: AppTypography.textSmRegular,
        decoration: InputDecoration(
          hintText: ProfileStrings.editNameHint,
          errorText: _error,
          counterStyle: AppTypography.textSmRegular.copyWith(color: scheme.onSurfaceVariant),
        ),
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text('Cancelar', style: AppTypography.textSmRegular),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(ProfileStrings.editNameSaveLabel, style: AppTypography.textSmRegular),
        ),
      ],
    );
  }
}

Future<String?> showGasosaEditNameDialog(
  BuildContext context, {
  required String currentName,
}) =>
    showDialog<String>(
      context: context,
      builder: (_) => GasosaEditNameDialog(currentName: currentName),
    );
