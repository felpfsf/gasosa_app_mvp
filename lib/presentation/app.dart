import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gasosa_app/core/di/injection.dart';
import 'package:gasosa_app/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class GasosaApp extends StatelessWidget {
  const GasosaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Gasosa',
      theme: AppTheme.dark,
      routerConfig: getIt<GoRouter>(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
    );
  }
}
