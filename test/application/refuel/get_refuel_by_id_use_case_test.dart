import 'package:flutter_test/flutter_test.dart';
import 'package:gasosa_app/application/refuel/get_refuel_by_id_use_case.dart';
import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/factories/refuel_factory.dart';
import '../../helpers/mock_repositories.dart';
import '../../helpers/test_helpers.dart';

void main() {
  late MockRefuelRepository mockRepository;
  late GetRefuelByIdUseCase useCase;

  setUp(() {
    mockRepository = MockRefuelRepository();
    useCase = GetRefuelByIdUseCase(repository: mockRepository);
  });

  group('GetRefuelByIdUseCase -', () {
    group('abastecimento encontrado', () {
      test('retorna Right com o abastecimento quando encontrado', () async {
        final refuel = RefuelFactory.create(id: 'r-1');
        when(() => mockRepository.getRefuelById(any())).thenAnswer((_) async => right(refuel));

        final result = await useCase('r-1');

        expect(result, isRight());
        expect(rightValue(result), refuel);
        verify(() => mockRepository.getRefuelById('r-1')).called(1);
      });

      test('retorna Right(null) quando abastecimento não existe', () async {
        when(() => mockRepository.getRefuelById(any())).thenAnswer((_) async => right(null));

        final result = await useCase('r-not-found');

        expect(result, isRight());
        expect(rightValue(result), isNull);
      });
    });

    group('falha no repositório', () {
      test('retorna Left(DatabaseFailure) quando repositório falha', () async {
        const failure = DatabaseFailure('Erro ao buscar abastecimento', null, null);
        when(() => mockRepository.getRefuelById(any())).thenAnswer((_) async => left(failure));

        final result = await useCase('r-1');

        expect(result, isLeft());
        expect(result, isLeftWith<DatabaseFailure>());
        expect(leftFailure(result).message, 'Erro ao buscar abastecimento');
      });
    });

    group('delegação ao repositório', () {
      test('repassa o id exato ao repositório', () async {
        const id = 'exact-refuel-id';
        when(() => mockRepository.getRefuelById(any())).thenAnswer((_) async => right(null));

        await useCase(id);

        verify(() => mockRepository.getRefuelById(id)).called(1);
      });
    });
  });
}
