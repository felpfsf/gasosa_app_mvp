import 'package:flutter/material.dart';
import 'package:gasosa_app/core/app_strings.dart';
import 'package:gasosa_app/core/extensions/date_time_extensions.dart';
import 'package:gasosa_app/core/helpers/numeric_parser.dart';
import 'package:gasosa_app/domain/entities/fuel_type.dart';
import 'package:gasosa_app/domain/entities/refuel.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_card.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_empty_state_widget.dart';
import 'package:gasosa_app/theme/app_colors.dart';
import 'package:gasosa_app/theme/app_spacing.dart';
import 'package:gasosa_app/theme/app_typography.dart';

class RefuelsList extends StatelessWidget {
  const RefuelsList({
    super.key,
    required this.refuels,
    required this.controller,
    this.onRefuelTap,
    this.physics,
  });
  final List<RefuelEntity> refuels;
  final ScrollController controller;
  final Future<void> Function(String refuelId)? onRefuelTap;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    if (refuels.isEmpty) {
      return const GasosaCard(
        child: GasosaEmptyStateWidget(
          title: RefuelStrings.emptyStateTitle,
          message: RefuelStrings.emptyStateMessage,
          actionLabel: RefuelStrings.emptyStateAction,
        ),
      );
    }

    return ListView.separated(
      controller: controller,
      physics: physics,
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: AppSpacing.md + MediaQuery.of(context).viewPadding.bottom,
      ),
      separatorBuilder: (_, _) => AppSpacing.gap16,
      itemCount: refuels.length,
      shrinkWrap: true,
      itemBuilder: (_, index) {
        final refuel = refuels[index];
        final previousRefuel = index < refuels.length - 1 ? refuels[index + 1] : null;
        return _RefuelItem(
          key: ValueKey(refuel.id),
          refuel: refuel,
          previousRefuel: previousRefuel,
          onTap: onRefuelTap != null ? () => onRefuelTap!(refuel.id) : null,
        );
      },
    );
  }
}

class _RefuelItem extends StatelessWidget {
  const _RefuelItem({
    super.key,
    required this.refuel,
    this.previousRefuel,
    this.onTap,
  });

  final RefuelEntity refuel;
  final RefuelEntity? previousRefuel;
  final VoidCallback? onTap;

  double get pricePerLiter => refuel.totalValue / refuel.liters;

  int? get distanceTraveled {
    if (previousRefuel == null) return null;

    return refuel.mileage - previousRefuel!.mileage;
  }

  double? get consumption {
    final distance = distanceTraveled;
    if (distance == null || distance <= 0) return null;

    return distance / refuel.liters;
  }

  @override
  Widget build(BuildContext context) {
    return GasosaCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.sm,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(refuel.refuelDate.formattedFullDate(), style: AppTypography.textSmBold),
              Row(
                spacing: AppSpacing.xs,
                children: [
                  const Icon(Icons.local_gas_station_rounded),
                  Text(refuel.fuelType.displayName, style: AppTypography.textMdBold),
                ],
              ),
            ],
          ),
          const Divider(thickness: 1, color: AppColors.border),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: AppSpacing.sm,
            children: [
              Text('KM: ${refuel.mileage.toStringAsFixed(0)}', style: AppTypography.textSmRegular),
              Text('Litros: ${NumericParser.formatDouble(refuel.liters)} L', style: AppTypography.textSmRegular),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total: R\$ ${NumericParser.formatDouble(refuel.totalValue)}', style: AppTypography.textSmRegular),
              Text(
                'Valor/Litro: R\$ ${NumericParser.formatDouble(pricePerLiter, decimalPlaces: 3)}',
                style: AppTypography.textSmRegular,
              ),
            ],
          ),

          if (consumption != null || distanceTraveled != null) ...[
            Row(
              spacing: AppSpacing.sm,
              children: [
                if (consumption != null) ...[
                  const Icon(Icons.speed_rounded),
                  Text(
                    'Consumo: ${consumption!.toStringAsFixed(1)} km/l',
                    style: AppTypography.textSmMedium,
                  ),
                ],
                const Spacer(),
                if (distanceTraveled != null) ...[
                  const Icon(Icons.route_rounded),
                  // TODO(felipe): Change to Expanded after fixing overflow issue
                  Expanded(child: Text('$distanceTraveled km', style: AppTypography.textSmRegular)),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
