import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gasosa_app/core/app_strings.dart';
import 'package:gasosa_app/core/di/injection.dart';
import 'package:gasosa_app/core/helpers/formatters.dart';
import 'package:gasosa_app/core/helpers/numeric_parser.dart';
import 'package:gasosa_app/core/presentation/ui_state.dart';
import 'package:gasosa_app/core/validators/refuel_validators.dart';
import 'package:gasosa_app/domain/entities/fuel_type.dart';
import 'package:gasosa_app/presentation/screens/refuel/viewmodel/manage_refuel_viewmodel.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_appbar.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_button.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_checkbox.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_confirm_dialog.dart';
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
  late final ManageRefuelViewModel _viewmodel;
  final _formKey = GlobalKey<FormState>();
  final _mileageEC = TextEditingController();
  final _totalValueEC = TextEditingController();
  final _litersEC = TextEditingController();
  final _coldStartLitersEC = TextEditingController();
  final _coldStartValueEC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewmodel = getIt<ManageRefuelViewModel>();
    _viewmodel.init(widget.refuelId, widget.vehicleId);
    _viewmodel.loadCommand.state.addListener(_onLoadStateChanged);
  }

  void _onLoadStateChanged() {
    if (_viewmodel.loadCommand.state.value is! UiData) return;
    if (widget.refuelId != null) {
      final s = _viewmodel.state.value;
      _mileageEC.text = NumericParser.formatInt(s.mileage);
      _totalValueEC.text = NumericParser.formatDouble(s.totalValue);
      _litersEC.text = NumericParser.formatDouble(s.liters);
      _coldStartLitersEC.text = s.coldStartLiters != null ? NumericParser.formatDouble(s.coldStartLiters!) : '';
      _coldStartValueEC.text = s.coldStartValue != null ? NumericParser.formatDouble(s.coldStartValue!) : '';
    }
    _viewmodel.loadCommand.state.removeListener(_onLoadStateChanged);
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
    final confirmed = await showGasosaConfirmDialog(
      context,
      title: RefuelStrings.deleteDialogTitle,
      content: RefuelStrings.deleteDialogMessage,
      confirmLabel: RefuelStrings.deleteDialogConfirmLabel,
      danger: true,
    );
    if (!confirmed) return;

    final response = await _viewmodel.delete();
    if (!mounted) return;
    response?.fold(
      (failure) => Messages.showError(context, failure.message),
      (_) {
        Messages.showSuccess(context, RefuelStrings.deleteSuccess);
        context.pop(true);
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
              _viewmodel.deleteCommand.state.value is UiLoading ||
              _viewmodel.photoCommand.state.value is UiLoading;

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
                      hint: RefuelStrings.mileageHint,
                      controller: _mileageEC,
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
                      hint: RefuelStrings.litersHint,
                      controller: _litersEC,
                      validator: RefuelValidators.liters,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [DigitDecimalInputFormatter()],
                      onChanged: _viewmodel.updateLiters,
                    ),
                    GasosaFormField(
                      label: RefuelStrings.totalValueLabel,
                      hint: RefuelStrings.totalValueHint,
                      controller: _totalValueEC,
                      validator: RefuelValidators.totalValue,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [MoneyInputFormatterWithoutSymbol()],
                      onChanged: _viewmodel.updateTotalValue,
                    ),
                    if (_viewmodel.shouldShowColdStart) ...[
                      GasosaCheckbox(
                        title: RefuelStrings.coldStartCheckboxLabel,
                        value: _viewmodel.hasColdStart,
                        onChanged: (value) {
                          setState(() => _viewmodel.setColdStart(value: value));
                          if (!value) {
                            _coldStartLitersEC.clear();
                            _coldStartValueEC.clear();
                          }
                        },
                      ),
                      if (_viewmodel.hasColdStart) ...[
                        GasosaFormField(
                          label: RefuelStrings.coldStartLitersLabel,
                          hint: RefuelStrings.coldStartLitersHint,
                          controller: _coldStartLitersEC,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [DigitDecimalInputFormatter()],
                          onChanged: _viewmodel.updateColdStartLiters,
                        ),
                        GasosaFormField(
                          label: RefuelStrings.coldStartValueLabel,
                          hint: RefuelStrings.coldStartValueHint,
                          controller: _coldStartValueEC,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [MoneyInputFormatterWithoutSymbol()],
                          onChanged: _viewmodel.updateColdStartValue,
                        ),
                      ],
                    ],
                    GasosaCheckbox(
                      title: RefuelStrings.receiptCheckboxLabel,
                      value: _viewmodel.hasReceiptPhoto,
                      onChanged: (value) => setState(() => _viewmodel.toggleReceiptPhoto(value: value)),
                    ),
                    if (_viewmodel.shouldShowReceiptPhotoInput) ...[
                      GasosaPhotoPicker(
                        label: RefuelStrings.receiptPhotoLabel,
                        image: _viewmodel.currentReceiptPhoto,
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
                        if (_viewmodel.isEditing) ...[
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
        Text(RefuelStrings.fuelTypeLabel, style: AppTypography.textSmBold),
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
    _mileageEC.dispose();
    _totalValueEC.dispose();
    _litersEC.dispose();
    _coldStartLitersEC.dispose();
    _coldStartValueEC.dispose();
    super.dispose();
  }
}
