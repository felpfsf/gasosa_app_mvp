import 'package:flutter/material.dart';
import 'package:gasosa_app/theme/app_colors.dart';
import 'package:gasosa_app/theme/app_spacing.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class GasosaLoader {
  static OverlayEntry? _entry;
  static int _refCount = 0;

  static void show(BuildContext context, {String message = 'Carregando...'}) {
    _refCount++;

    if (_entry != null) return;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _entry = OverlayEntry(builder: (_) => const _FullScreenSpinner());

    overlay.insert(_entry!);

    // return showDialog(
    //   context: context,
    //   builder: (_) {
    //     return PopScope(
    //       canPop: false,
    //       child: Dialog(
    //         child: Padding(
    //           padding: AppSpacing.paddingLg,
    //           child: Row(
    //             spacing: AppSpacing.md,
    //             children: [
    //               const CircularProgressIndicator(),
    //               Text(message),
    //             ],
    //           ),
    //         ),
    //       ),
    //     );
    //   },
    // );
  }

  static void hide() {
    if (_refCount > 0) {
      _refCount--;
    }
    if (_refCount == 0) {
      _entry?.remove();
      _entry = null;
    }
  }

  static void forceHide() {
    _refCount = 0;
    _entry?.remove();
    _entry = null;
  }
}

class _FullScreenSpinner extends StatelessWidget {
  const _FullScreenSpinner();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: ModalBarrier(color: AppColors.background.withValues(alpha: 0.8), dismissible: false)),
        Center(
          child: LoadingAnimationWidget.waveDots(color: AppColors.primary, size: 60),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _LoaderCard extends StatelessWidget {
  const _LoaderCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppSpacing.md),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.md,
          children: [
            const CircularProgressIndicator(strokeWidth: 2.5),
            Text(message),
          ],
        ),
      ),
    );
  }
}
