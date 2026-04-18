import 'package:gasosa_app/core/services/observability/observability_service.dart';
import 'package:gasosa_app/data/local/dao/refuel_dao.dart';
import 'package:gasosa_app/data/local/dao/vehicle_dao.dart';
import 'package:gasosa_app/data/remote/refuel_remote_datasource.dart';
import 'package:gasosa_app/data/remote/vehicle_remote_datasource.dart';
import 'package:gasosa_app/domain/services/auth_service.dart';
import 'package:mocktail/mocktail.dart';

/// Mock do AuthService para testes
class MockAuthService extends Mock implements AuthService {}

/// Mock do ObservabilityService para testes
class MockObservabilityService extends Mock implements ObservabilityService {}

/// Mock do VehicleDao para testes
class MockVehicleDao extends Mock implements VehicleDao {}

/// Mock do RefuelDao para testes
class MockRefuelDao extends Mock implements RefuelDao {}

/// Mock do VehicleRemoteDatasource para testes
class MockVehicleRemoteDatasource extends Mock implements VehicleRemoteDatasource {}

/// Mock do RefuelRemoteDatasource para testes
class MockRefuelRemoteDatasource extends Mock implements RefuelRemoteDatasource {}
