import 'package:flutter/material.dart';
import 'package:gasosa_app/presentation/routes/app_router.dart';
import 'package:gasosa_app/theme/app_theme.dart';

class GasosaApp extends StatelessWidget {
  const GasosaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Gasosa',
      theme: AppTheme.dark,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
