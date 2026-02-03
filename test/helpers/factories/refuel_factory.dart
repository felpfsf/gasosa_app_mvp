import 'package:faker/faker.dart';
import 'package:gasosa_app/domain/entities/fuel_type.dart';
import 'package:gasosa_app/domain/entities/refuel.dart';

/// Factory para criar RefuelEntity fake nos testes
class RefuelFactory {
  static final _faker = Faker();

  /// Cria um RefuelEntity com valores fake ou customizados
  static RefuelEntity create({
    String? id,
    String? vehicleId,
    DateTime? refuelDate,
    FuelType? fuelType,
    double? totalValue,
    int? mileage,
    double? liters,
    double? coldStartLiters,
    double? coldStartValue,
    String? receiptPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RefuelEntity(
      id: id ?? _faker.guid.guid(),
      vehicleId: vehicleId ?? _faker.guid.guid(),
      refuelDate: refuelDate ?? DateTime.now(),
      fuelType: fuelType ?? FuelType.gasoline,
      totalValue: totalValue ?? _faker.randomGenerator.decimal(scale: 300.0, min: 50.0),
      mileage: mileage ?? _faker.randomGenerator.integer(100000, min: 1000),
      liters: liters ?? _faker.randomGenerator.decimal(scale: 60.0, min: 10.0),
      coldStartLiters: coldStartLiters,
      coldStartValue: coldStartValue,
      receiptPath: receiptPath,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt,
    );
  }

  /// Cria um RefuelEntity completo com todos os campos opcionais
  static RefuelEntity createFull({
    String? id,
    String? vehicleId,
    DateTime? refuelDate,
    FuelType? fuelType,
    double? totalValue,
    int? mileage,
    double? liters,
    double? coldStartLiters,
    double? coldStartValue,
    String? receiptPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final baseValue = totalValue ?? _faker.randomGenerator.decimal(scale: 300.0, min: 50.0);
    final baseLiters = liters ?? _faker.randomGenerator.decimal(scale: 60.0, min: 10.0);

    return RefuelEntity(
      id: id ?? _faker.guid.guid(),
      vehicleId: vehicleId ?? _faker.guid.guid(),
      refuelDate: refuelDate ?? DateTime.now(),
      fuelType: fuelType ?? FuelType.values[_faker.randomGenerator.integer(FuelType.values.length)],
      totalValue: baseValue,
      mileage: mileage ?? _faker.randomGenerator.integer(100000, min: 1000),
      liters: baseLiters,
      coldStartLiters: coldStartLiters ?? _faker.randomGenerator.decimal(scale: 5.0, min: 0.5),
      coldStartValue: coldStartValue ?? _faker.randomGenerator.decimal(scale: 30.0, min: 5.0),
      receiptPath: receiptPath ?? '/receipts/${_faker.guid.guid()}.jpg',
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Cria um RefuelEntity sem cold start
  static RefuelEntity createWithoutColdStart({
    String? id,
    String? vehicleId,
    DateTime? refuelDate,
    FuelType? fuelType,
    double? totalValue,
    int? mileage,
    double? liters,
    String? receiptPath,
    DateTime? createdAt,
  }) {
    return RefuelEntity(
      id: id ?? _faker.guid.guid(),
      vehicleId: vehicleId ?? _faker.guid.guid(),
      refuelDate: refuelDate ?? DateTime.now(),
      fuelType: fuelType ?? FuelType.gasoline,
      totalValue: totalValue ?? _faker.randomGenerator.decimal(scale: 300.0, min: 50.0),
      mileage: mileage ?? _faker.randomGenerator.integer(100000, min: 1000),
      liters: liters ?? _faker.randomGenerator.decimal(scale: 60.0, min: 10.0),
      receiptPath: receiptPath,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  /// Cria um RefuelEntity válido para testes específicos
  static RefuelEntity createValid({
    String id = 'refuel-123',
    String vehicleId = 'vehicle-456',
    DateTime? refuelDate,
    FuelType fuelType = FuelType.gasoline,
    double totalValue = 250.50,
    int mileage = 50000,
    double liters = 45.5,
  }) {
    return RefuelEntity(
      id: id,
      vehicleId: vehicleId,
      refuelDate: refuelDate ?? DateTime(2026, 1, 15),
      fuelType: fuelType,
      totalValue: totalValue,
      mileage: mileage,
      liters: liters,
      createdAt: DateTime(2026, 1, 15),
    );
  }

  /// Cria um RefuelEntity para criação (id vazio)
  static RefuelEntity createNew({
    String? vehicleId,
    DateTime? refuelDate,
    FuelType? fuelType,
    double? totalValue,
    int? mileage,
    double? liters,
  }) {
    return RefuelEntity(
      id: '',
      vehicleId: vehicleId ?? _faker.guid.guid(),
      refuelDate: refuelDate ?? DateTime.now(),
      fuelType: fuelType ?? FuelType.gasoline,
      totalValue: totalValue ?? _faker.randomGenerator.decimal(scale: 300.0, min: 50.0),
      mileage: mileage ?? _faker.randomGenerator.integer(100000, min: 1000),
      liters: liters ?? _faker.randomGenerator.decimal(scale: 60.0, min: 10.0),
      createdAt: DateTime.now(),
    );
  }

  /// Cria uma lista de RefuelEntity ordenados por data (mais recente primeiro)
  static List<RefuelEntity> createList(
    int count, {
    String? vehicleId,
    int? startMileage,
  }) {
    final fixedVehicleId = vehicleId ?? _faker.guid.guid();
    var currentMileage = startMileage ?? 50000;

    return List.generate(count, (index) {
      final refuel = create(
        vehicleId: fixedVehicleId,
        mileage: currentMileage,
        refuelDate: DateTime.now().subtract(Duration(days: index * 7)),
      );
      currentMileage += _faker.randomGenerator.integer(500, min: 100);
      return refuel;
    }).reversed.toList(); // Mais antigos primeiro
  }

  /// Cria uma sequência de abastecimentos para teste de consumo
  /// Retorna lista ordenada cronologicamente (mais antigo primeiro)
  static List<RefuelEntity> createSequenceForConsumption({
    required String vehicleId,
    required int count,
    int startMileage = 50000,
    double avgConsumption = 12.0, // km/l
  }) {
    final refuels = <RefuelEntity>[];
    var currentMileage = startMileage;
    var currentDate = DateTime(2026, 1, 1);

    for (var i = 0; i < count; i++) {
      final liters = _faker.randomGenerator.decimal(scale: 50.0, min: 30.0);
      final kmDriven = (liters * avgConsumption).round();

      refuels.add(
        RefuelEntity(
          id: 'refuel-$i',
          vehicleId: vehicleId,
          refuelDate: currentDate,
          fuelType: FuelType.gasoline,
          totalValue: liters * 5.5, // R$ 5.50 por litro
          mileage: currentMileage,
          liters: liters,
          createdAt: currentDate,
        ),
      );

      currentMileage += kmDriven;
      currentDate = currentDate.add(const Duration(days: 7));
    }

    return refuels;
  }

  /// Cria dois abastecimentos consecutivos para teste de cálculo
  static List<RefuelEntity> createConsecutivePair({
    String? vehicleId,
    int mileage1 = 50000,
    int mileage2 = 50500,
    double liters1 = 40.0,
    double liters2 = 40.0,
  }) {
    final fixedVehicleId = vehicleId ?? _faker.guid.guid();

    return [
      RefuelEntity(
        id: 'refuel-1',
        vehicleId: fixedVehicleId,
        refuelDate: DateTime(2026, 1, 1),
        fuelType: FuelType.gasoline,
        totalValue: liters1 * 5.5,
        mileage: mileage1,
        liters: liters1,
        createdAt: DateTime(2026, 1, 1),
      ),
      RefuelEntity(
        id: 'refuel-2',
        vehicleId: fixedVehicleId,
        refuelDate: DateTime(2026, 1, 8),
        fuelType: FuelType.gasoline,
        totalValue: liters2 * 5.5,
        mileage: mileage2,
        liters: liters2,
        createdAt: DateTime(2026, 1, 8),
      ),
    ];
  }
}
