import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class DigitDecimalInputFormatter extends TextInputFormatter {
  DigitDecimalInputFormatter({this.decimalDigits = 3})
    : assert(decimalDigits >= 0, 'Decimal digits must be at least 0');

  final int decimalDigits;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Remove todos os caracteres não numéricos
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Se não há dígitos, retorna 0.00
    if (digitsOnly.isEmpty) {
      final emptyValue = '0.${'0' * decimalDigits}';
      return TextEditingValue(
        text: emptyValue,
        selection: TextSelection.collapsed(offset: emptyValue.length),
      );
    }

    // Limita o número máximo de dígitos para evitar overflow
    if (digitsOnly.length > 10) {
      digitsOnly = digitsOnly.substring(0, 10);
    }

    // Adiciona zeros à esquerda apenas se necessário para ter pelo menos decimalDigits dígitos
    while (digitsOnly.length < decimalDigits) {
      digitsOnly = '0$digitsOnly';
    }

    // Separa a parte inteira da decimal
    String integerPart = digitsOnly.substring(0, digitsOnly.length - decimalDigits);
    final decimalPart = digitsOnly.substring(digitsOnly.length - decimalDigits);

    // Remove zeros à esquerda da parte inteira, mas mantém pelo menos um zero
    integerPart = integerPart.replaceFirst(RegExp(r'^0+'), '');
    if (integerPart.isEmpty) {
      integerPart = '0';
    }

    final formatted = '$integerPart.$decimalPart';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 2);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final cents = int.tryParse(digitsOnly) ?? 0;
    final value = cents / 100;

    final formatted = _formatter.format(value);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class MoneyInputFormatterWithoutSymbol extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.currency(locale: 'pt_BR', symbol: '', decimalDigits: 2);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final cents = int.tryParse(digitsOnly) ?? 0;
    final value = cents / 100;

    final formatted = _formatter.format(value).trim();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class CurrencyHelper {
  static double parseFromFormatted(String formattedText) {
    if (formattedText.isEmpty) return 0.0;

    final cleanText = formattedText.replaceAll(RegExp(r'[R\$\s]'), '').replaceAll('.', '').replaceAll(',', '.');

    return double.tryParse(cleanText) ?? 0.0;
  }
}
