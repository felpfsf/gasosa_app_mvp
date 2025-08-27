import 'package:flutter/material.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_confirm_dialog.dart';

Future<bool> showDeleteVehicleConfirmDialog(BuildContext context, {String? vehicleName}) {
  const String title = 'Excluir veículo';
  final message = [
    if (vehicleName != null && vehicleName.isNotEmpty) 'Tem certeza que deseja excluir o veículo "$vehicleName"?',
    'Essa ação também removerá todos os abastecimentos vinculados a este veículo.',
    'Esta ação não pode ser desfeita.',
  ].join('\n\n');

  return showGasosaConfirmDialog(
    context,
    title: title,
    content: message,
    confirmLabel: 'Excluir',
    danger: true,
  );
}
