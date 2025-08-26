import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gasosa_app/core/di/locator.dart';
import 'package:gasosa_app/domain/services/auth_service.dart';
import 'package:gasosa_app/presentation/routes/route_paths.dart';
import 'package:gasosa_app/presentation/screens/dashboard/viewmodel/dashboard_viewmodel.dart';
import 'package:gasosa_app/presentation/screens/dashboard/widgets/vehicle_list_card.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_appbar.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_avatar.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_empty_state_widget.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_error_state_widget.dart';
import 'package:gasosa_app/theme/app_colors.dart';
import 'package:gasosa_app/theme/app_spacing.dart';
import 'package:gasosa_app/theme/app_typography.dart';
import 'package:go_router/go_router.dart';

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
    await getIt<AuthService>().logout();
    if (mounted) {
      context.go(RoutePaths.login);
    }
  }

  void _goToCreateVehicle() {
    // context.push(RoutePaths.addVehicle);
  }
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName;
    return Scaffold(
      appBar: GasosaAppbar(
        title: 'Bem vindo $name',
        leading: GestureDetector(
          onTap: () => {},
          child: GasosaAvatar(photoUrl: user?.photoURL, size: 32),
        ),
        actions: [
          IconButton(
            onPressed: () async => _logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToCreateVehicle,
        icon: const Icon(Icons.directions_car_filled_rounded, color: AppColors.text),
        label: Text(
          'Adicionar veículo',
          style: AppTypography.textSmBold.copyWith(color: AppColors.text),
        ),
      ),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (_, __) {
          final state = _viewModel.state;

          if (state.vehicles.isEmpty) {
            return GasosaEmptyStateWidget(
              title: 'Nenhum veículo cadastrado',
              message: 'Cadastre seu primeiro veículo para começar a usar o app.',
              actionLabel: 'Cadastrar veículo',
              onPressed: _goToCreateVehicle,
            );
          }

          if (state.errorMessage != null) {
            return GasosaErrorStateWidget(
              errorMessage: state.errorMessage!,
              onPressed: _viewModel.retry,
            );
          }

          return ListView.separated(
            padding: AppSpacing.paddingMd,
            itemCount: state.vehicles.length,
            separatorBuilder: (_, __) => AppSpacing.gap16,
            itemBuilder: (_, index) {
              final vehicle = state.vehicles[index];
              return VehicleCard(
                vehicle: vehicle,
                onTap: () => {},
                onEdit: () => {},
                onDelete: () async {},
                enableSwipe: true,
              );
            },
          );
        },
      ),
    );
  }
}
