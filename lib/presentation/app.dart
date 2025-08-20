import 'package:flutter/material.dart';
import 'package:gasosa_app/presentation/routes/app_router.dart';

class GasosaApp extends StatelessWidget {
  const GasosaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Gasosa',
      theme: _buildTheme(),
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }

  ThemeData _buildTheme() {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C5CE7)),
      useMaterial3: true,
    );

    return base.copyWith(
      appBarTheme: base.appBarTheme.copyWith(centerTitle: true),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
