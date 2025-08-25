import 'package:flutter/material.dart';
import 'package:validatorless/validatorless.dart';

class UserValidators {
  static final name = Validatorless.multiple([
    Validatorless.required('Nome obrigatório'),
    Validatorless.min(2, 'Nome deve ter pelo menos 2 caracteres'),
    Validatorless.max(50, 'Nome deve ter no máximo 50 caracteres'),
  ]);

  static final email = Validatorless.multiple([
    Validatorless.required('Email obrigatório'),
    Validatorless.email('Email inválido'),
  ]);

  static final password = Validatorless.multiple([
    Validatorless.required('Senha obrigatória'),
    Validatorless.min(6, 'Senha deve ter pelo menos 6 caracteres'),
  ]);

  static FormFieldValidator<String> confirmPassword(TextEditingController passwordEC) {
    return Validatorless.multiple([
      Validatorless.required('Confirmação de senha obrigatória'),
      Validatorless.min(6, 'Senha deve ter pelo menos 6 caracteres'),
      Validatorless.compare(passwordEC, 'As senhas não coincidem'),
    ]);
  }
}
