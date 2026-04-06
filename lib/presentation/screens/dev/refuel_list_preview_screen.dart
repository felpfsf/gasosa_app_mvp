import 'package:flutter/material.dart';
import 'package:gasosa_app/core/app_strings.dart';
import 'package:gasosa_app/domain/entities/fuel_type.dart';
import 'package:gasosa_app/domain/entities/refuel.dart';
import 'package:gasosa_app/domain/entities/vehicle.dart';
import 'package:gasosa_app/presentation/screens/vehicle/widgets/refuel_list.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_appbar.dart';
import 'package:gasosa_app/theme/app_colors.dart';
import 'package:gasosa_app/theme/app_spacing.dart';
import 'package:gasosa_app/theme/app_typography.dart';
import 'package:go_router/go_router.dart';

// ---------------------------------------------------------------------------
// Mock data
// ---------------------------------------------------------------------------

final _mockVehicle = VehicleEntity(
  id: 'mock-vehicle',
  userId: 'mock-user',
  name: 'Gol 1.0',
  fuelType: FuelType.gasoline,
  plate: 'ABC1D23',
  tankCapacity: 50,
  createdAt: DateTime(2025, 1, 10),
);

// Dados ordenados do mais recente ao mais antigo (como a lista exibe).
// Consumo calculado: distanceTraveled = km[n] - km[n+1],  consumo = dist / liters[n]
// Preço/litro = totalValue / liters
//
// Abastecimento | km rodados | liters  | R$/L  | consumo
// r-01          | 500 km     | 41,20 L | 6,20  | 12,14 km/L
// r-02          | 530 km     | 43,50 L | 6,12  | 12,18 km/L
// r-03          | 480 km     | 39,80 L | 6,25  | 12,06 km/L
// r-04          | 540 km     | 44,00 L | 6,28  | 12,27 km/L
// r-05          | 490 km     | 40,50 L | 6,18  | 12,10 km/L
// r-06          | 510 km     | 42,00 L | 6,30  | 12,14 km/L  (+ partida a frio)
// r-07          | 460 km     | 38,50 L | 6,15  | 11,95 km/L
// r-08          | 550 km     | 44,80 L | 5,98  | 12,28 km/L
// r-09          | 500 km     | 41,50 L | 5,95  | 12,05 km/L
// r-10          | 530 km     | 43,20 L | 5,92  | 12,27 km/L
// r-11          | 480 km     | 39,50 L | 5,90  | 12,15 km/L
// r-12          | —          | 37,80 L | 5,89  | —  (sem abastecimento anterior)
final _mockRefuels = [
  RefuelEntity(
    id: 'r-01',
    vehicleId: 'mock-vehicle',
    refuelDate: DateTime(2026, 4, 2),
    fuelType: FuelType.gasoline,
    mileage: 45510,
    liters: 41.2,
    totalValue: 255.44, // 41,20 × 6,20
    createdAt: DateTime(2026, 4, 2),
  ),
  RefuelEntity(
    id: 'r-02',
    vehicleId: 'mock-vehicle',
    refuelDate: DateTime(2026, 3, 18),
    fuelType: FuelType.gasoline,
    mileage: 45010,
    liters: 43.5,
    totalValue: 266.22, // 43,50 × 6,12
    createdAt: DateTime(2026, 3, 18),
  ),
  RefuelEntity(
    id: 'r-03',
    vehicleId: 'mock-vehicle',
    refuelDate: DateTime(2026, 3, 4),
    fuelType: FuelType.gasoline,
    mileage: 44480,
    liters: 39.8,
    totalValue: 248.75, // 39,80 × 6,25
    createdAt: DateTime(2026, 3, 4),
  ),
  RefuelEntity(
    id: 'r-04',
    vehicleId: 'mock-vehicle',
    refuelDate: DateTime(2026, 2, 18),
    fuelType: FuelType.gasoline,
    mileage: 44000,
    liters: 44.0,
    totalValue: 276.32, // 44,00 × 6,28
    createdAt: DateTime(2026, 2, 18),
  ),
  RefuelEntity(
    id: 'r-05',
    vehicleId: 'mock-vehicle',
    refuelDate: DateTime(2026, 2, 4),
    fuelType: FuelType.gasoline,
    mileage: 43460,
    liters: 40.5,
    totalValue: 250.29, // 40,50 × 6,18
    createdAt: DateTime(2026, 2, 4),
  ),
  RefuelEntity(
    id: 'r-06',
    vehicleId: 'mock-vehicle',
    refuelDate: DateTime(2026, 1, 21),
    fuelType: FuelType.gasoline,
    mileage: 42970,
    liters: 42.0,
    totalValue: 264.60, // 42,00 × 6,30
    coldStartLiters: 1.8,
    coldStartValue: 11.34, // 1,80 × 6,30
    createdAt: DateTime(2026, 1, 21),
  ),
  RefuelEntity(
    id: 'r-07',
    vehicleId: 'mock-vehicle',
    refuelDate: DateTime(2026, 1, 7),
    fuelType: FuelType.gasoline,
    mileage: 42460,
    liters: 38.5,
    totalValue: 236.78, // 38,50 × 6,15
    createdAt: DateTime(2026, 1, 7),
  ),
  RefuelEntity(
    id: 'r-08',
    vehicleId: 'mock-vehicle',
    refuelDate: DateTime(2025, 12, 23),
    fuelType: FuelType.gasoline,
    mileage: 42000,
    liters: 44.8,
    totalValue: 267.90, // 44,80 × 5,98
    createdAt: DateTime(2025, 12, 23),
  ),
  RefuelEntity(
    id: 'r-09',
    vehicleId: 'mock-vehicle',
    refuelDate: DateTime(2025, 12, 8),
    fuelType: FuelType.gasoline,
    mileage: 41450,
    liters: 41.5,
    totalValue: 246.93, // 41,50 × 5,95
    createdAt: DateTime(2025, 12, 8),
  ),
  RefuelEntity(
    id: 'r-10',
    vehicleId: 'mock-vehicle',
    refuelDate: DateTime(2025, 11, 24),
    fuelType: FuelType.gasoline,
    mileage: 40950,
    liters: 43.2,
    totalValue: 255.74, // 43,20 × 5,92
    createdAt: DateTime(2025, 11, 24),
  ),
  RefuelEntity(
    id: 'r-11',
    vehicleId: 'mock-vehicle',
    refuelDate: DateTime(2025, 11, 9),
    fuelType: FuelType.gasoline,
    mileage: 40420,
    liters: 39.5,
    totalValue: 233.05, // 39,50 × 5,90
    createdAt: DateTime(2025, 11, 9),
  ),
  RefuelEntity(
    id: 'r-12',
    vehicleId: 'mock-vehicle',
    refuelDate: DateTime(2025, 10, 26),
    fuelType: FuelType.gasoline,
    mileage: 39940,
    liters: 37.8,
    totalValue: 222.64, // 37,80 × 5,89
    createdAt: DateTime(2025, 10, 26),
  ),
];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class RefuelListPreviewScreen extends StatefulWidget {
  const RefuelListPreviewScreen({super.key});

  @override
  State<RefuelListPreviewScreen> createState() => _RefuelListPreviewScreenState();
}

