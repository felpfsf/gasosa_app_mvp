/// Helper for parsing numeric input from text fields.
/// Handles Brazilian locale (comma as decimal separator) and empty values.
class NumericParser {
  const NumericParser._();

  /// Parses a string to int, handling empty values and Brazilian locale.
  ///
  /// Returns [defaultValue] if:
  /// - Input is null or empty
  /// - Parsing fails
  static int parseInt(String? value, {int defaultValue = 0}) {
    if (value == null || value.trim().isEmpty) {
      return defaultValue;
    }

    final normalized = value.replaceAll(',', '.');
    return int.tryParse(normalized) ?? defaultValue;
  }

  /// Parses a string to double, handling empty values and Brazilian locale.
  ///
  /// Replaces comma with dot for decimal separator.
  /// Returns [defaultValue] if:
  /// - Input is null or empty
  /// - Parsing fails
  static double parseDouble(String? value, {double defaultValue = 0.0}) {
    if (value == null || value.trim().isEmpty) {
      return defaultValue;
    }

    final normalized = value.replaceAll(',', '.');
    return double.tryParse(normalized) ?? defaultValue;
  }

  /// Formats a double to string with Brazilian locale (comma as decimal separator).
  ///
  /// [decimalPlaces] defines the number of decimal places (default: 2).
  static String formatDouble(double value, {int decimalPlaces = 2}) {
    return value.toStringAsFixed(decimalPlaces).replaceAll('.', ',');
  }

  /// Formats an int to string.
  static String formatInt(int value) {
    return value.toString();
  }
}
