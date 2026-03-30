import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gasosa_app/core/app_strings.dart';
import 'package:gasosa_app/core/di/injection.dart';
import 'package:gasosa_app/core/helpers/formatters.dart';
import 'package:gasosa_app/core/presentation/ui_state.dart';
import 'package:gasosa_app/core/validators/vehicle_validators.dart';
import 'package:gasosa_app/domain/entities/fuel_type.dart';
import 'package:gasosa_app/presentation/screens/vehicle/viewmodel/manage_vehicle_viewmodel.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_appbar.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_button.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_dropdown_field.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_form_field.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_photo_picker.dart';
import 'package:gasosa_app/presentation/widgets/messages.dart';
import 'package:gasosa_app/theme/app_colors.dart';
import 'package:gasosa_app/theme/app_spacing.dart';
import 'package:go_router/go_router.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class ManageVehicleScreen extends StatefulWidget {
  const ManageVehicleScreen({super.key, this.vehicleId});
  final String? vehicleId;

  @override
  State<ManageVehicleScreen> createState() => _ManageVehicleScreenState();
}

class _ManageVehicleScreenState extends State<ManageVehicleScreen> {
  late final ManageVehicleViewModel _viewmodel;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _plateController = TextEditingController();
  final _tankController = TextEditingController();
  bool _didPopulate = false;

  @override
  void initState() {
    super.initState();
    _viewmodel = getIt<ManageVehicleViewModel>();
    _viewmodel.init(vehicleId: widget.vehicleId);
  }

  void _populateControllersIfNeeded(ManageVehicleState s) {
    if (_didPopulate || !s.isEdit || s.initial == null) return;
    _nameController.text = s.name;
    _plateController.text = s.plate;
    _tankController.text = s.tankCapacity;
    _didPopulate = true;
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    final response = await _viewmodel.save();
    response?.fold(
      (failure) => Messages.showError(context, failure.message),
      (_) {
        Messages.showSuccess(context, VehicleStrings.saveSuccess);
        if (mounted) context.pop(true);
      },
    );
  }

  Future<void> _onDelete() async {
    // GasosaConfirmDialog
    final res = await _viewmodel.delete();
    res?.fold(
      (f) => Messages.showError(context, f.message),
      (_) {
        Messages.showSuccess(context, VehicleStrings.deleteSuccess);
        if (mounted) context.pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.vehicleId != null;

    return Scaffold(
      appBar: GasosaAppbar(
        title: isEdit ? VehicleStrings.appBarTitleEdit : VehicleStrings.appBarTitleCreate,
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
        builder: (_, _) {
          final s = _viewmodel.state.value;
          _populateControllersIfNeeded(s);
          final isLoading =
              _viewmodel.loadCommand.state.value is UiLoading ||
              _viewmodel.saveCommand.state.value is UiLoading ||
              _viewmodel.deleteCommand.state.value is UiLoading ||
              _viewmodel.photoCommand.state.value is UiLoading;
          final currentImage = (s.photoPath != null && s.photoPath!.isNotEmpty) ? File(s.photoPath!) : null;

          return Stack(
            children: [
              SafeArea(
                child: SingleChildScrollView(
                  padding: AppSpacing.paddingMd,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: AppSpacing.md,
                      children: [
                        GasosaFormField(
                          label: VehicleStrings.nameLabel,
                          controller: _nameController,
                          onChanged: _viewmodel.updateName,
                          validator: VehicleValidators.name,
                        ),
                        GasosaFormField(
                          label: VehicleStrings.plateLabel,
                          controller: _plateController,
                          onChanged: _viewmodel.updatePlate,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              return VehicleValidators.plate(value);
                            }
                            return null;
                          },
                        ),
                        GasosaFormField(
                          label: VehicleStrings.tankCapacityLabel,
                          controller: _tankController,
                          onChanged: _viewmodel.updateTankCapacity,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: VehicleValidators.tankCapacity,
                          inputFormatters: [DigitDecimalInputFormatter()],
                        ),
                        GasosaDropdownField<FuelType>(
                          label: VehicleStrings.fuelTypeLabel,
                          value: s.fuelType,
                          items: FuelType.values,
                          labelOf: (e) => e.displayName,
                          onChanged: (value) {
                            if (value != null) {
                              _viewmodel.updateFuelType(value);
                            }
                          },
                        ),
                        GasosaPhotoPicker(
                          label: VehicleStrings.photoLabel,
                          image: currentImage,
                          onFileSelected: (file) async {
                            if (file == null) {
                              _viewmodel.onRemovePhoto();
                            } else {
                              await _viewmodel.onPickLocalPhoto(file);
                            }
                          },
                        ),

                        AppSpacing.gap4,
                        const Divider(thickness: 1, color: AppColors.border),

                        Row(
                          spacing: AppSpacing.md,
                          children: [
                            Expanded(
                              child: GasosaButton(
                                label: VehicleStrings.saveButton,
                                onPressed: isLoading ? null : _onSave,
                              ),
                            ),
                            if (s.isEdit) ...[
                              Expanded(
                                child: GasosaButton(
                                  label: VehicleStrings.deleteButton,
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
              ),

              if (isLoading)
                Container(
                  color: Colors.black.withValues(alpha: .08),
                  child: ColoredBox(
                    color: AppColors.background.withValues(alpha: 0.8),
                    child: Center(
                      child: LoadingAnimationWidget.waveDots(color: AppColors.primary, size: 48),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _viewmodel.dispose();
    _nameController.dispose();
    _plateController.dispose();
    _tankController.dispose();
    super.dispose();
  }
}
