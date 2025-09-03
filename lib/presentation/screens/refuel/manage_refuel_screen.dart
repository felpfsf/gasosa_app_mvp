import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gasosa_app/core/di/locator.dart';
import 'package:gasosa_app/core/helpers/formatters.dart';
import 'package:gasosa_app/core/validators/refuel_validators.dart';
import 'package:gasosa_app/domain/entities/fuel_type.dart';
import 'package:gasosa_app/presentation/routes/route_paths.dart';
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

    response.fold(
      (failure) => Messages.showError(context, failure.message),
      (_) {
        Messages.showSuccess(context, 'Abastecimento salvo com sucesso!');
        // TODO(felipe): navegação voltar corretamente para a tela de detalhes do veículo
        if (mounted) context.go(RoutePaths.dashboard);
      },
    );
  }

  Future<void> _onDelete() async {
    final response = await _viewmodel.delete();
    response.fold(
      (failure) => Messages.showError(context, failure.message),
      (_) {
        Messages.showSuccess(context, 'Abastecimento excluído com sucesso!');
        // TODO(felipe): navegação voltar corretamente para a tela de detalhes do veículo
        if (mounted) context.go(RoutePaths.dashboard);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GasosaAppbar(
        title: widget.refuelId != null ? 'Editar Abastecimento' : 'Adicionar Abastecimento',
        showBackButton: true,
        // TODO(felipe): navegação voltar corretamente para a tela de detalhes do veículo
        onBackPressed: () => context.go(RoutePaths.dashboard),
      ),
      body: AnimatedBuilder(
        animation: _viewmodel,
        builder: (context, _) {
          final state = _viewmodel.state;

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
                      label: 'Data do Abastecimento',
                      initialDate: state.refuelDate,
                      onChanged: _viewmodel.updateRefuelDate,
                    ),
                    GasosaFormField(
                      label: 'KM atual',
                      controller: _viewmodel.mileageEC,
                      validator: RefuelValidators.mileage,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: _viewmodel.updateMileage,
                    ),
                    if (state.availableFuelTypes.isNotEmpty) ...[
                      GasosaDropdownField<FuelType>(
                        label: 'Tipo de Combustível',
                        value: state.fuelType,
                        items: state.availableFuelTypes
                            .map((e) => DropdownMenuItem(value: e, child: Text(e.displayName)))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            _viewmodel.updateFuelType(value);
                          }
                        },
                      ),
                    ] else if (state.availableFuelTypes.isNotEmpty) ...[
                      // TODO(felipe): Alterar para um widget
                      Column(
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
                              state.fuelType.displayName,
                              style: AppTypography.textSmRegular.copyWith(color: AppColors.text.withValues(alpha: .6)),
                            ),
                          ),
                        ],
                      ),
                    ],

                    GasosaFormField(
                      label: 'Litros abastecidos',
                      controller: _viewmodel.litersEC,
                      validator: RefuelValidators.liters,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [DigitDecimalInputFormatter()],
                      onChanged: _viewmodel.updateLiters,
                    ),
                    GasosaFormField(
                      label: 'Valor total',
                      controller: _viewmodel.totalValueEC,
                      validator: RefuelValidators.totalValue,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [MoneyInputFormatterWithoutSymbol()],
                      onChanged: _viewmodel.updateTotalValue,
                    ),
                    if (_viewmodel.shouldShowColdStart) ...[
                      GasosaCheckbox(
                        title: 'Abasteceu partida a frio?',
                        value: _viewmodel.hasColdStart,
                        onChanged: (value) => setState(() => _viewmodel.hasColdStart = value ?? false),
                      ),
                      if (_viewmodel.hasColdStart) ...[
                        GasosaFormField(
                          label: 'Litros abastecidos (partida a frio)',
                          controller: _viewmodel.coldStartLitersEC,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [DigitDecimalInputFormatter()],
                          onChanged: _viewmodel.updateColdStartLiters,
                        ),
                        GasosaFormField(
                          label: 'Valor total (partida a frio)',
                          controller: _viewmodel.coldStartValueEC,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [MoneyInputFormatterWithoutSymbol()],
                          onChanged: _viewmodel.updateColdStartValue,
                        ),
                      ],
                    ],
                    GasosaCheckbox(
                      title: 'Comprovante de Abastecimento?',
                      value: _viewmodel.hasReceiptPhoto,
                      onChanged: (value) => setState(() => _viewmodel.hasReceiptPhoto = value ?? false),
                    ),
                    if (_viewmodel.shouldShowReceiptPhotoInput) ...[
                      GasosaPhotoPicker(
                        label: 'Comprovante de Abastecimento',
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
                            label: 'Salvar',
                            onPressed: state.isLoading ? null : _onSave,
                          ),
                        ),
                        if (state.isEditing) ...[
                          Expanded(
                            child: GasosaButton(
                              label: 'Excluir',
                              variant: GasosaButtonVariant.danger,
                              onPressed: state.isLoading ? null : _onDelete,
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

  @override
  void dispose() {
    _viewmodel.dispose();
    super.dispose();
  }
}
