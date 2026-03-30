import 'package:flutter/material.dart';
import 'package:gasosa_app/core/app_strings.dart';
import 'package:validatorless/validatorless.dart';

class UserValidators {
  static final name = Validatorless.multiple([
    Validatorless.required(UserValidatorStrings.nameRequired),
    Validatorless.min(2, UserValidatorStrings.nameTooShort),
    Validatorless.max(50, UserValidatorStrings.nameTooLong),
  ]);

  static final email = Validatorless.multiple([
    Validatorless.required(UserValidatorStrings.emailRequired),
    Validatorless.email(UserValidatorStrings.emailInvalid),
  ]);

  static final password = Validatorless.multiple([
    Validatorless.required(UserValidatorStrings.passwordRequired),
    Validatorless.min(6, UserValidatorStrings.passwordTooShort),
  ]);

  static FormFieldValidator<String> confirmPassword(TextEditingController passwordEC) {
    return Validatorless.multiple([
      Validatorless.required(UserValidatorStrings.confirmPasswordRequired),
      Validatorless.min(6, UserValidatorStrings.passwordTooShort),
      Validatorless.compare(passwordEC, UserValidatorStrings.confirmPasswordMismatch),
    ]);
  }
}
