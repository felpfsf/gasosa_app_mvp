import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gasosa_app/core/app_strings.dart';
import 'package:gasosa_app/core/di/injection.dart';
import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/presentation/ui_state.dart';
import 'package:gasosa_app/domain/entities/vehicle.dart';
import 'package:gasosa_app/presentation/routes/route_paths.dart';
import 'package:gasosa_app/presentation/screens/dashboard/widgets/show_delete_vehicle_confirm_dialog.dart';
import 'package:gasosa_app/presentation/screens/vehicle/viewmodel/vehicle_detail_viewmodel.dart';
import 'package:gasosa_app/presentation/screens/vehicle/widgets/refuel_list.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_appbar.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_error_state_widget.dart';
import 'package:gasosa_app/presentation/widgets/messages.dart';
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
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _viewModel = getIt<VehicleDetailViewModel>();
    _viewModel.init(widget.vehicleId);

    _scrollController = ScrollController();
  }

  Future<void> _goToEditVehicle() async {
    final result = await context.push(Routes.manageVehiclePath(widget.vehicleId));
    if (result == true) {
      _viewModel.init(widget.vehicleId);
    }
  }

  Future<void> _deleteVehicle() async {
    final confirmed = await showDeleteVehicleConfirmDialog(
      context,
      vehicleName: _viewModel.vehicle.value?.name,
    );
    if (!confirmed) return;

    final result = await _viewModel.deleteVehicle(widget.vehicleId);
    if (!mounted) return;

    result?.fold(
      (failure) => Messages.showError(context, failure.message),
      (_) => context.pop(true),
    );
  }

  Future<void> _goToRefuelManageCreate() async {
    final result = await context.push(Routes.manageRefuelPath(vehicleId: widget.vehicleId));
    if (result == true) {
      _viewModel.init(widget.vehicleId);
    }
  }

  Future<void> _goToRefuelManageEdit(String refuelId) async {
    final result = await context.push(Routes.manageRefuelPath(refuelId: refuelId));
    if (result == true) {
      _viewModel.init(widget.vehicleId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GasosaAppbar(
        title: VehicleStrings.appBarTitleDetail,
        actions: [
          IconButton(
            tooltip: VehicleStrings.editTooltip,
            onPressed: _goToEditVehicle,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: VehicleStrings.deleteTooltip,
            onPressed: _deleteVehicle,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
        onBackPressed: () {
          if (Navigator.canPop(context)) {
            context.pop();
          } else {
            context.go(Routes.dashboard);
          }
        },
        showBackButton: true,
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          _viewModel.loadCommand.state,
          _viewModel.deleteCommand.state,
          _viewModel.vehicle,
          _viewModel.refuels,
        ]),
        builder: (_, _) {
          final loadState = _viewModel.loadCommand.state.value;

          if (loadState is UiLoading || loadState is UiInitial) {
            return ColoredBox(
              color: AppColors.background.withValues(alpha: 0.8),
              child: Center(
                child: LoadingAnimationWidget.waveDots(color: AppColors.primary, size: 48),
              ),
            );
          }

          if (loadState is UiError<Unit>) {
            return GasosaErrorStateWidget(
              errorMessage: loadState.message,
            );
          }

          final vehicle = _viewModel.vehicle.value;
          if (vehicle == null) {
            return Center(child: LoadingAnimationWidget.waveDots(color: AppColors.primary, size: 48));
          }

          final refuels = _viewModel.refuels.value;

          final imageHeight = MediaQuery.of(context).size.width * (9.0 / 16.0);
          final expandedHeight = imageHeight + 132.0;

          return RefreshIndicator(
            onRefresh: () => _viewModel.refresh(widget.vehicleId),
            edgeOffset: expandedHeight,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _VehicleHeaderDelegate(
                    vehicle: vehicle,
                    fuelTypeLabel: _viewModel.fuelTypeLabel,
                    subtitle: _viewModel.vehicleSubtitle,
                    expandedHeight: expandedHeight,
                  ),
                ),
                SliverPadding(
                  padding: AppSpacing.paddingHorizontalMd,
                  sliver: SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(VehicleStrings.refuelsSectionTitle, style: AppTypography.titleMd),
                          ),
                          _AddRefuelButton(onTap: _goToRefuelManageCreate),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: RefuelsList(
                    refuels: refuels,
                    controller: _scrollController,
                    onRefuelTap: _goToRefuelManageEdit,
                    physics: const NeverScrollableScrollPhysics(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Collapsible header delegate
// ---------------------------------------------------------------------------

class _VehicleHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _VehicleHeaderDelegate({
    required this.vehicle,
    required this.fuelTypeLabel,
    required this.subtitle,
    required this.expandedHeight,
  });

  final VehicleEntity vehicle;
  final String fuelTypeLabel;
  final String subtitle;
  final double expandedHeight;

  static const double _collapsedHeight = 72.0;

  @override
  double get minExtent => _collapsedHeight;

  @override
  double get maxExtent => expandedHeight;

  @override
  bool shouldRebuild(covariant _VehicleHeaderDelegate old) =>
      vehicle != old.vehicle ||
      fuelTypeLabel != old.fuelTypeLabel ||
      subtitle != old.subtitle ||
      expandedHeight != old.expandedHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final t = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final expandedOpacity = (1.0 - t * 2.0).clamp(0.0, 1.0);
    final collapsedOpacity = ((t - 0.5) * 2.0).clamp(0.0, 1.0);

    return Material(
      color: AppColors.background,
      elevation: collapsedOpacity * 2,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Estado expandido ──────────────────────────────────────────
          Opacity(
            opacity: expandedOpacity,
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minHeight: maxExtent,
              maxHeight: maxExtent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeaderImage(imageUrl: vehicle.photoPath),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      spacing: AppSpacing.xs,
                      children: [
                        Text(vehicle.name, style: AppTypography.titleLg),
                        Text(
                          'Tipo de Combustível: $fuelTypeLabel',
                          style: AppTypography.textSmRegular,
                        ),
                        if (subtitle.isNotEmpty) Text(subtitle, style: AppTypography.textSmRegular),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Estado colapsado ──────────────────────────────────────────
          Opacity(
            opacity: collapsedOpacity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                spacing: AppSpacing.md,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppSpacing.radiusSm,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.directions_car_outlined,
                      size: 24,
                      color: AppColors.primary,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.name,
                          style: AppTypography.textMdBold,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            style: AppTypography.textSmRegular.copyWith(
                              color: AppColors.text.withValues(alpha: .65),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderImage extends StatefulWidget {
  const _HeaderImage({this.imageUrl});
  final String? imageUrl;

  @override
  State<_HeaderImage> createState() => _HeaderImageState();
}

class _HeaderImageState extends State<_HeaderImage> {
  bool _fileExists = false;

  @override
  void initState() {
    super.initState();
    _checkFileExists();
  }

  @override
  void didUpdateWidget(_HeaderImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _checkFileExists();
    }
  }

  Future<void> _checkFileExists() async {
    final url = widget.imageUrl;
    if (url == null || url.isEmpty) {
      if (mounted) setState(() => _fileExists = false);
      return;
    }
    final exists = await File(url).exists();
    if (mounted) setState(() => _fileExists = exists);
  }

  void _previewImage(BuildContext context) {
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
                  tag: '${widget.imageUrl}-vehicle',
                  child: Image.file(
                    File(widget.imageUrl!),
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

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.only(
      topLeft: AppSpacing.radiusMd.topLeft,
      topRight: AppSpacing.radiusMd.topRight,
    );

    return GestureDetector(
      onTap: _fileExists ? () => _previewImage(context) : null,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: radius,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _fileExists
                  ? Hero(
                      tag: '${widget.imageUrl}-vehicle',
                      child: Image.file(File(widget.imageUrl!), fit: BoxFit.cover),
                    )
                  : Container(
                      color: AppColors.surface,
                      alignment: Alignment.center,
                      child: const Icon(Icons.directions_car_filled_outlined, size: 64, color: AppColors.primary),
                    ),
            ),
          ),
          if (_fileExists)
            Positioned(
              top: 8,
              right: 8,
              child: CircleAvatar(
                backgroundColor: AppColors.surface,
                child: IconButton(
                  onPressed: () => _previewImage(context),
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

class _AddRefuelButton extends StatelessWidget {
  const _AddRefuelButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
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
        onTap: onTap,
        borderRadius: AppSpacing.radiusSm,
        child: Padding(
          padding: AppSpacing.paddingMd,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.sm,
            children: [
              const Icon(
                Icons.local_gas_station_rounded,
                color: AppColors.text,
                size: 24,
              ),
              Text('Novo', style: AppTypography.textMdBold.copyWith(color: AppColors.text)),
            ],
          ),
        ),
      ),
    );
  }
}
