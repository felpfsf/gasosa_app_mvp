import 'package:flutter/material.dart';
import 'package:gasosa_app/core/di/locator.dart';
import 'package:gasosa_app/core/viewmodel/loading_controller.dart';
import 'package:gasosa_app/theme/app_colors.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class GlobalLoaderOverlay extends StatelessWidget {
  const GlobalLoaderOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final controller = getIt<LoadingController>();
    return Stack(
      children: [
        child,
        AnimatedBuilder(
          animation: controller,
          builder: (_, __) {
            final visible = controller.isLoading;
            return IgnorePointer(
              ignoring: !visible,
              child: AnimatedOpacity(
                opacity: visible ? 1 : 0,
                duration: const Duration(milliseconds: 120),
                child: Stack(
                  children: [
                    Positioned.fill(child: ModalBarrier(color: AppColors.background.withValues(alpha: 0.8), dismissible: false)),
                    Center(
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: LoadingAnimationWidget.waveDots(color: AppColors.primary, size: 48),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
