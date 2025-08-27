import 'package:flutter/services.dart';

class DigitDecimalInputFormatter extends TextInputFormatter {
  DigitDecimalInputFormatter({this.decimalDigits = 2})
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
