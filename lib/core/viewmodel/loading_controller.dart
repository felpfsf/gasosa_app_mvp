import 'package:flutter/material.dart';

class LoadingController extends ChangeNotifier {
  bool _visible = false;
  bool get visible => _visible;

  void show() {
    if (_visible) return;
    _visible = true;
    notifyListeners();
  }

  void hide() {
    if (!_visible) return;
    _visible = false;
    notifyListeners();
  }
}
