import 'package:faker/faker.dart';
import 'package:gasosa_app/domain/entities/fuel_type.dart';
import 'package:gasosa_app/domain/entities/vehicle.dart';

/// Factory para criar VehicleEntity fake nos testes
class VehicleFactory {
  static final _faker = Faker();

  /// Cria um VehicleEntity com valores fake ou customizados
  static VehicleEntity create({
    String? id,
    String? userId,
    String? name,
    String? plate,
    double? tankCapacity,
    FuelType? fuelType,
    String? photoPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VehicleEntity(
      id: id ?? _faker.guid.guid(),
      userId: userId ?? _faker.guid.guid(),
      name: name ?? _faker.vehicle.model(),
      plate: plate,
      tankCapacity: tankCapacity,
      fuelType: fuelType ?? FuelType.gasoline,
      photoPath: photoPath,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt,
    );
  }

  /// Cria um VehicleEntity completo com todos os campos opcionais
  static VehicleEntity createFull({
    String? id,
    String? userId,
    String? name,
    String? plate,
    double? tankCapacity,
    FuelType? fuelType,
    String? photoPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VehicleEntity(
      id: id ?? _faker.guid.guid(),
      userId: userId ?? _faker.guid.guid(),
      name: name ?? '${_faker.company.name()} ${_faker.vehicle.model()}',
      plate: plate ?? _generatePlate(),
      tankCapacity: tankCapacity ?? _faker.randomGenerator.decimal(scale: 80.0, min: 30.0),
      fuelType: fuelType ?? FuelType.values[_faker.randomGenerator.integer(FuelType.values.length)],
      photoPath: photoPath ?? '/photos/${_faker.guid.guid()}.jpg',
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Cria um VehicleEntity sem campos opcionais (plate, tankCapacity, photoPath)
  static VehicleEntity createMinimal({
    String id = '',
    String? userId,
    String? name,
    FuelType? fuelType,
    DateTime? createdAt,
  }) {
    return VehicleEntity(
      id: id,
      userId: userId ?? _faker.guid.guid(),
      name: name ?? _faker.vehicle.model(),
      fuelType: fuelType ?? FuelType.flex,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  /// Cria um VehicleEntity válido para testes específicos
  static VehicleEntity createValid({
    String id = 'vehicle-123',
    String userId = 'user-456',
    String name = 'Honda Civic',
    String plate = 'ABC1234',
    double tankCapacity = 50.0,
    FuelType fuelType = FuelType.gasoline,
  }) {
    return VehicleEntity(
      id: id,
      userId: userId,
      name: name,
      plate: plate,
      tankCapacity: tankCapacity,
      fuelType: fuelType,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  /// Cria um VehicleEntity para criação (id vazio)
  static VehicleEntity createNew({
    String? userId,
    String? name,
    FuelType? fuelType,
  }) {
    return VehicleEntity(
      id: '',
      userId: userId ?? _faker.guid.guid(),
      name: name ?? _faker.vehicle.model(),
      fuelType: fuelType ?? FuelType.gasoline,
      createdAt: DateTime.now(),
    );
  }

  /// Cria uma lista de VehicleEntity fake
  static List<VehicleEntity> createList(int count, {String? userId}) {
    final fixedUserId = userId ?? _faker.guid.guid();
    return List.generate(
      count,
      (index) => create(
        userId: fixedUserId,
        name: '${_faker.vehicle.model()} ${index + 1}',
      ),
    );
  }

  /// Cria uma lista de VehicleEntity completos
  static List<VehicleEntity> createFullList(int count, {String? userId}) {
    final fixedUserId = userId ?? _faker.guid.guid();
    return List.generate(count, (_) => createFull(userId: fixedUserId));
  }

  /// Gera uma placa brasileira fake no formato ABC1D23 ou ABC1234
  static String _generatePlate() {
    final useNewFormat = _faker.randomGenerator.boolean();
    if (useNewFormat) {
      // Placa Mercosul: ABC1D23
      return '${_faker.randomGenerator.fromCharSet('ABCDEFGHIJKLMNOPQRSTUVWXYZ', 3)}'
          '${_faker.randomGenerator.integer(9)}'
          '${_faker.randomGenerator.fromCharSet('ABCDEFGHIJKLMNOPQRSTUVWXYZ', 1)}'
          '${_faker.randomGenerator.integer(99, min: 10)}';
    } else {
      // Placa antiga: ABC1234
      return '${_faker.randomGenerator.fromCharSet('ABCDEFGHIJKLMNOPQRSTUVWXYZ', 3)}'
          '${_faker.randomGenerator.integer(9999, min: 1000)}';
    }
  }
}
