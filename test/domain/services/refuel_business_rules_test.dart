import 'package:flutter_test/flutter_test.dart';
import 'package:gasosa_app/domain/entities/fuel_type.dart';
import 'package:gasosa_app/domain/entities/vehicle.dart';
import 'package:gasosa_app/domain/services/refuel_business_rules.dart';

void main() {
  late RefuelBusinessRules businessRules;

  setUp(() {
    businessRules = const RefuelBusinessRules();
  });

  group('RefuelBusinessRules - getAvailableFuelTypes', () {
    test('flex vehicle should return gasoline and ethanol', () {
      final vehicle = _createVehicle(fuelType: FuelType.flex);

      final result = businessRules.getAvailableFuelTypes(vehicle);

      expect(result, containsAll([FuelType.gasoline, FuelType.ethanol]));
      expect(result.length, 2);
    });

    test('gasoline vehicle should return only gasoline', () {
      final vehicle = _createVehicle(fuelType: FuelType.gasoline);

      final result = businessRules.getAvailableFuelTypes(vehicle);

      expect(result, [FuelType.gasoline]);
      expect(result.length, 1);
    });

    test('ethanol vehicle should return only ethanol', () {
      final vehicle = _createVehicle(fuelType: FuelType.ethanol);

      final result = businessRules.getAvailableFuelTypes(vehicle);

      expect(result, [FuelType.ethanol]);
      expect(result.length, 1);
    });

    test('diesel vehicle should return only diesel', () {
      final vehicle = _createVehicle(fuelType: FuelType.diesel);

      final result = businessRules.getAvailableFuelTypes(vehicle);

      expect(result, [FuelType.diesel]);
      expect(result.length, 1);
    });

    test('gnv vehicle should return only gnv', () {
      final vehicle = _createVehicle(fuelType: FuelType.gnv);

      final result = businessRules.getAvailableFuelTypes(vehicle);

      expect(result, [FuelType.gnv]);
      expect(result.length, 1);
    });
  });

  group('RefuelBusinessRules - vehicleHasColdStartReservoir', () {
    test('ethanol vehicle has cold start reservoir', () {
      final vehicle = _createVehicle(fuelType: FuelType.ethanol);

      final result = businessRules.vehicleHasColdStartReservoir(vehicle);

      expect(result, isTrue);
    });

    test('flex vehicle has cold start reservoir', () {
      final vehicle = _createVehicle(fuelType: FuelType.flex);

      final result = businessRules.vehicleHasColdStartReservoir(vehicle);

      expect(result, isTrue);
    });

    test('gnv vehicle has cold start reservoir', () {
      final vehicle = _createVehicle(fuelType: FuelType.gnv);

      final result = businessRules.vehicleHasColdStartReservoir(vehicle);

      expect(result, isTrue);
    });

    test('gasoline vehicle does not have cold start reservoir', () {
      final vehicle = _createVehicle(fuelType: FuelType.gasoline);

      final result = businessRules.vehicleHasColdStartReservoir(vehicle);

      expect(result, isFalse);
    });

    test('diesel vehicle does not have cold start reservoir', () {
      final vehicle = _createVehicle(fuelType: FuelType.diesel);

      final result = businessRules.vehicleHasColdStartReservoir(vehicle);

      expect(result, isFalse);
    });
  });

  group('RefuelBusinessRules - shouldShowColdStart', () {
    test('flex vehicle always shows cold start regardless of selected fuel', () {
      final vehicle = _createVehicle(fuelType: FuelType.flex);

      final resultGasoline = businessRules.shouldShowColdStart(
        vehicle: vehicle,
        selectedFuelType: FuelType.gasoline,
      );
      final resultEthanol = businessRules.shouldShowColdStart(
        vehicle: vehicle,
        selectedFuelType: FuelType.ethanol,
      );

      expect(resultGasoline, isTrue);
      expect(resultEthanol, isTrue);
    });

    test('ethanol vehicle shows cold start only when ethanol is selected', () {
      final vehicle = _createVehicle(fuelType: FuelType.ethanol);

      final result = businessRules.shouldShowColdStart(
        vehicle: vehicle,
        selectedFuelType: FuelType.ethanol,
      );

      expect(result, isTrue);
    });

    test('gnv vehicle shows cold start only when gnv is selected', () {
      final vehicle = _createVehicle(fuelType: FuelType.gnv);

      final result = businessRules.shouldShowColdStart(
        vehicle: vehicle,
        selectedFuelType: FuelType.gnv,
      );

      expect(result, isTrue);
    });

    test('gasoline vehicle never shows cold start', () {
      final vehicle = _createVehicle(fuelType: FuelType.gasoline);

      final result = businessRules.shouldShowColdStart(
        vehicle: vehicle,
        selectedFuelType: FuelType.gasoline,
      );

      expect(result, isFalse);
    });

    test('diesel vehicle never shows cold start', () {
      final vehicle = _createVehicle(fuelType: FuelType.diesel);

      final result = businessRules.shouldShowColdStart(
        vehicle: vehicle,
        selectedFuelType: FuelType.diesel,
      );

      expect(result, isFalse);
    });
  });

  group('RefuelBusinessRules - validateMileageAgainstPrevious', () {
    test('validation passes when there is no previous mileage', () {
      final result = businessRules.validateMileageAgainstPrevious(
        currentMileage: 10000,
        previousMileage: null,
      );

      expect(result, isNull);
    });

    test('validation passes when current mileage is greater than previous', () {
      final result = businessRules.validateMileageAgainstPrevious(
        currentMileage: 15000,
        previousMileage: 10000,
      );

      expect(result, isNull);
    });

    test('validation passes when current mileage equals previous', () {
      final result = businessRules.validateMileageAgainstPrevious(
        currentMileage: 10000,
        previousMileage: 10000,
      );

      expect(result, isNull);
    });

    test('validation fails when current mileage is less than previous', () {
      final result = businessRules.validateMileageAgainstPrevious(
        currentMileage: 8000,
        previousMileage: 10000,
      );

      expect(result, isNotNull);
      expect(result, contains('10000 km'));
    });

    test('error message contains the previous mileage value', () {
      final result = businessRules.validateMileageAgainstPrevious(
        currentMileage: 5000,
        previousMileage: 12345,
      );

      expect(result, contains('12345'));
    });
  });
}

// Helper function to create test vehicles
VehicleEntity _createVehicle({required FuelType fuelType}) {
  return VehicleEntity(
    id: 'test-id',
    userId: 'test-user',
    name: 'Test Vehicle',
    fuelType: fuelType,
    createdAt: DateTime.now(),
  );
}
