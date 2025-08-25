import 'package:flutter/material.dart';
import 'package:gasosa_app/theme/app_typography.dart';
import 'package:go_router/go_router.dart';

class GasosaAppbar extends StatelessWidget implements PreferredSizeWidget {
  const GasosaAppbar({
    super.key,
    required this.title,
    this.centerTitle = true,
    this.actions,
    this.leading,
    this.showBackButton = false,
    this.onBackPressed,
  });

  final String title;
  final bool centerTitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: AppTypography.textLgBold),
      centerTitle: centerTitle,
      leading: showBackButton
          ? leading ??
                BackButton(
                  onPressed:
                      onBackPressed ??
                      () {
                        if (context.canPop()) {
                          context.pop();
                        }
                      },
                )
          : null,
      actions: actions,
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
