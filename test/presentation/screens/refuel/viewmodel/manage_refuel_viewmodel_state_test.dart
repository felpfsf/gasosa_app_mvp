import 'package:flutter_test/flutter_test.dart';
import 'package:gasosa_app/domain/entities/fuel_type.dart';
import 'package:gasosa_app/presentation/screens/refuel/viewmodel/manage_refuel_viewmodel.dart';

void main() {
  group('ManageRefuelState - Single Source of Truth', () {
    test('hasColdStart should be derived from state values', () {
      final state1 = ManageRefuelState();
      expect(state1.coldStartLiters, isNull);
      expect(state1.coldStartValue, isNull);

      final state2 = state1.copyWith(
        coldStartLiters: 10.5,
        coldStartValue: 50.0,
      );
      expect(state2.coldStartLiters, 10.5);
      expect(state2.coldStartValue, 50.0);
    });

    test('state copyWith should preserve cold start values when not cleared', () {
      final state = ManageRefuelState(
        coldStartLiters: 10.0,
        coldStartValue: 50.0,
      );

      final copiedState = state.copyWith();

      expect(copiedState.coldStartLiters, 10.0);
      expect(copiedState.coldStartValue, 50.0);
    });

    test('state copyWith should clear cold start values with clearColdStart flag', () {
      final state = ManageRefuelState(
        coldStartLiters: 10.0,
        coldStartValue: 50.0,
      );

      final clearedState = state.copyWith(clearColdStart: true);

      expect(clearedState.coldStartLiters, isNull);
      expect(clearedState.coldStartValue, isNull);
    });

    test('receiptPath can be cleared with clearPhotoPath flag', () {
      final state = ManageRefuelState(receiptPath: '/path/to/photo.jpg');
      expect(state.receiptPath, isNotNull);

      final clearedState = state.copyWith(clearPhotoPath: true);
      expect(clearedState.receiptPath, isNull);
    });

    test('fuelType defaults to gasoline', () {
      final state = ManageRefuelState();
      expect(state.fuelType, FuelType.gasoline);
    });

    test('fuelType can be updated', () {
      final state = ManageRefuelState();
      final updatedState = state.copyWith(fuelType: FuelType.ethanol);
      expect(updatedState.fuelType, FuelType.ethanol);
    });

    test('isEditing indicates edit mode correctly', () {
      final createState = ManageRefuelState();
      expect(createState.isEditing, isFalse);

      final editState = ManageRefuelState(isEditing: true);
      expect(editState.isEditing, isTrue);
    });
  });
}
