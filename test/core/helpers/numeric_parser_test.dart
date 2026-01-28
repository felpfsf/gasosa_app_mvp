import 'package:flutter_test/flutter_test.dart';
import 'package:gasosa_app/core/helpers/numeric_parser.dart';

void main() {
  group('NumericParser - parseInt', () {
    test('parses valid integer string', () {
      expect(NumericParser.parseInt('123'), 123);
      expect(NumericParser.parseInt('0'), 0);
      expect(NumericParser.parseInt('999999'), 999999);
    });

    test('returns default value for null or empty input', () {
      expect(NumericParser.parseInt(null), 0);
      expect(NumericParser.parseInt(''), 0);
      expect(NumericParser.parseInt('   '), 0);
      expect(NumericParser.parseInt(null, defaultValue: 42), 42);
    });

    test('returns default value for invalid input', () {
      expect(NumericParser.parseInt('abc'), 0);
      expect(NumericParser.parseInt('12.5'), 0);
      expect(NumericParser.parseInt('12,5'), 0);
      expect(NumericParser.parseInt('12abc'), 0);
    });

    test('handles whitespace', () {
      expect(NumericParser.parseInt('  123  '), 123);
      expect(NumericParser.parseInt(' 0 '), 0);
    });

    test('uses custom default value', () {
      expect(NumericParser.parseInt('invalid', defaultValue: 100), 100);
      expect(NumericParser.parseInt('', defaultValue: -1), -1);
    });
  });

  group('NumericParser - parseDouble', () {
    test('parses valid double string with dot', () {
      expect(NumericParser.parseDouble('123.45'), 123.45);
      expect(NumericParser.parseDouble('0.0'), 0.0);
      expect(NumericParser.parseDouble('99.99'), 99.99);
    });

    test('parses valid double string with comma (Brazilian locale)', () {
      expect(NumericParser.parseDouble('123,45'), 123.45);
      expect(NumericParser.parseDouble('0,0'), 0.0);
      expect(NumericParser.parseDouble('99,99'), 99.99);
    });

    test('parses integer as double', () {
      expect(NumericParser.parseDouble('123'), 123.0);
      expect(NumericParser.parseDouble('0'), 0.0);
    });

    test('returns default value for null or empty input', () {
      expect(NumericParser.parseDouble(null), 0.0);
      expect(NumericParser.parseDouble(''), 0.0);
      expect(NumericParser.parseDouble('   '), 0.0);
      expect(NumericParser.parseDouble(null, defaultValue: 42.5), 42.5);
    });

    test('returns default value for invalid input', () {
      expect(NumericParser.parseDouble('abc'), 0.0);
      expect(NumericParser.parseDouble('12.5.6'), 0.0);
      expect(NumericParser.parseDouble('12abc'), 0.0);
    });

    test('handles whitespace', () {
      expect(NumericParser.parseDouble('  123.45  '), 123.45);
      expect(NumericParser.parseDouble(' 0,5 '), 0.5);
    });

    test('uses custom default value', () {
      expect(NumericParser.parseDouble('invalid', defaultValue: 100.5), 100.5);
      expect(NumericParser.parseDouble('', defaultValue: -1.5), -1.5);
    });
  });

  group('NumericParser - formatDouble', () {
    test('formats double with comma as decimal separator', () {
      expect(NumericParser.formatDouble(123.45), '123,45');
      expect(NumericParser.formatDouble(0.0), '0,00');
      expect(NumericParser.formatDouble(99.99), '99,99');
    });

    test('formats with custom decimal places', () {
      expect(NumericParser.formatDouble(123.456, decimalPlaces: 3), '123,456');
      expect(NumericParser.formatDouble(123.4, decimalPlaces: 1), '123,4');
      expect(NumericParser.formatDouble(123.0, decimalPlaces: 0), '123');
    });

    test('rounds to specified decimal places', () {
      expect(NumericParser.formatDouble(123.456), '123,46');
      expect(NumericParser.formatDouble(123.454), '123,45');
    });
  });

  group('NumericParser - formatInt', () {
    test('formats integer to string', () {
      expect(NumericParser.formatInt(123), '123');
      expect(NumericParser.formatInt(0), '0');
      expect(NumericParser.formatInt(999999), '999999');
    });

    test('handles negative numbers', () {
      expect(NumericParser.formatInt(-123), '-123');
    });
  });
}
