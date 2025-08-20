import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gasosa_app/presentation/routes/route_paths.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            ElevatedButton(
              onPressed: () => context.go(RoutePaths.register),
              child: const Text('Ir para Cadastro'),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signInAnonymously();
                if (context.mounted) {
                  context.go(RoutePaths.dashboard);
                }
              },
              child: const Text('Entrar'),
            ),
          ],
        ),
      ),
    );
  }
}
