import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gasosa_app/core/di/locator.dart';
import 'package:gasosa_app/presentation/routes/route_paths.dart';
import 'package:gasosa_app/presentation/screens/dashboard/widgets/show_delete_vehicle_confirm_dialog.dart';
import 'package:gasosa_app/presentation/screens/vehicle/viewmodel/vehicle_detail_viewmodel.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_appbar.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_card.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_empty_state_widget.dart';
import 'package:gasosa_app/theme/app_colors.dart';
import 'package:gasosa_app/theme/app_spacing.dart';
import 'package:gasosa_app/theme/app_typography.dart';
import 'package:go_router/go_router.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class VehicleDetailScreen extends StatefulWidget {
  const VehicleDetailScreen({super.key, required this.vehicleId});
  final String vehicleId;

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  late final VehicleDetailViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = getIt<VehicleDetailViewModel>();
    _viewModel.init(widget.vehicleId);
  }

  Future<void> _goToEditVehicle() async {
    context.push(RoutePaths.vehicleManageEdit(widget.vehicleId));
  }

  Future<void> _deleteVehicle() async {
    final confirmed = await showDeleteVehicleConfirmDialog(
      context,
      vehicleName: _viewModel.state.vehicle?.name,
    );
    if (confirmed) {
      _viewModel.deleteVehicle();
      if (mounted) context.go(RoutePaths.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GasosaAppbar(
        title: 'Detalhes do Veículo',
        actions: [
          IconButton(tooltip: 'Editar', onPressed: _goToEditVehicle, icon: const Icon(Icons.edit_outlined)),
          IconButton(tooltip: 'Excluir', onPressed: _deleteVehicle, icon: const Icon(Icons.delete_outline)),
        ],
        onBackPressed: () => context.go(RoutePaths.dashboard),
        showBackButton: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: null,
        icon: const Icon(Icons.local_gas_station_rounded, color: AppColors.text),
        label: Text(
          'Novo abastecimento',
          style: AppTypography.textSmBold.copyWith(color: AppColors.text),
        ),
      ),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (_, __) {
          final state = _viewModel.state;
          final error = state.errorMessage;
          final loading = state.isLoading;

          if (loading) {
            return ColoredBox(
              color: AppColors.background.withValues(alpha: 0.8),
              child: Center(
                child: LoadingAnimationWidget.waveDots(color: AppColors.primary, size: 48),
              ),
            );
          }

          if (error != null) {
            return Padding(
              padding: AppSpacing.paddingMd,
              child: Center(
                child: Text(
                  error,
                  style: AppTypography.textMdBold.copyWith(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final vehicle = state.vehicle!;
          final plate = (vehicle.plate ?? '').toUpperCase();
          final cap = vehicle.tankCapacity?.toStringAsFixed(0) ?? 'N/A';
          final subtitle = [
            if (plate.isNotEmpty) 'Placa: $plate',
            'Capacidade do tanque: $cap${vehicle.tankCapacity != null ? ' L' : ''}',
          ].join(' • ');

          return ListView(
            padding: AppSpacing.paddingMd,
            children: [
              /// Header
              GasosaCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeaderImage(imageUrl: vehicle.photoPath),
                    Padding(
                      padding: AppSpacing.paddingMd,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: AppSpacing.md,
                        children: [
                          Text(vehicle.name, style: AppTypography.titleLg),
                          if (subtitle.isNotEmpty) Text(subtitle, style: AppTypography.textSmRegular),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              /// Fim Header
              AppSpacing.gap16,
              const GasosaCard(
                child: GasosaEmptyStateWidget(
                  title: 'Nenhum abastecimento',
                  message: 'Quando você registrar um abastecimento, ele aparecerá aqui.',
                  actionLabel: 'Adicionar',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderImage extends StatelessWidget {
  const _HeaderImage({this.imageUrl});
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.only(
      topLeft: AppSpacing.radiusMd.topLeft,
      topRight: AppSpacing.radiusMd.topRight,
    );
    final hasPath = imageUrl != null && imageUrl!.isNotEmpty && File(imageUrl!).existsSync();

    return ClipRRect(
      borderRadius: radius,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: hasPath
            ? Image.file(File(imageUrl!), fit: BoxFit.cover)
            : Container(
                color: AppColors.surface,
                alignment: Alignment.center,
                child: const Icon(Icons.directions_car_filled_outlined, size: 64, color: AppColors.primary),
              ),
      ),
    );
  }
}
