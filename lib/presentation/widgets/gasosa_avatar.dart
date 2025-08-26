import 'package:flutter/material.dart';
import 'package:gasosa_app/theme/app_colors.dart';
import 'package:gasosa_app/theme/app_spacing.dart';

class GasosaAvatar extends StatelessWidget {
  const GasosaAvatar({super.key, this.photoUrl, this.size = 48});

  final String? photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.5)],
        ),
      ),
      child: Padding(
        padding: AppSpacing.paddingHorizontalLg,
        child: CircleAvatar(
          backgroundColor: AppColors.surface,
          backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
              ? NetworkImage(photoUrl!)
              : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
        ),
      ),
    );
  }
}
