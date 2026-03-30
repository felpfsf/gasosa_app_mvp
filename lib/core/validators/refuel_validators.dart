import 'package:gasosa_app/core/app_strings.dart';
import 'package:gasosa_app/domain/entities/fuel_type.dart';
import 'package:validatorless/validatorless.dart';

class RefuelValidators {
  static final liters = Validatorless.multiple([
    Validatorless.required(RefuelValidatorStrings.litersRequired),
    Validatorless.min(1, RefuelValidatorStrings.litersTooLow),
    Validatorless.max(100, RefuelValidatorStrings.litersTooHigh),
  ]);

  static final totalValue = Validatorless.multiple([
    Validatorless.required(RefuelValidatorStrings.totalValueRequired),
    Validatorless.min(0_01, RefuelValidatorStrings.totalValueTooLow),
  ]);

  static final mileage = Validatorless.multiple([
    Validatorless.required(RefuelValidatorStrings.mileageRequired),
    Validatorless.min(0, RefuelValidatorStrings.mileageTooLow),
    Validatorless.max(1_000_000, RefuelValidatorStrings.mileageTooHigh),
  ]);

  static final coldStartLiters = Validatorless.multiple([
    Validatorless.required(RefuelValidatorStrings.coldStartLitersRequired),
    Validatorless.min(0, RefuelValidatorStrings.coldStartLitersTooLow),
    Validatorless.max(100, RefuelValidatorStrings.coldStartLitersTooHigh),
  ]);

  static final coldStartValue = Validatorless.multiple([
    Validatorless.required(RefuelValidatorStrings.coldStartValueRequired),
    Validatorless.min(0_01, RefuelValidatorStrings.coldStartValueTooLow),
  ]);

  static String? fuelType(FuelType? value) {
    if (value == null) return RefuelValidatorStrings.fuelTypeRequired;
    return null;
  }

  static String? date(DateTime? date) {
    if (date == null) return RefuelValidatorStrings.dateRequired;
    return null;
  }
}
