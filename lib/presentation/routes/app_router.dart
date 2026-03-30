import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gasosa_app/core/app_strings.dart';
import 'package:gasosa_app/presentation/routes/auth_refresh_notifier.dart';
import 'package:gasosa_app/presentation/routes/route_paths.dart';
import 'package:gasosa_app/presentation/screens/auth/login_screen.dart';
import 'package:gasosa_app/presentation/screens/auth/register_screen.dart';
import 'package:gasosa_app/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:gasosa_app/presentation/screens/refuel/manage_refuel_screen.dart';
import 'package:gasosa_app/presentation/screens/splash/splash_screen.dart';
import 'package:gasosa_app/presentation/screens/vehicle/manage_vehicle_screen.dart';
import 'package:gasosa_app/presentation/screens/vehicle/vehicle_detail_screen.dart';
import 'package:gasosa_app/theme/app_colors.dart';
import 'package:gasosa_app/theme/app_spacing.dart';
import 'package:gasosa_app/theme/app_typography.dart';
import 'package:go_router/go_router.dart';

String? _authGuard(BuildContext context, GoRouterState state) {
  final isAuthenticated = FirebaseAuth.instance.currentUser != null;
  final loc = state.matchedLocation;

  const publicRoutes = {
    Routes.splash,
    Routes.login,
    Routes.register,
  };

  if (loc == Routes.splash) {
    return null;
  }

  if (!isAuthenticated && !publicRoutes.contains(loc)) {
    return Routes.login;
  }

  if (isAuthenticated && publicRoutes.contains(loc)) {
    return Routes.dashboard;
  }

  return null;
}

final GoRouter appRouter = GoRouter(
  initialLocation: Routes.splash,
  refreshListenable: AuthRefreshNotifier(),
  redirect: _authGuard,
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.md,
        children: [
          const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
          Text(AppErrorStrings.pageNotFound, style: AppTypography.titleLg),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go(Routes.dashboard),
            child: const Text(AppErrorStrings.goToDashboard),
          ),
        ],
      ),
    ),
  ),
  routes: [
    GoRoute(
      path: Routes.splash,
      builder: (_, _) => const SplashScreen(),
    ),
    GoRoute(
      path: Routes.login,
      builder: (_, _) => const LoginScreen(),
    ),
    GoRoute(
      path: Routes.register,
      builder: (_, _) => const RegisterScreen(),
    ),
    GoRoute(
      path: Routes.dashboard,
      builder: (_, _) => const DashboardScreen(),
    ),
    GoRoute(
      path: Routes.vehicle,
      redirect: (_, state) => state.uri.path == Routes.vehicle ? Routes.dashboard : null,
      routes: [
        GoRoute(
          path: Routes.manageVehicle,
          builder: (context, state) {
            final id = state.uri.queryParameters['id'];
            return ManageVehicleScreen(vehicleId: id);
          },
        ),
        GoRoute(
          path: Routes.vehicleDetail,
          builder: (context, state) {
            final id = state.uri.queryParameters['id']!;
            return VehicleDetailScreen(vehicleId: id);
          },
        ),
      ],
    ),
    GoRoute(
      path: Routes.refuel,
      redirect: (_, state) => state.uri.path == Routes.refuel ? Routes.dashboard : null,
      routes: [
        GoRoute(
          path: Routes.manageRefuel,
          builder: (context, state) {
            final id = state.uri.queryParameters['id'];
            final vehicleId = state.uri.queryParameters['vehicleId'];
            return ManageRefuelScreen(refuelId: id, vehicleId: vehicleId);
          },
        ),
      ],
    ),
  ],
);
