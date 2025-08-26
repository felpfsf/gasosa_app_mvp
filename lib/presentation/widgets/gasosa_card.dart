import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:gasosa_app/theme/app_colors.dart';
import 'package:gasosa_app/theme/app_spacing.dart';

class GasosaCard extends StatelessWidget {
  const GasosaCard({
    super.key,
    this.child,
    this.color,
    this.padding,
    this.margin,
    this.onTap,
    this.enableSwipeActions = false,
    this.swipeActions,
  });

  final Widget? child;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool enableSwipeActions;
  final List<Widget>? swipeActions;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding ?? AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: AppSpacing.radiusMd,
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );

    final tappable = onTap != null
        ? InkWell(
            onTap: onTap,
            borderRadius: AppSpacing.radiusMd,
            child: content,
          )
        : content;

    if (enableSwipeActions && swipeActions != null) {
      return Slidable(
        endActionPane: ActionPane(motion: const DrawerMotion(), children: swipeActions!),
        child: tappable,
      );
    }
    return tappable;
  }
}
