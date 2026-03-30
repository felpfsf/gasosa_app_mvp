import 'package:gasosa_app/core/app_strings.dart';
import 'package:validatorless/validatorless.dart';

class VehicleValidators {
  static final name = Validatorless.multiple([
    Validatorless.required(VehicleValidatorStrings.nameRequired),
    Validatorless.min(3, VehicleValidatorStrings.nameTooShort),
    Validatorless.max(50, VehicleValidatorStrings.nameTooLong),
    Validatorless.regex(RegExp(r'^[a-zA-Z0-9\s]+$'), VehicleValidatorStrings.nameInvalidChars),
  ]);

  static final plate = Validatorless.multiple([
    Validatorless.max(7, VehicleValidatorStrings.plateTooLong),
    Validatorless.regex(RegExp(r'^[a-zA-Z0-9]+$'), VehicleValidatorStrings.plateInvalidChars),
  ]);

  static final tankCapacity = Validatorless.multiple([
    Validatorless.min(1, VehicleValidatorStrings.tankCapacityMin),
  ]);
}
