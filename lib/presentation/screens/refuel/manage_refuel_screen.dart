import 'package:flutter/material.dart';
import 'package:gasosa_app/presentation/routes/route_paths.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_appbar.dart';
import 'package:gasosa_app/theme/app_spacing.dart';
import 'package:go_router/go_router.dart';

class ManageRefuelScreen extends StatefulWidget {
  const ManageRefuelScreen({super.key, this.refuelId});
  final String? refuelId;

  @override
  State<ManageRefuelScreen> createState() => _ManageRefuelScreenState();
}

class _ManageRefuelScreenState extends State<ManageRefuelScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GasosaAppbar(
        title: widget.refuelId != null ? 'Editar Abastecimento' : 'Adicionar Abastecimento',
        showBackButton: true,
        onBackPressed: () => context.go(RoutePaths.dashboard),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.md,
              children: [],
            ),
          ),
        ),
      ),
    );
  }
}
