import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gasosa_app/core/di/locator.dart';
import 'package:gasosa_app/core/viewmodel/loading_controller.dart';
import 'package:gasosa_app/presentation/routes/app_router.dart';
import 'package:gasosa_app/presentation/widgets/global_loader_overlay.dart';
import 'package:gasosa_app/theme/app_theme.dart';

class GasosaApp extends StatelessWidget {
  const GasosaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final loading = getIt<LoadingController>();
    return MaterialApp.router(
      title: 'Gasosa',
      theme: AppTheme.dark,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      builder: (context, child) => GlobalLoaderOverlay(
        controller: loading,
        child: child,
      ),
    );
  }
}
