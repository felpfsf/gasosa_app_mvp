import 'package:gasosa_app/domain/entities/fuel_type.dart';
import 'package:gasosa_app/domain/entities/vehicle.dart';

/// Domain service that encapsulates refuel business rules.
/// These rules are pure domain logic and don't depend on infrastructure.
class RefuelBusinessRules {
  const RefuelBusinessRules();

  /// Calculates which fuel types are available for a given vehicle.
  ///
  /// Rules:
  /// - Flex vehicles can use gasoline or ethanol
  /// - Single-fuel vehicles can only use their specific fuel type
  List<FuelType> getAvailableFuelTypes(VehicleEntity vehicle) {
    switch (vehicle.fuelType) {
      case FuelType.flex:
        return [FuelType.gasoline, FuelType.ethanol];
      case FuelType.gasoline:
      case FuelType.ethanol:
      case FuelType.diesel:
      case FuelType.gnv:
        return [vehicle.fuelType];
    }
  }

  /// Determines if a vehicle has a cold start reservoir.
  ///
  /// Cold start is present in:
  /// - Ethanol vehicles
  /// - Flex vehicles
  /// - GNV vehicles
  bool vehicleHasColdStartReservoir(VehicleEntity vehicle) {
    return vehicle.fuelType == FuelType.ethanol ||
        vehicle.fuelType == FuelType.flex ||
        vehicle.fuelType == FuelType.gnv;
  }

  /// Determines if cold start fields should be shown based on vehicle and selected fuel.
  ///
  /// Rules:
  /// - Vehicle must have cold start reservoir
  /// - For flex vehicles: always show (user chooses ethanol or gasoline in reservoir)
  /// - For ethanol/GNV: only show when selected fuel matches
  bool shouldShowColdStart({
    required VehicleEntity vehicle,
    required FuelType selectedFuelType,
  }) {
    if (!vehicleHasColdStartReservoir(vehicle)) {
      return false;
    }

    // Flex vehicles always have cold start option
    if (vehicle.fuelType == FuelType.flex) {
      return true;
    }

    // For single-fuel ethanol/GNV, show only when that fuel is selected
    return selectedFuelType == FuelType.ethanol || selectedFuelType == FuelType.gnv;
  }

  /// Validates that mileage is greater than previous refuel's mileage.
  ///
  /// Returns error message if invalid, null if valid.
  String? validateMileageAgainstPrevious({
    required int currentMileage,
    required int? previousMileage,
  }) {
    if (previousMileage == null) {
      return null; // No previous refuel, validation passes
    }

    if (currentMileage < previousMileage) {
      return 'KM não pode ser menor que o abastecimento anterior ($previousMileage km)';
    }

    return null;
  }
}
