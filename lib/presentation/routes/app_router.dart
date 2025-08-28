import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gasosa_app/presentation/routes/auth_refresh_notifier.dart';
import 'package:gasosa_app/presentation/routes/route_paths.dart';
import 'package:gasosa_app/presentation/screens/auth/login_screen.dart';
import 'package:gasosa_app/presentation/screens/auth/register_screen.dart';
import 'package:gasosa_app/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:gasosa_app/presentation/screens/splash/splash_screen.dart';
import 'package:gasosa_app/presentation/screens/vehicle/manage_vehicle_screen.dart';
import 'package:gasosa_app/presentation/screens/vehicle/vehicle_detail_screen.dart';
import 'package:go_router/go_router.dart';

String? _authGuard(BuildContext context, GoRouterState state) {
  final isAuthenticated = FirebaseAuth.instance.currentUser != null;
  final loc = state.matchedLocation;

  const publicRoutes = {
    RoutePaths.splash,
    RoutePaths.login,
    RoutePaths.register,
  };

  // if (!isAuthenticated && loc == RoutePaths.splash) {
  //   return RoutePaths.login;
  // }

  if (loc == RoutePaths.splash) {
    return null;
  }

  if (!isAuthenticated && !publicRoutes.contains(loc)) {
    return RoutePaths.login;
  }

  if (isAuthenticated && (publicRoutes.contains(loc))) {
    return RoutePaths.dashboard;
  }

  return null;
}

final GoRouter appRouter = GoRouter(
  initialLocation: RoutePaths.splash,
  refreshListenable: AuthRefreshNotifier(),
  redirect: _authGuard,
  routes: [
    GoRoute(
      path: RoutePaths.splash,
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: RoutePaths.login,
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: RoutePaths.register,
      builder: (_, __) => const RegisterScreen(),
    ),
    GoRoute(
      path: RoutePaths.dashboard,
      builder: (_, __) => const DashboardScreen(),
    ),
    GoRoute(
      path: RoutePaths.vehicleManageCreate,
      builder: (_, __) => const ManageVehicleScreen(),
    ),
    GoRoute(
      path: RoutePaths.vehicleManageEdit(':id'),
      builder: (context, state) => ManageVehicleScreen(vehicleId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: RoutePaths.vehicleDetail(':id'),
      builder: (context, state) => VehicleDetailScreen(vehicleId: state.pathParameters['id']!),
    ),
  ],
);
