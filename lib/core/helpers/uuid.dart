import 'package:uuid/uuid.dart';

class UuidHelper {
  static const _uuid = Uuid();

  static String generate() => _uuid.v4();

  static bool isValid(String value) {
    try {
      Uuid.parse(value);
      return true;
    } catch (e) {
      return false;
    }
  }
}
