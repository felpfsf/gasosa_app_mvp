import 'package:flutter/material.dart';
import 'package:gasosa_app/core/extensions/date_time_extensions.dart';
import 'package:gasosa_app/domain/entities/fuel_type.dart';
import 'package:gasosa_app/domain/entities/refuel.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_card.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_empty_state_widget.dart';
import 'package:gasosa_app/theme/app_colors.dart';
import 'package:gasosa_app/theme/app_spacing.dart';
import 'package:gasosa_app/theme/app_typography.dart';

class RefuelsList extends StatelessWidget {
  const RefuelsList({super.key, required this.refuels, required this.controller});
  final List<RefuelEntity> refuels;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    if (refuels.isEmpty) {
      return const GasosaCard(
        child: GasosaEmptyStateWidget(
          title: 'Nenhum abastecimento',
          message: 'Quando você registrar um abastecimento, ele aparecerá aqui.',
          actionLabel: 'Adicionar',
        ),
      );
    }

    return ListView.separated(
      controller: controller,
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: AppSpacing.md + MediaQuery.of(context).viewPadding.bottom,
      ),
      separatorBuilder: (_, __) => AppSpacing.gap16,
      itemCount: refuels.length,
      shrinkWrap: true,
      itemBuilder: (_, index) {
        final refuel = refuels[index];
        final previousRefuel = index < refuels.length - 1 ? refuels[index + 1] : null;
        return _RefuelItem(
          key: ValueKey(refuel.id),
          refuel: refuel,
          previousRefuel: previousRefuel,
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
  });

  final RefuelEntity refuel;
  final RefuelEntity? previousRefuel;

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
              Text('Litros: ${refuel.liters.toStringAsFixed(2)} L', style: AppTypography.textSmRegular),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total: R\$ ${refuel.totalValue.toStringAsFixed(2)}', style: AppTypography.textSmRegular),
              Text('Valor/Litro: R\$ ${pricePerLiter.toStringAsFixed(3)}', style: AppTypography.textSmRegular),
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
                  Text('$distanceTraveled km', style: AppTypography.textSmRegular),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
