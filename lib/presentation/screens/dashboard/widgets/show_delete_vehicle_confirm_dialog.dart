import 'package:flutter/material.dart';
import 'package:gasosa_app/core/app_strings.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_confirm_dialog.dart';

Future<bool> showDeleteVehicleConfirmDialog(BuildContext context, {String? vehicleName}) {
  return showGasosaConfirmDialog(
    context,
    title: VehicleStrings.deleteDialogTitle,
    content: VehicleStrings.deleteDialogMessage(vehicleName),
    confirmLabel: VehicleStrings.deleteDialogConfirmLabel,
    danger: true,
  );
}
