import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gasosa_app/core/di/locator.dart';
import 'package:gasosa_app/domain/services/auth_service.dart';
import 'package:gasosa_app/presentation/routes/route_paths.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await getIt<AuthService>().logout();
              if (context.mounted) {
                context.go(RoutePaths.login);
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            Text('Welcome, $email!'),
            const Text('Dashboard Item 1'),
            const Text('Dashboard Item 2'),
            const Text('Dashboard Item 3'),
          ],
        ),
      ),
    );
  }
}
