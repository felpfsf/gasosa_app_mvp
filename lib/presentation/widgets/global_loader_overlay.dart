import 'package:flutter/material.dart';
import 'package:gasosa_app/core/di/locator.dart';
import 'package:gasosa_app/core/viewmodel/loading_controller.dart';
import 'package:gasosa_app/theme/app_colors.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class GlobalLoaderOverlay extends StatelessWidget {
  const GlobalLoaderOverlay({
    super.key,
    required this.controller,
    this.child,
  });

  final LoadingController controller;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final controller = getIt<LoadingController>();
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Stack(
          children: [
            if (child != null) child!,
            if (controller.visible)
              ColoredBox(
                color: AppColors.background.withValues(alpha: 0.8),
                child: Center(
                  child: LoadingAnimationWidget.waveDots(color: AppColors.primary, size: 48),
                ),
              ),
          ],
        );
      },
    );
  }
}
