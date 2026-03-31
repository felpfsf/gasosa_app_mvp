import 'package:flutter_test/flutter_test.dart';
import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';

import 'factories/refuel_factory.dart';
import 'factories/vehicle_factory.dart';
import 'test_helpers.dart';

void main() {
  group('Test Infrastructure Validation', () {
    group('Factories', () {
      test('VehicleFactory deve criar veículo válido', () {
        final vehicle = VehicleFactory.create();

        expect(vehicle.id, isNotEmpty);
        expect(vehicle.userId, isNotEmpty);
        expect(vehicle.name, isNotEmpty);
      });

      test('RefuelFactory deve criar abastecimento válido', () {
        final refuel = RefuelFactory.create();

        expect(refuel.id, isNotEmpty);
        expect(refuel.vehicleId, isNotEmpty);
        expect(refuel.liters, greaterThan(0));
        expect(refuel.totalValue, greaterThan(0));
      });
    });

    group('Matchers Customizados', () {
      test('isRight() deve detectar Right', () {
        final result = right<Failure, String>('success');

        expect(result, isRight());
      });

      test('isLeft() deve detectar Left', () {
        final result = left<Failure, String>(const UnexpectedFailure('error', null, null));

        expect(result, isLeft());
      });

      test('isRightWith() deve validar valor Right', () {
        final result = right<Failure, String>('success');

        expect(result, isRightWith('success'));
      });

      test('isLeftWith() deve validar tipo de Failure', () {
        final result = left<Failure, String>(const UnexpectedFailure('error', null, null));

        expect(result, isLeftWith<UnexpectedFailure>());
      });

      test('isLeftWithMessage() deve validar mensagem', () {
        final result = left<Failure, String>(const UnexpectedFailure('Email inválido', null, null));

        expect(result, isLeftWithMessage('Email'));
      });

      test('rightValue() deve extrair valor Right', () {
        final result = right<Failure, String>('success');

        final value = rightValue(result);

        expect(value, 'success');
      });

      test('leftFailure() deve extrair Failure', () {
        final result = left<Failure, String>(const UnexpectedFailure('error', null, null));

        final failure = leftFailure(result);

        expect(failure, isA<UnexpectedFailure>());
        expect(failure.message, 'error');
      });
    });
  });
}
