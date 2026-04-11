import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gasosa_app/core/app_strings.dart';
import 'package:gasosa_app/core/di/injection.dart';
import 'package:gasosa_app/core/presentation/ui_state.dart';
import 'package:gasosa_app/domain/entities/vehicle.dart';
import 'package:gasosa_app/domain/services/auth_service.dart';
import 'package:gasosa_app/presentation/routes/route_paths.dart';
import 'package:gasosa_app/presentation/screens/dashboard/viewmodel/dashboard_viewmodel.dart';
import 'package:gasosa_app/presentation/screens/dashboard/widgets/vehicle_list_card.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_appbar.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_avatar.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_confirm_dialog.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_empty_state_widget.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_error_state_widget.dart';
import 'package:gasosa_app/presentation/widgets/messages.dart';
import 'package:gasosa_app/theme/app_colors.dart';
import 'package:gasosa_app/theme/app_spacing.dart';
import 'package:gasosa_app/theme/app_typography.dart';
import 'package:go_router/go_router.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = getIt<DashboardViewModel>();
    _viewModel.init();
  }

  Future<void> _logout() async {
    final confirmed = await showGasosaConfirmDialog(
      context,
      title: DashboardStrings.logoutDialogTitle,
      content: DashboardStrings.logoutDialogContent,
      confirmLabel: DashboardStrings.logoutDialogConfirmLabel,
      danger: true,
    );
    if (!confirmed) return;
    await _viewModel.logout();
    if (mounted) {
      context.go(Routes.login);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showGasosaConfirmDialog(
      context,
      title: DashboardStrings.deleteAccountDialogTitle,
      content: DashboardStrings.deleteAccountDialogContent,
      confirmLabel: DashboardStrings.deleteAccountDialogConfirmLabel,
      danger: true,
    );
    if (!confirmed) return;

    final result = await _viewModel.deleteAccount();
    if (!mounted) return;

    result.fold(
      (failure) => Messages.showError(context, failure.message),
      (_) {
        Messages.showSuccess(context, DashboardStrings.deleteAccountSuccess);
        context.go(Routes.login);
      },
    );
  }

  Future<void> _goToCreateVehicle() async {
    await context.push(Routes.manageVehiclePath());
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthUser?>(
      valueListenable: _viewModel.currentUser,
      builder: (context, user, _) {
        return Scaffold(
          appBar: GasosaAppbar(
            title: DashboardStrings.greeting(user?.name),
            leading: GasosaAvatar(photoUrl: user?.photoUrl, size: 32),
            actions: [
              if (kDebugMode)
                IconButton(
                  onPressed: () => context.push(Routes.devRefuelPreview),
                  icon: const Icon(Icons.bug_report_outlined),
                  tooltip: '[DEV] Scroll Preview',
                ),
              IconButton(
                onPressed: () async => _logout(),
                icon: const Icon(Icons.logout),
                tooltip: DashboardStrings.logoutTooltip,
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                tooltip: 'Mais opções',
                onSelected: (value) {
                  if (value == 'delete_account') _deleteAccount();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'delete_account',
                    child: Row(
                      spacing: 8,
                      children: [
                        const Icon(Icons.delete_forever_outlined, color: AppColors.error),
                        Text(
                          DashboardStrings.deleteAccountMenuLabel,
                          style: AppTypography.textSmRegular.copyWith(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          floatingActionButton: ValueListenableBuilder<UiState<List<VehicleEntity>>>(
            valueListenable: _viewModel.watchVehicles.state,
            builder: (_, uiState, _) {
              final hasVehicles = uiState is UiData<List<VehicleEntity>> && uiState.data.isNotEmpty;
              return hasVehicles
                  ? FloatingActionButton.extended(
                      onPressed: _goToCreateVehicle,
                      icon: const Icon(Icons.directions_car_filled_rounded, color: AppColors.text),
                      label: Text(
                        DashboardStrings.addVehicleLabel,
                        style: AppTypography.textSmBold.copyWith(color: AppColors.text),
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),
          body: ValueListenableBuilder<UiState<List<VehicleEntity>>>(
            valueListenable: _viewModel.watchVehicles.state,
            builder: (_, uiState, _) {
              if (uiState is UiInitial || uiState is UiLoading) {
                return ColoredBox(
                  color: AppColors.background.withValues(alpha: 0.8),
                  child: Center(
                    child: LoadingAnimationWidget.waveDots(color: AppColors.primary, size: 48),
                  ),
                );
              }

              if (uiState is UiError<List<VehicleEntity>>) {
                return GasosaErrorStateWidget(
                  errorMessage: uiState.message,
                  onPressed: _viewModel.retry,
                );
              }

              final vehicles = (uiState as UiData<List<VehicleEntity>>).data;

              if (vehicles.isEmpty) {
                return GasosaEmptyStateWidget(
                  title: DashboardStrings.emptyStateTitle,
                  message: DashboardStrings.emptyStateMessage,
                  actionLabel: DashboardStrings.emptyStateAction,
                  onPressed: _goToCreateVehicle,
                );
              }

              return ListView.separated(
                padding: AppSpacing.paddingMd,
                itemCount: vehicles.length,
                separatorBuilder: (_, _) => AppSpacing.gap16,
                itemBuilder: (_, index) {
                  final vehicle = vehicles[index];
                  return VehicleCard(
                    vehicle: vehicle,
                    onTap: () => context.push(Routes.vehicleDetailPath(vehicle.id)),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
