import 'package:flutter/material.dart';
import 'package:gasosa_app/core/di/locator.dart';
import 'package:gasosa_app/presentation/routes/route_paths.dart';
import 'package:gasosa_app/presentation/screens/refuel/viewmodel/manage_refuel_viewmodel.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_appbar.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_date_picker_field.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_form_field.dart';
import 'package:gasosa_app/theme/app_spacing.dart';
import 'package:go_router/go_router.dart';

class ManageRefuelScreen extends StatefulWidget {
  const ManageRefuelScreen({super.key, this.refuelId});
  final String? refuelId;

  @override
  State<ManageRefuelScreen> createState() => _ManageRefuelScreenState();
}

class _ManageRefuelScreenState extends State<ManageRefuelScreen> {
  late final ManageRefuelViewmodel _viewmodel;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _viewmodel = getIt<ManageRefuelViewmodel>();
    _viewmodel.init(widget.refuelId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GasosaAppbar(
        title: widget.refuelId != null ? 'Editar Abastecimento' : 'Adicionar Abastecimento',
        showBackButton: true,
        // TODO(felipe): navegação voltar corretamente para a tela de detalhes do veículo
        onBackPressed: () => context.go(RoutePaths.dashboard),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingMd,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.md,
              children: [
                GasosaDatePickerField(
                  label: 'Data do Abastecimento',
                  // initialDate: DateTime.now(),
                ),
                GasosaFormField(
                  label: 'KM atual',
                  controller: _viewmodel.mileageEC,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
