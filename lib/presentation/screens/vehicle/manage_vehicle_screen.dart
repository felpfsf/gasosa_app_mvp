import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gasosa_app/core/di/locator.dart';
import 'package:gasosa_app/presentation/screens/vehicle/viewmodel/manage_vehicle_viewmodel.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_appbar.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_button.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_form_field.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_photo_picker.dart';
import 'package:gasosa_app/presentation/widgets/messages.dart';
import 'package:gasosa_app/theme/app_colors.dart';
import 'package:gasosa_app/theme/app_spacing.dart';

class ManageVehicleScreen extends StatefulWidget {
  const ManageVehicleScreen({super.key, this.vehicleId});
  final String? vehicleId;

  @override
  State<ManageVehicleScreen> createState() => _ManageVehicleScreenState();
}

class _ManageVehicleScreenState extends State<ManageVehicleScreen> {
  late final ManageVehicleViewModel _viewmodel;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _viewmodel = getIt<ManageVehicleViewModel>();
    _viewmodel.init(vehicleId: widget.vehicleId);
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    final response = await _viewmodel.save();
    response.fold(
      (failure) => Messages.showError(context, failure.message),
      (_) {
        Messages.showSuccess(context, 'Veículo salvo com sucesso!');
        if (mounted) Navigator.of(context).pop(true);
      },
    );
  }

  Future<void> _onDelete() async {
    // GasosaConfirmDialog
    final res = await _viewmodel.delete();
    res.fold(
      (f) => Messages.showError(context, f.message),
      (_) {
        Messages.showSuccess(context, 'Veículo excluído!');
        if (mounted) Navigator.of(context).pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.vehicleId != null;

    return Scaffold(
      appBar: GasosaAppbar(title: isEdit ? 'Editar Veículo' : 'Adicionar Veículo'),
      body: AnimatedBuilder(
        animation: _viewmodel,
        builder: (_, __) {
          final s = _viewmodel.state;
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
                          label: 'Nome',
                          controller: _viewmodel.nameEC,
                          onChanged: _viewmodel.updateName,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome do veículo' : null,
                        ),
                        GasosaFormField(
                          label: 'Placa (opcional)',
                          controller: _viewmodel.plateEC,
                          onChanged: _viewmodel.updatePlate,
                        ),
                        GasosaFormField(
                          label: 'Capacidade do Tanque (L) — opcional',
                          controller: _viewmodel.tankCapacityEC,
                          onChanged: _viewmodel.updateTankCapacity,
                          // inputFormatters aqui (DigitDecimalInputFormatter)
                        ),

                        GasosaPhotoPicker(
                          label: 'Foto do Veículo - opcional',
                          image: currentImage,
                          onFileSelected: (file) => _viewmodel.updatePhotoPath(file?.path),
                        ),

                        AppSpacing.gap4,
                        const Divider(thickness: 1, color: AppColors.border),

                        Row(
                          children: [
                            Expanded(
                              child: GasosaButton(label: 'Salvar', onPressed: s.isLoading ? null : _onSave),
                            ),
                            if (s.isEdit) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: GasosaButton(
                                  label: 'Excluir',
                                  variant: GasosaButtonVariant.danger,
                                  onPressed: s.isLoading ? null : _onDelete,
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

              if (s.isLoading)
                Container(
                  color: Colors.black.withValues(alpha: .08),
                  child: const Center(child: CircularProgressIndicator()),
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
    super.dispose();
  }
}