class _RefuelListPreviewScreenState extends State<RefuelListPreviewScreen> {
  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final imageHeight = MediaQuery.of(context).size.width * (9.0 / 16.0);
    final expandedHeight = imageHeight + 132.0;

    return Scaffold(
      appBar: GasosaAppbar(
        title: '[DEV] ${VehicleStrings.appBarTitleDetail}',
        showBackButton: true,
        onBackPressed: () => context.pop(),
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _VehicleHeaderDelegate(
              vehicle: _mockVehicle,
              expandedHeight: expandedHeight,
            ),
          ),
          SliverPadding(
            padding: AppSpacing.paddingHorizontalMd,
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(VehicleStrings.refuelsSectionTitle, style: AppTypography.titleMd),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: RefuelsList(
              refuels: _mockRefuels,
              controller: _scrollController,
              physics: const NeverScrollableScrollPhysics(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Collapsible header delegate
// ---------------------------------------------------------------------------

class _VehicleHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _VehicleHeaderDelegate({
    required this.vehicle,
    required this.expandedHeight,
  });

  final VehicleEntity vehicle;
  final double expandedHeight;

  static const double _collapsedHeight = 72.0;

  @override
  double get minExtent => _collapsedHeight;

  @override
  double get maxExtent => expandedHeight;

  @override
  bool shouldRebuild(covariant _VehicleHeaderDelegate old) =>
      vehicle != old.vehicle || expandedHeight != old.expandedHeight;

  String get _subtitle {
    final plate = (vehicle.plate ?? '').trim().toUpperCase();
    final tank = vehicle.tankCapacity?.toStringAsFixed(0);
    return [
      if (plate.isNotEmpty) plate,
      if (tank != null) 'Tanque: $tank L',
    ].join(' • ');
  }

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final t = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final expandedOpacity = (1.0 - t * 2.0).clamp(0.0, 1.0);
    final collapsedOpacity = ((t - 0.5) * 2.0).clamp(0.0, 1.0);

    return Material(
      color: AppColors.background,
      elevation: collapsedOpacity * 2,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Estado expandido ──────────────────────────────────────────
          // OverflowBox garante que a Column sempre recebe maxExtent de
          // altura, independente do shrinkOffset atual. O Stack (hardEdge)
          // clipará o que exceder a altura visível.
          Opacity(
            opacity: expandedOpacity,
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minHeight: maxExtent,
              maxHeight: maxExtent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      color: AppColors.surface,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.directions_car_filled_outlined,
                        size: 64,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      spacing: AppSpacing.xs,
                      children: [
                        Text(vehicle.name, style: AppTypography.titleLg),
                        Text(
                          'Tipo de Combustível: ${vehicle.fuelType.displayName}',
                          style: AppTypography.textSmRegular,
                        ),
                        if (_subtitle.isNotEmpty) Text(_subtitle, style: AppTypography.textSmRegular),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Estado colapsado ──────────────────────────────────────────
          Opacity(
            opacity: collapsedOpacity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                spacing: AppSpacing.md,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppSpacing.radiusSm,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.directions_car_outlined,
                      size: 24,
                      color: AppColors.primary,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                            style: AppTypography.textSmRegular.copyWith(
                              color: AppColors.text.withValues(alpha: .65),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
