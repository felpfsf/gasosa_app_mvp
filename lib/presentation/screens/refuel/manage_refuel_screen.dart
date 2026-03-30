import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gasosa_app/core/app_strings.dart';
import 'package:gasosa_app/core/di/injection.dart';
import 'package:gasosa_app/core/helpers/formatters.dart';
import 'package:gasosa_app/core/presentation/ui_state.dart';
import 'package:gasosa_app/core/validators/refuel_validators.dart';
import 'package:gasosa_app/domain/entities/fuel_type.dart';
import 'package:gasosa_app/presentation/screens/refuel/viewmodel/manage_refuel_viewmodel.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_appbar.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_button.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_checkbox.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_date_picker_field.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_dropdown_field.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_form_field.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_photo_picker.dart';
import 'package:gasosa_app/presentation/widgets/messages.dart';
import 'package:gasosa_app/theme/app_colors.dart';
import 'package:gasosa_app/theme/app_spacing.dart';
import 'package:gasosa_app/theme/app_typography.dart';
import 'package:go_router/go_router.dart';

class ManageRefuelScreen extends StatefulWidget {
  const ManageRefuelScreen({super.key, this.refuelId, this.vehicleId});
  final String? refuelId;
  final String? vehicleId;

  @override
  State<ManageRefuelScreen> createState() => _ManageRefuelScreenState();
}

class _ManageRefuelScreenState extends State<ManageRefuelScreen> {
  late final ManageRefuelViewmodel _viewmodel;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _viewmodel = getIt<ManageRefuelViewmodel>();
    _viewmodel.init(widget.refuelId, widget.vehicleId);
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    final response = await _viewmodel.save();

    response?.fold(
      (failure) => Messages.showError(context, failure.message),
      (_) {
        Messages.showSuccess(context, RefuelStrings.saveSuccess);
        if (mounted) context.pop(true);
      },
    );
  }

  Future<void> _onDelete() async {
    final response = await _viewmodel.delete();
    response?.fold(
      (failure) => Messages.showError(context, failure.message),
      (_) {
        Messages.showSuccess(context, RefuelStrings.deleteSuccess);
        if (mounted) context.pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GasosaAppbar(
        title: widget.refuelId != null ? RefuelStrings.appBarTitleEdit : RefuelStrings.appBarTitleCreate,
        showBackButton: true,
        onBackPressed: () => context.pop(),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          _viewmodel.state,
          _viewmodel.loadCommand.state,
          _viewmodel.saveCommand.state,
          _viewmodel.deleteCommand.state,
          _viewmodel.photoCommand.state,
        ]),
        builder: (context, _) {
          final state = _viewmodel.state.value;
          final isLoading =
              _viewmodel.loadCommand.state.value is UiLoading ||
              _viewmodel.saveCommand.state.value is UiLoading ||
              _viewmodel.deleteCommand.state.value is UiLoading;

          return SafeArea(
            child: SingleChildScrollView(
              padding: AppSpacing.paddingMd,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.md,
                  children: [
                    GasosaDatePickerField(
                      label: RefuelStrings.dateLabel,
                      initialDate: state.refuelDate,
                      onChanged: _viewmodel.updateRefuelDate,
                    ),
                    GasosaFormField(
                      label: RefuelStrings.mileageLabel,
                      controller: _viewmodel.mileageEC,
                      validator: _viewmodel.mileageValidator,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: _viewmodel.updateMileage,
                    ),
                    if (state.availableFuelTypes.length > 1) ...[
                      GasosaDropdownField<FuelType>(
                        label: RefuelStrings.fuelTypeLabel,
                        value: state.fuelType,
                        items: state.availableFuelTypes,
                        labelOf: (e) => e.displayName,
                        onChanged: (value) {
                          if (value != null) {
                            _viewmodel.updateFuelType(value);
                          }
                        },
                      ),
                    ] else if (state.availableFuelTypes.length == 1) ...[
                      _buildFixedFuelType(state.fuelType.displayName),
                    ],
                    GasosaFormField(
                      label: RefuelStrings.litersLabel,
                      controller: _viewmodel.litersEC,
                      validator: RefuelValidators.liters,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [DigitDecimalInputFormatter()],
                      onChanged: _viewmodel.updateLiters,
                    ),
                    GasosaFormField(
                      label: RefuelStrings.totalValueLabel,
                      controller: _viewmodel.totalValueEC,
                      validator: RefuelValidators.totalValue,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [MoneyInputFormatterWithoutSymbol()],
                      onChanged: _viewmodel.updateTotalValue,
                    ),
                    if (_viewmodel.shouldShowColdStart) ...[
                      GasosaCheckbox(
                        title: RefuelStrings.coldStartCheckboxLabel,
                        value: _viewmodel.hasColdStart,
                        onChanged: (value) => setState(() => _viewmodel.hasColdStart = value ?? false),
                      ),
                      if (_viewmodel.hasColdStart) ...[
                        GasosaFormField(
                          label: RefuelStrings.coldStartLitersLabel,
                          controller: _viewmodel.coldStartLitersEC,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [DigitDecimalInputFormatter()],
                          onChanged: _viewmodel.updateColdStartLiters,
                        ),
                        GasosaFormField(
                          label: RefuelStrings.coldStartValueLabel,
                          controller: _viewmodel.coldStartValueEC,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [MoneyInputFormatterWithoutSymbol()],
                          onChanged: _viewmodel.updateColdStartValue,
                        ),
                      ],
                    ],
                    GasosaCheckbox(
                      title: RefuelStrings.receiptCheckboxLabel,
                      value: _viewmodel.hasReceiptPhoto,
                      onChanged: (value) => setState(() => _viewmodel.hasReceiptPhoto = value ?? false),
                    ),
                    if (_viewmodel.shouldShowReceiptPhotoInput) ...[
                      GasosaPhotoPicker(
                        label: RefuelStrings.receiptPhotoLabel,
                        image: state.receiptPath != null ? File(state.receiptPath!) : null,
                        onFileSelected: (file) async {
                          if (file == null) {
                            _viewmodel.onRemovePhoto();
                          } else {
                            await _viewmodel.onPickLocalPhoto(file);
                          }
                        },
                      ),
                    ],

                    AppSpacing.gap4,
                    const Divider(thickness: 1, color: AppColors.border),

                    Row(
                      spacing: AppSpacing.md,
                      children: [
                        Expanded(
                          child: GasosaButton(
                            label: RefuelStrings.saveButton,
                            onPressed: isLoading ? null : _onSave,
                          ),
                        ),
                        if (state.isEditing) ...[
                          Expanded(
                            child: GasosaButton(
                              label: RefuelStrings.deleteButton,
                              variant: GasosaButtonVariant.danger,
                              onPressed: isLoading ? null : _onDelete,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFixedFuelType(String fuelType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.sm,
      children: [
        Text('Tipo de Combustível', style: AppTypography.textSmBold),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppSpacing.sm),
            color: AppColors.surface.withValues(alpha: 0.5),
          ),
          child: Text(
            fuelType,
            style: AppTypography.textSmRegular.copyWith(color: AppColors.text.withValues(alpha: .6)),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _viewmodel.dispose();
    super.dispose();
  }
}
