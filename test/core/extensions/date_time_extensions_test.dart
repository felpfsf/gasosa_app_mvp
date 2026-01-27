import 'package:flutter_test/flutter_test.dart';
import 'package:gasosa_app/core/extensions/date_time_extensions.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    // Inicializa locale pt_BR para testes de formatação
    await initializeDateFormatting('pt_BR');
  });
  group('DateTimeExtensions.formattedDate', () {
    test('deve formatar data corretamente em formato dd/MM/yyyy', () {
      // Arrange
      final date = DateTime(2026, 1, 27);

      // Act
      final result = date.formattedDate();

      // Assert
      expect(result, '27/01/2026');
    });

    test('deve adicionar zero à esquerda para dia < 10', () {
      // Arrange
      final date = DateTime(2026, 12, 5);

      // Act
      final result = date.formattedDate();

      // Assert
      expect(result, '05/12/2026');
    });

    test('deve adicionar zero à esquerda para mês < 10', () {
      // Arrange
      final date = DateTime(2026, 3, 15);

      // Act
      final result = date.formattedDate();

      // Assert
      expect(result, '15/03/2026');
    });

    test('deve retornar --/--/---- quando data é nula', () {
      // Arrange
      const DateTime? date = null;

      // Act
      final result = date.formattedDate();

      // Assert
      expect(result, '--/--/----');
    });

    test('deve formatar corretamente 31 de dezembro', () {
      // Arrange
      final date = DateTime(2025, 12, 31);

      // Act
      final result = date.formattedDate();

      // Assert
      expect(result, '31/12/2025');
    });

    test('deve formatar corretamente 1º de janeiro', () {
      // Arrange
      final date = DateTime(2026);

      // Act
      final result = date.formattedDate();

      // Assert
      expect(result, '01/01/2026');
    });

    test('deve formatar corretamente ano bissexto (29 de fevereiro)', () {
      // Arrange
      final date = DateTime(2024, 2, 29);

      // Act
      final result = date.formattedDate();

      // Assert
      expect(result, '29/02/2024');
    });

    test('deve ignorar hora/minuto/segundo na formatação', () {
      // Arrange
      final date = DateTime(2026, 6, 15, 14, 30, 45);

      // Act
      final result = date.formattedDate();

      // Assert
      expect(result, '15/06/2026');
    });
  });

  group('DateTimeExtensions.formattedFullDate', () {
    test('deve formatar data por extenso em português', () {
      // Arrange
      final date = DateTime(2026, 1, 27);

      // Act
      final result = date.formattedFullDate();

      // Assert
      expect(result, '27 de janeiro de 2026');
    });

    test('deve retornar string vazia quando data é nula', () {
      // Arrange
      const DateTime? date = null;

      // Act
      final result = date.formattedFullDate();

      // Assert
      expect(result, '');
    });

    test('deve formatar corretamente mês de fevereiro', () {
      // Arrange
      final date = DateTime(2026, 2, 14);

      // Act
      final result = date.formattedFullDate();

      // Assert
      expect(result, '14 de fevereiro de 2026');
    });

    test('deve formatar corretamente mês de março', () {
      // Arrange
      final date = DateTime(2026, 3, 8);

      // Act
      final result = date.formattedFullDate();

      // Assert
      expect(result, '8 de março de 2026');
    });

    test('deve formatar corretamente mês de dezembro', () {
      // Arrange
      final date = DateTime(2025, 12, 25);

      // Act
      final result = date.formattedFullDate();

      // Assert
      expect(result, '25 de dezembro de 2025');
    });

    test('deve formatar dia 1 sem zero à esquerda', () {
      // Arrange
      final date = DateTime(2026, 7);

      // Act
      final result = date.formattedFullDate();

      // Assert
      expect(result, '1 de julho de 2026');
    });

    test('deve ignorar hora/minuto/segundo na formatação', () {
      // Arrange
      final date = DateTime(2026, 10, 12, 23, 59, 59);

      // Act
      final result = date.formattedFullDate();

      // Assert
      expect(result, '12 de outubro de 2026');
    });

    test('deve formatar todos os meses corretamente', () {
      final months = [
        (1, 'janeiro'),
        (2, 'fevereiro'),
        (3, 'março'),
        (4, 'abril'),
        (5, 'maio'),
        (6, 'junho'),
        (7, 'julho'),
        (8, 'agosto'),
        (9, 'setembro'),
        (10, 'outubro'),
        (11, 'novembro'),
        (12, 'dezembro'),
      ];

      for (final (month, monthName) in months) {
        final date = DateTime(2026, month, 15);
        final result = date.formattedFullDate();
        expect(
          result,
          '15 de $monthName de 2026',
          reason: 'Mês $month deveria ser formatado como $monthName',
        );
      }
    });
  });
}
