import 'package:flutter_test/flutter_test.dart';
import 'package:gasosa_app/application/vehicles/get_vehicle_by_id_use_case.dart';
import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/factories/vehicle_factory.dart';
import '../../helpers/mock_repositories.dart';
import '../../helpers/test_helpers.dart';

void main() {
  late MockVehicleRepository mockRepository;
  late GetVehicleByIdUseCase useCase;

  setUp(() {
    mockRepository = MockVehicleRepository();
    useCase = GetVehicleByIdUseCase(repository: mockRepository);
  });

  group('GetVehicleByIdUseCase -', () {
    group('veículo encontrado', () {
      test('retorna Right com o veículo quando encontrado', () async {
        final vehicle = VehicleFactory.create(id: 'v-1');
        when(() => mockRepository.getVehicleById(any())).thenAnswer((_) async => right(vehicle));

        final result = await useCase('v-1');

        expect(result, isRight());
        expect(rightValue(result), vehicle);
        verify(() => mockRepository.getVehicleById('v-1')).called(1);
      });

      test('retorna Right(null) quando veículo não existe no repositório', () async {
        when(() => mockRepository.getVehicleById(any())).thenAnswer((_) async => right(null));

        final result = await useCase('v-not-found');

        expect(result, isRight());
        expect(rightValue(result), isNull);
      });
    });

    group('falha no repositório', () {
      test('retorna Left(DatabaseFailure) quando repositório falha', () async {
        const failure = DatabaseFailure('Erro ao buscar veículo', null, null);
        when(() => mockRepository.getVehicleById(any())).thenAnswer((_) async => left(failure));

        final result = await useCase('v-1');

        expect(result, isLeft());
        expect(result, isLeftWith<DatabaseFailure>());
        expect(leftFailure(result).message, 'Erro ao buscar veículo');
      });
    });

    group('delegação ao repositório', () {
      test('repassa o id exato ao repositório', () async {
        const id = 'exact-id-123';
        when(() => mockRepository.getVehicleById(any())).thenAnswer((_) async => right(null));

        await useCase(id);

        verify(() => mockRepository.getVehicleById(id)).called(1);
      });
    });
  });
}
