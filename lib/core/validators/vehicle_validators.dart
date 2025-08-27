import 'package:validatorless/validatorless.dart';

class VehicleValidators {
  static final name = Validatorless.multiple([
    Validatorless.required('Nome do veículo é obrigatório'),
    Validatorless.min(3, 'Nome deve ter pelo menos 3 caracteres'),
    Validatorless.max(50, 'Nome deve ter no máximo 50 caracteres'),
    Validatorless.regex(RegExp(r'^[a-zA-Z0-9\s]+$'), 'Nome do veículo deve conter apenas caracteres alfanuméricos'),
  ]);

  static final plate = Validatorless.multiple([
    Validatorless.max(7, 'Placa deve ter no máximo 7 caracteres'),
    Validatorless.regex(RegExp(r'^[a-zA-Z0-9]+$'), 'Placa deve conter apenas caracteres alfanuméricos'),
  ]);

  static final tankCapacity = Validatorless.multiple([
    Validatorless.min(1, 'Capacidade do tanque deve ser maior que 0'),
  ]);
}
