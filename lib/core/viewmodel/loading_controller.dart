import 'package:flutter/material.dart';

class LoadingController extends ChangeNotifier {
  int _count = 0;
  bool get isLoading => _count > 0;

  void show() {
    _count++;
    notifyListeners();
  }

  void hide() {
    if (_count > 0) {
      _count--;
      notifyListeners();
    }
  }

  Future<T> track<T>(Future<T> Function() action) async {
    show();
    try {
      return await action();
    } finally {
      hide();
    }
  }
}
