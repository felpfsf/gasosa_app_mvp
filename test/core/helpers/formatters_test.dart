import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasosa_app/core/helpers/formatters.dart';

void main() {
  group('DigitDecimalInputFormatter', () {
    late DigitDecimalInputFormatter formatter;

    setUp(() {
      formatter = DigitDecimalInputFormatter(decimalDigits: 3);
    });

    test('deve formatar valor vazio como 0.000', () {
      // Arrange
      const oldValue = TextEditingValue(text: '');
      const newValue = TextEditingValue(text: '');

      // Act
      final result = formatter.formatEditUpdate(oldValue, newValue);

      // Assert
      expect(result.text, '0.000');
    });

    test('deve formatar dígito único corretamente', () {
      // Arrange
      const oldValue = TextEditingValue(text: '0.000');
      const newValue = TextEditingValue(text: '5');

      // Act
      final result = formatter.formatEditUpdate(oldValue, newValue);

      // Assert
      expect(result.text, '0.005');
    });

    test('deve formatar múltiplos dígitos corretamente', () {
      // Arrange
      const oldValue = TextEditingValue(text: '0.000');
      const newValue = TextEditingValue(text: '123');

      // Act
      final result = formatter.formatEditUpdate(oldValue, newValue);

      // Assert
      expect(result.text, '0.123');
    });

    test('deve mover dígitos para parte inteira quando passar de 3 decimais', () {
      // Arrange
      const oldValue = TextEditingValue(text: '0.123');
      const newValue = TextEditingValue(text: '1234');

      // Act
      final result = formatter.formatEditUpdate(oldValue, newValue);

      // Assert
      expect(result.text, '1.234');
    });

    test('deve formatar valor com parte inteira e decimal', () {
      // Arrange
      const oldValue = TextEditingValue(text: '0.000');
      const newValue = TextEditingValue(text: '45678');

      // Act
      final result = formatter.formatEditUpdate(oldValue, newValue);

      // Assert
      expect(result.text, '45.678');
    });

    test('deve remover caracteres não numéricos', () {
      // Arrange
      const oldValue = TextEditingValue(text: '0.000');
      const newValue = TextEditingValue(text: 'abc123def');

      // Act
      final result = formatter.formatEditUpdate(oldValue, newValue);

      // Assert
      expect(result.text, '0.123');
    });

    test('deve remover zeros à esquerda desnecessários da parte inteira', () {
      // Arrange
      const oldValue = TextEditingValue(text: '0.000');
      const newValue = TextEditingValue(text: '0001234');

      // Act
      final result = formatter.formatEditUpdate(oldValue, newValue);

      // Assert
      expect(result.text, '1.234');
    });

    test('deve manter pelo menos um zero na parte inteira', () {
      // Arrange
      const oldValue = TextEditingValue(text: '0.000');
      const newValue = TextEditingValue(text: '123');

      // Act
      final result = formatter.formatEditUpdate(oldValue, newValue);

      // Assert
      expect(result.text, '0.123');
    });

    test('deve limitar a 10 dígitos no máximo', () {
      // Arrange
      const oldValue = TextEditingValue(text: '0.000');
      const newValue = TextEditingValue(text: '12345678901234567890');

      // Act
      final result = formatter.formatEditUpdate(oldValue, newValue);

      // Assert
      expect(result.text.replaceAll('.', '').length, lessThanOrEqualTo(10));
    });

    test('deve manter cursor no final após formatação', () {
      // Arrange
      const oldValue = TextEditingValue(text: '0.000');
      const newValue = TextEditingValue(text: '123');

      // Act
      final result = formatter.formatEditUpdate(oldValue, newValue);

      // Assert
      expect(result.selection.baseOffset, result.text.length);
    });

    group('com decimalDigits = 2', () {
      setUp(() {
        formatter = DigitDecimalInputFormatter(decimalDigits: 2);
      });

      test('deve formatar com 2 casas decimais', () {
        // Arrange
        const oldValue = TextEditingValue(text: '');
        const newValue = TextEditingValue(text: '123');

        // Act
        final result = formatter.formatEditUpdate(oldValue, newValue);

        // Assert
        expect(result.text, '1.23');
      });

      test('deve formatar valor vazio como 0.00', () {
        // Arrange
        const oldValue = TextEditingValue(text: '');
        const newValue = TextEditingValue(text: '');

        // Act
        final result = formatter.formatEditUpdate(oldValue, newValue);

        // Assert
        expect(result.text, '0.00');
      });
    });

    group('com decimalDigits = 0', () {
      setUp(() {
        formatter = DigitDecimalInputFormatter(decimalDigits: 0);
      });

      test('deve formatar sem casas decimais', () {
        // Arrange
        const oldValue = TextEditingValue(text: '');
        const newValue = TextEditingValue(text: '123');

        // Act
        final result = formatter.formatEditUpdate(oldValue, newValue);

        // Assert
        expect(result.text, '123.');
      });
    });

    test('deve adicionar zeros à esquerda quando necessário para manter decimais', () {
      // Arrange
      const oldValue = TextEditingValue(text: '');
      const newValue = TextEditingValue(text: '5');

      // Act
      final result = formatter.formatEditUpdate(oldValue, newValue);

      // Assert
      expect(result.text, '0.005');
    });

    test('deve formatar corretamente valor grande', () {
      // Arrange
      const oldValue = TextEditingValue(text: '0.000');
      const newValue = TextEditingValue(text: '9999999');

      // Act
      final result = formatter.formatEditUpdate(oldValue, newValue);

      // Assert
      expect(result.text, '9999.999');
    });
  });
}
