import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gasosa_app/core/di/locator.dart';
import 'package:gasosa_app/domain/entities/fuel_type.dart';
import 'package:gasosa_app/presentation/routes/route_paths.dart';
import 'package:gasosa_app/presentation/screens/dashboard/widgets/show_delete_vehicle_confirm_dialog.dart';
import 'package:gasosa_app/presentation/screens/vehicle/viewmodel/vehicle_detail_viewmodel.dart';
import 'package:gasosa_app/presentation/screens/vehicle/widgets/refuel_list.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_appbar.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_card.dart';
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

class _VehicleDetailScreenState extends State<VehicleDetailScreen> with TickerProviderStateMixin {
  late final VehicleDetailViewModel _viewModel;
  late final ScrollController _scrollController;
  late final AnimationController _animationController;

  bool _isExtended = true;

  @override
  void initState() {
    super.initState();
    _viewModel = getIt<VehicleDetailViewModel>();
    _viewModel.init(widget.vehicleId);

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  void _onScroll() {
    if (_scrollController.offset > 100 && _isExtended) {
      setState(() => _isExtended = false);
      _animationController.forward();
    } else if (_scrollController.offset <= 100 && !_isExtended) {
      setState(() => _isExtended = true);
      _animationController.reverse();
    }
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

  Future<void> _goToRefuelManageCreate() async {
    context.push(RoutePaths.refuelManageCreate(widget.vehicleId));
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
      // floatingActionButton: _buildFloatingActionButton(),
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
          final fuelType = vehicle.fuelType.displayName;

          final refuels = state.refuels!;

          return Column(
            children: [
              /// Header
              Padding(
                padding: AppSpacing.paddingMd,
                child: GasosaCard(
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
                            Text('Tipo de Combustível: $fuelType', style: AppTypography.textSmRegular),
                            if (subtitle.isNotEmpty) Text(subtitle, style: AppTypography.textSmRegular),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              /// Fim Header
              ///
              Padding(
                padding: AppSpacing.paddingHorizontalMd,
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: AlignmentGeometry.centerLeft,
                        child: Text('Abastecimentos', style: AppTypography.titleMd),
                      ),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: AppSpacing.radiusLg,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: _goToRefuelManageCreate,
                        borderRadius: AppSpacing.radiusSm,
                        child: const Padding(
                          padding: AppSpacing.paddingMd,
                          child: Icon(
                            Icons.local_gas_station_rounded,
                            color: AppColors.text,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gap8,
              Expanded(
                child: RefuelsList(
                  refuels: refuels,
                  controller: _scrollController,
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
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ignore: unused_element
  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      extendedIconLabelSpacing: _isExtended ? 10 : 0,
      extendedPadding: _isExtended ? null : AppSpacing.paddingMd,
      onPressed: _goToRefuelManageCreate,
      label: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        child: _isExtended
            ? Text(
                'Novo abastecimento',
                style: AppTypography.textSmBold.copyWith(color: AppColors.text),
              )
            : const SizedBox.shrink(key: ValueKey('collapsed')),
      ),
      icon: const Icon(Icons.local_gas_station_rounded, color: AppColors.text),
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

    void previewImage() {
      if (!hasPath) return;
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: AppColors.background,
          insetPadding: AppSpacing.paddingHorizontalSm,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: AppSpacing.radiusMd,
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: Hero(
                    tag: '$imageUrl-vehicle',
                    child: Image.file(
                      File(imageUrl!),
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  backgroundColor: AppColors.surface,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_outlined, color: AppColors.text),
                    tooltip: 'Fechar',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: hasPath ? previewImage : null,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: radius,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: hasPath
                  ? Hero(
                      tag: '$imageUrl-vehicle',
                      child: Image.file(File(imageUrl!), fit: BoxFit.cover),
                    )
                  : Container(
                      color: AppColors.surface,
                      alignment: Alignment.center,
                      child: const Icon(Icons.directions_car_filled_outlined, size: 64, color: AppColors.primary),
                    ),
            ),
          ),
          if (hasPath)
            Positioned(
              top: 8,
              right: 8,
              child: CircleAvatar(
                backgroundColor: AppColors.surface,
                child: IconButton(
                  onPressed: hasPath ? previewImage : null,
                  icon: const Icon(Icons.zoom_in, color: AppColors.text),
                  tooltip: 'Visualizar imagem',
                ),
              ),
            ),
        ],
      ),
    );
  }
}
