import 'package:flutter_test/flutter_test.dart';
import 'package:gasosa_app/application/refuel/get_refuels_by_vehicle_use_case.dart';
import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/factories/refuel_factory.dart';
import '../../helpers/mock_repositories.dart';
import '../../helpers/test_helpers.dart';

void main() {
  late MockRefuelRepository mockRepository;
  late GetRefuelsByVehicleUseCase useCase;

  setUp(() {
    mockRepository = MockRefuelRepository();
    useCase = GetRefuelsByVehicleUseCase(repository: mockRepository);
  });

  group('GetRefuelsByVehicleUseCase -', () {
    group('lista de abastecimentos', () {
      test('retorna Right com lista preenchida', () async {
        final refuels = [
          RefuelFactory.create(vehicleId: 'v-1'),
          RefuelFactory.create(vehicleId: 'v-1'),
        ];
        when(() => mockRepository.getAllByVehicleId(any())).thenAnswer((_) async => right(refuels));

        final result = await useCase('v-1');

        expect(result, isRight());
        expect(rightValue(result), hasLength(2));
        verify(() => mockRepository.getAllByVehicleId('v-1')).called(1);
      });

      test('retorna Right com lista vazia quando não há abastecimentos', () async {
        when(() => mockRepository.getAllByVehicleId(any())).thenAnswer((_) async => right([]));

        final result = await useCase('v-empty');

        expect(result, isRight());
        expect(rightValue(result), isEmpty);
      });
    });

    group('falha no repositório', () {
      test('retorna Left(DatabaseFailure) quando repositório falha', () async {
        const failure = DatabaseFailure('Erro ao buscar abastecimentos', null, null);
        when(() => mockRepository.getAllByVehicleId(any())).thenAnswer((_) async => left(failure));

        final result = await useCase('v-1');

        expect(result, isLeft());
        expect(result, isLeftWith<DatabaseFailure>());
        expect(leftFailure(result).message, 'Erro ao buscar abastecimentos');
      });
    });

    group('delegação ao repositório', () {
      test('repassa o vehicleId exato ao repositório', () async {
        const vehicleId = 'exact-vehicle-id';
        when(() => mockRepository.getAllByVehicleId(any())).thenAnswer((_) async => right([]));

        await useCase(vehicleId);

        verify(() => mockRepository.getAllByVehicleId(vehicleId)).called(1);
      });
    });
  });
}
