import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gasosa_app/domain/entities/vehicle.dart';
import 'package:gasosa_app/presentation/screens/dashboard/widgets/show_delete_vehicle_confirm_dialog.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_card.dart';
import 'package:gasosa_app/theme/app_colors.dart';
import 'package:gasosa_app/theme/app_spacing.dart';
import 'package:gasosa_app/theme/app_typography.dart';

class VehicleCard extends StatelessWidget {
  const VehicleCard({
    super.key,
    required this.vehicle,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final VehicleEntity vehicle;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  String get _subtitle {
    final plate = (vehicle.plate ?? '').trim();
    final capacity = vehicle.tankCapacity;
    return [
      if (plate.isNotEmpty) plate.toUpperCase(),
      if (capacity != null) '${capacity.toStringAsFixed(0)} L',
    ].join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('vehicle_${vehicle.id}'),
      direction: onDelete != null ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: 24,
        ),
      ),
      confirmDismiss: (direction) => showDeleteVehicleConfirmDialog(
        context,
        vehicleName: vehicle.name,
      ),
      onDismissed: (direction) {
        onDelete?.call();
      },
      child: GasosaCard(
        onTap: onTap,
        child: Row(
          spacing: AppSpacing.md,
          children: [
            _VehicleThumbnail(vehicle.photoPath),
            AppSpacing.gap16,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.xs,
                children: [
                  Text(
                    vehicle.name,
                    style: AppTypography.textMdBold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_subtitle.isNotEmpty)
                    Text(
                      _subtitle,
                      style: AppTypography.textSmRegular.copyWith(color: AppColors.text.withValues(alpha: .6)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              tooltip: 'Ver detalhes',
              color: AppColors.text,
              onPressed: onTap,
            ),

            /// Action buttons
            // Row(
            //   children: [
            //     IconButton(
            //       icon: const Icon(Icons.edit_outlined),
            //       tooltip: 'Editar',
            //       color: AppColors.text,
            //       onPressed: onEdit?.call,
            //     ),
            //     IconButton(
            //       icon: const Icon(Icons.delete_outline),
            //       tooltip: 'Excluir',
            //       color: AppColors.text,
            //       onPressed: onDelete?.call,
            //     ),
            //     IconButton(
            //       icon: const Icon(Icons.chevron_right_rounded),
            //       tooltip: 'Ver detalhes',
            //       color: AppColors.text,
            //       onPressed: onTap,
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }
}

class _VehicleThumbnail extends StatefulWidget {
  const _VehicleThumbnail(this.photoUrl);

  final String? photoUrl;

  @override
  State<_VehicleThumbnail> createState() => _VehicleThumbnailState();
}

class _VehicleThumbnailState extends State<_VehicleThumbnail> {
  bool _fileExists = false;

  @override
  void initState() {
    super.initState();
    _checkFile(widget.photoUrl);
  }

  @override
  void didUpdateWidget(_VehicleThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoUrl != widget.photoUrl) {
      _checkFile(widget.photoUrl);
    }
  }

  Future<void> _checkFile(String? path) async {
    final exists = path != null && path.isNotEmpty && await File(path).exists();
    if (mounted) setState(() => _fileExists = exists);
  }

  @override
  Widget build(BuildContext context) {
    const double size = 48.0;
    final radius = BorderRadius.circular(24);

    if (_fileExists) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.file(
          File(widget.photoUrl!),
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: radius,
        border: Border.all(color: AppColors.border),
      ),
      child: const Icon(Icons.directions_car_filled_outlined, color: AppColors.primary),
    );
  }
}
