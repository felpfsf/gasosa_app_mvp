import 'package:flutter/material.dart';
import 'package:gasosa_app/theme/app_colors.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

sealed class Messages {
  static const _kDisplay = Duration(milliseconds: 1200);
  static const _kAnimation = Duration(milliseconds: 400);

  static void _show(
    BuildContext context,
    Widget snack, {
    Duration display = _kDisplay,
    Duration animation = _kAnimation,
    DismissType dismissType = DismissType.onSwipe,
    List<DismissDirection> dismissDirection = const [DismissDirection.startToEnd, DismissDirection.endToStart],
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      return;
    }

    showTopSnackBar(
      overlay,
      snack,
      displayDuration: display,
      animationDuration: animation,
      dismissType: dismissType,
      dismissDirection: dismissDirection,
    );
  }

  static void showError(BuildContext context, String message) {
    _show(context, CustomSnackBar.error(message: message));
  }

  static void showSuccess(BuildContext context, String message) {
    _show(context, CustomSnackBar.success(message: message));
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, CustomSnackBar.info(message: message));
  }

  static void showWarning(BuildContext context, String message) {
    _show(
      context,
      CustomSnackBar.info(
        message: message,
        backgroundColor: AppColors.warning,
        textStyle: const TextStyle(color: Color(0xFF8A6D3B), fontWeight: FontWeight.w600),
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: Color(0xFF8A6D3B),
          size: 120,
        ),
      ),
    );
  }
}
