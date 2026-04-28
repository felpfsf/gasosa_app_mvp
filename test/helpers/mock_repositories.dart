import 'package:gasosa_app/domain/repositories/refuel_repository.dart';
import 'package:gasosa_app/domain/repositories/user_repository.dart';
import 'package:gasosa_app/domain/repositories/vehicle_repository.dart';
import 'package:mocktail/mocktail.dart';

/// Mock do VehicleRepository para testes
class MockVehicleRepository extends Mock implements VehicleRepository {}

/// Mock do RefuelRepository para testes
class MockRefuelRepository extends Mock implements RefuelRepository {}

/// Mock do UserRepository para testes
class MockUserRepository extends Mock implements UserRepository {}
