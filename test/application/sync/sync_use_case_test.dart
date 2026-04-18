import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasosa_app/application/sync/sync_use_case.dart';
import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/data/local/db/app_database.dart';
import 'package:gasosa_app/domain/entities/fuel_type.dart';
import 'package:gasosa_app/domain/entities/refuel.dart';
import 'package:gasosa_app/domain/entities/vehicle.dart';
import 'package:gasosa_app/domain/services/auth_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mock_services.dart';
import '../../helpers/test_helpers.dart';

void main() {
  late MockVehicleDao mockVehicleDao;
  late MockRefuelDao mockRefuelDao;
  late MockVehicleRemoteDatasource mockVehicleRemote;
  late MockRefuelRemoteDatasource mockRefuelRemote;
  late MockAuthService mockAuth;
  late MockObservabilityService mockObservability;
  late SyncUseCase useCase;

  const tUser = AuthUser('user-1', 'Test', 'test@test.com');
  final tNow = DateTime(2026, 4, 18, 12, 0);
  final tOlder = DateTime(2026, 4, 18, 10, 0);
  final tNewer = DateTime(2026, 4, 18, 14, 0);

  setUpAll(() {
    registerFallbackValue(const UnexpectedFailure('', null, null));
    registerFallbackValue(VehicleEntity(
      id: '',
      userId: '',
      name: '',
      fuelType: FuelType.flex,
      createdAt: DateTime.now(),
    ));
    registerFallbackValue(RefuelEntity(
      id: '',
      vehicleId: '',
      refuelDate: DateTime.now(),
      fuelType: FuelType.gasoline,
      totalValue: 0,
      mileage: 0,
      liters: 0,
      createdAt: DateTime.now(),
    ));
    registerFallbackValue(const VehiclesCompanion());
    registerFallbackValue(const RefuelsCompanion());
  });

  setUp(() {
    mockVehicleDao = MockVehicleDao();
    mockRefuelDao = MockRefuelDao();
    mockVehicleRemote = MockVehicleRemoteDatasource();
    mockRefuelRemote = MockRefuelRemoteDatasource();
    mockAuth = MockAuthService();
    mockObservability = MockObservabilityService();

    useCase = SyncUseCase(
      vehicleDao: mockVehicleDao,
      refuelDao: mockRefuelDao,
      vehicleRemote: mockVehicleRemote,
      refuelRemote: mockRefuelRemote,
      auth: mockAuth,
      observability: mockObservability,
    );

    when(() => mockObservability.logEvent(any(), parameters: any(named: 'parameters')))
        .thenAnswer((_) async {});
    when(() => mockObservability.logError(any(), stackTrace: any(named: 'stackTrace'), context: any(named: 'context')))
        .thenAnswer((_) async {});
  });

  VehicleRow vehicleRow({
    String id = 'v1',
    String userId = 'user-1',
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) =>
      VehicleRow(
        id: id,
        userId: userId,
        name: 'Car',
        fuelType: 'gasoline',
        createdAt: createdAt ?? tNow,
        updatedAt: updatedAt,
        deletedAt: deletedAt,
      );

  Map<String, dynamic> vehicleMap({
    String id = 'v1',
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) =>
      {
        'id': id,
        'name': 'Car',
        'fuelType': 'gasoline',
        'plate': null,
        'tankCapacity': null,
        'photoPath': null,
        'createdAt': Timestamp.fromDate(createdAt ?? tNow),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt) : null,
        'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt) : null,
      };

  RefuelRow refuelRow({
    String id = 'r1',
    String vehicleId = 'v1',
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) =>
      RefuelRow(
        id: id,
        vehicleId: vehicleId,
        refuelDate: tNow,
        fuelType: 'gasoline',
        totalValue: 100.0,
        mileage: 5000,
        liters: 20.0,
        createdAt: createdAt ?? tNow,
        updatedAt: updatedAt,
        deletedAt: deletedAt,
      );

  Map<String, dynamic> refuelMap({
    String id = 'r1',
    String vehicleId = 'v1',
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) =>
      {
        'id': id,
        'vehicleId': vehicleId,
        'refuelDate': Timestamp.fromDate(tNow),
        'fuelType': 'gasoline',
        'totalValue': 100.0,
        'mileage': 5000,
        'liters': 20.0,
        'coldStartLiters': null,
        'coldStartValue': null,
        'receiptPath': null,
        'createdAt': Timestamp.fromDate(createdAt ?? tNow),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt) : null,
        'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt) : null,
      };

  void stubEmptySync() {
    when(() => mockAuth.currentUser()).thenAnswer((_) async => tUser);
    when(() => mockVehicleDao.getAllByUserIdIncludingDeleted(any())).thenAnswer((_) async => []);
    when(() => mockVehicleRemote.getAllByUserId(any())).thenAnswer((_) async => []);
    when(() => mockRefuelDao.getAllByVehicleIdsIncludingDeleted(any())).thenAnswer((_) async => []);
    when(() => mockRefuelRemote.getAllByUserId(any())).thenAnswer((_) async => []);
  }

  SyncResult _unwrap(Either<Failure, SyncResult> result) =>
      result.getOrElse((_) => throw Exception('Expected Right'));

  group('SyncUseCase -', () {
    test('retorna Left quando usuário não está autenticado', () async {
      when(() => mockAuth.currentUser()).thenAnswer((_) async => null);

      final result = await useCase();

      expect(result, isLeft());
    });

    test('retorna Right com zeros quando não há dados', () async {
      stubEmptySync();

      final result = await useCase();

      expect(result, isRight());
      expect(_unwrap(result).total, 0);
    });

    group('vehicles -', () {
      test('push: local-only vehicle é enviado ao remote', () async {
        when(() => mockAuth.currentUser()).thenAnswer((_) async => tUser);
        when(() => mockVehicleDao.getAllByUserIdIncludingDeleted('user-1'))
            .thenAnswer((_) async => [vehicleRow()]);
        when(() => mockVehicleRemote.getAllByUserId('user-1'))
            .thenAnswer((_) async => []);
        when(() => mockVehicleRemote.upsert(any(), any()))
            .thenAnswer((_) async {});
        when(() => mockRefuelDao.getAllByVehicleIdsIncludingDeleted(any()))
            .thenAnswer((_) async => []);
        when(() => mockRefuelRemote.getAllByUserId(any()))
            .thenAnswer((_) async => []);

        final result = await useCase();

        expect(result, isRight());
        expect(_unwrap(result).vehiclesPushed, 1);
        verify(() => mockVehicleRemote.upsert('user-1', any())).called(1);
      });

      test('push: local soft-deleted vehicle envia softDelete ao remote', () async {
        when(() => mockAuth.currentUser()).thenAnswer((_) async => tUser);
        when(() => mockVehicleDao.getAllByUserIdIncludingDeleted('user-1'))
            .thenAnswer((_) async => [vehicleRow(deletedAt: tNow)]);
        when(() => mockVehicleRemote.getAllByUserId('user-1'))
            .thenAnswer((_) async => []);
        when(() => mockVehicleRemote.softDelete(any(), any(), any()))
            .thenAnswer((_) async {});
        when(() => mockRefuelDao.getAllByVehicleIdsIncludingDeleted(any()))
            .thenAnswer((_) async => []);
        when(() => mockRefuelRemote.getAllByUserId(any()))
            .thenAnswer((_) async => []);

        final result = await useCase();

        expect(result, isRight());
        expect(_unwrap(result).vehiclesPushed, 1);
        verify(() => mockVehicleRemote.softDelete('user-1', 'v1', tNow)).called(1);
      });

      test('pull: remote-only vehicle é salvo localmente', () async {
        when(() => mockAuth.currentUser()).thenAnswer((_) async => tUser);
        when(() => mockVehicleDao.getAllByUserIdIncludingDeleted('user-1'))
            .thenAnswer((_) async => []);
        when(() => mockVehicleRemote.getAllByUserId('user-1'))
            .thenAnswer((_) async => [vehicleMap()]);
        when(() => mockVehicleDao.upsert(any()))
            .thenAnswer((_) async {});
        when(() => mockRefuelDao.getAllByVehicleIdsIncludingDeleted(any()))
            .thenAnswer((_) async => []);
        when(() => mockRefuelRemote.getAllByUserId(any()))
            .thenAnswer((_) async => []);

        final result = await useCase();

        expect(result, isRight());
        expect(_unwrap(result).vehiclesPulled, 1);
        verify(() => mockVehicleDao.upsert(any())).called(1);
      });

      test('conflito: local mais recente → push para remote', () async {
        when(() => mockAuth.currentUser()).thenAnswer((_) async => tUser);
        when(() => mockVehicleDao.getAllByUserIdIncludingDeleted('user-1'))
            .thenAnswer((_) async => [vehicleRow(updatedAt: tNewer)]);
        when(() => mockVehicleRemote.getAllByUserId('user-1'))
            .thenAnswer((_) async => [vehicleMap(updatedAt: tOlder)]);
        when(() => mockVehicleRemote.upsert(any(), any()))
            .thenAnswer((_) async {});
        when(() => mockRefuelDao.getAllByVehicleIdsIncludingDeleted(any()))
            .thenAnswer((_) async => []);
        when(() => mockRefuelRemote.getAllByUserId(any()))
            .thenAnswer((_) async => []);

        final result = await useCase();

        expect(result, isRight());
        expect(_unwrap(result).vehiclesPushed, 1);
        expect(_unwrap(result).vehiclesPulled, 0);
        verify(() => mockVehicleRemote.upsert('user-1', any())).called(1);
      });

      test('conflito: remote mais recente → pull para local', () async {
        when(() => mockAuth.currentUser()).thenAnswer((_) async => tUser);
        when(() => mockVehicleDao.getAllByUserIdIncludingDeleted('user-1'))
            .thenAnswer((_) async => [vehicleRow(updatedAt: tOlder)]);
        when(() => mockVehicleRemote.getAllByUserId('user-1'))
            .thenAnswer((_) async => [vehicleMap(updatedAt: tNewer)]);
        when(() => mockVehicleDao.upsert(any()))
            .thenAnswer((_) async {});
        when(() => mockRefuelDao.getAllByVehicleIdsIncludingDeleted(any()))
            .thenAnswer((_) async => []);
        when(() => mockRefuelRemote.getAllByUserId(any()))
            .thenAnswer((_) async => []);

        final result = await useCase();

        expect(result, isRight());
        expect(_unwrap(result).vehiclesPulled, 1);
        expect(_unwrap(result).vehiclesPushed, 0);
        verify(() => mockVehicleDao.upsert(any())).called(1);
      });

      test('conflito: mesmo updatedAt → nenhuma ação', () async {
        when(() => mockAuth.currentUser()).thenAnswer((_) async => tUser);
        when(() => mockVehicleDao.getAllByUserIdIncludingDeleted('user-1'))
            .thenAnswer((_) async => [vehicleRow(updatedAt: tNow)]);
        when(() => mockVehicleRemote.getAllByUserId('user-1'))
            .thenAnswer((_) async => [vehicleMap(updatedAt: tNow)]);
        when(() => mockRefuelDao.getAllByVehicleIdsIncludingDeleted(any()))
            .thenAnswer((_) async => []);
        when(() => mockRefuelRemote.getAllByUserId(any()))
            .thenAnswer((_) async => []);

        final result = await useCase();

        expect(result, isRight());
        expect(_unwrap(result).total, 0);
        verifyNever(() => mockVehicleRemote.upsert(any(), any()));
        verifyNever(() => mockVehicleDao.upsert(any()));
      });
    });

    group('refuels -', () {
      test('push: local-only refuel é enviado ao remote', () async {
        when(() => mockAuth.currentUser()).thenAnswer((_) async => tUser);
        when(() => mockVehicleDao.getAllByUserIdIncludingDeleted('user-1'))
            .thenAnswer((_) async => [vehicleRow()]);
        when(() => mockVehicleRemote.getAllByUserId('user-1'))
            .thenAnswer((_) async => [vehicleMap()]);
        when(() => mockRefuelDao.getAllByVehicleIdsIncludingDeleted(['v1']))
            .thenAnswer((_) async => [refuelRow()]);
        when(() => mockRefuelRemote.getAllByUserId('user-1'))
            .thenAnswer((_) async => []);
        when(() => mockRefuelRemote.upsert(any(), any()))
            .thenAnswer((_) async {});

        final result = await useCase();

        expect(result, isRight());
        expect(_unwrap(result).refuelsPushed, 1);
        verify(() => mockRefuelRemote.upsert('user-1', any())).called(1);
      });

      test('pull: remote-only refuel é salvo localmente', () async {
        when(() => mockAuth.currentUser()).thenAnswer((_) async => tUser);
        when(() => mockVehicleDao.getAllByUserIdIncludingDeleted('user-1'))
            .thenAnswer((_) async => [vehicleRow()]);
        when(() => mockVehicleRemote.getAllByUserId('user-1'))
            .thenAnswer((_) async => [vehicleMap()]);
        when(() => mockRefuelDao.getAllByVehicleIdsIncludingDeleted(['v1']))
            .thenAnswer((_) async => []);
        when(() => mockRefuelRemote.getAllByUserId('user-1'))
            .thenAnswer((_) async => [refuelMap()]);
        when(() => mockRefuelDao.upsert(any()))
            .thenAnswer((_) async {});

        final result = await useCase();

        expect(result, isRight());
        expect(_unwrap(result).refuelsPulled, 1);
        verify(() => mockRefuelDao.upsert(any())).called(1);
      });
    });

    test('retorna Left quando ocorre exceção durante sync', () async {
      when(() => mockAuth.currentUser()).thenAnswer((_) async => tUser);
      when(() => mockVehicleDao.getAllByUserIdIncludingDeleted(any()))
          .thenThrow(Exception('DB error'));

      final result = await useCase();

      expect(result, isLeft());
    });

    test('loga evento de analytics ao completar sync', () async {
      stubEmptySync();

      await useCase();

      verify(() => mockObservability.logEvent('sync_completed', parameters: any(named: 'parameters'))).called(1);
    });
  });
}
