import 'package:flutter/material.dart';
import 'package:gasosa_app/core/viewmodel/loading_controller.dart';

abstract class BaseViewModel extends ChangeNotifier {
  BaseViewModel(this._loading);
  final LoadingController _loading;

  /// Cada VM define como refletir o loading no seu `state` local.
  @protected
  void setViewLoading({bool value});

  /// Envolve uma operação assíncrona ativando/desativando:
  /// - loader global (overlay);
  /// - loading local (state.isLoading).
  Future<T> track<T>(Future<T> Function() op) async {
    setViewLoading(value: true);
    _loading.show();
    try {
      return await op();
    } finally {
      setViewLoading(value: false);
      _loading.hide();
    }
  }
}
