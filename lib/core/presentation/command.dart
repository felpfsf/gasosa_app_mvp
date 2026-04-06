import 'package:flutter/foundation.dart';
import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/core/presentation/ui_state.dart';

class Command<T> {
  Command({UiState<T>? initialState}) : state = ValueNotifier<UiState<T>>(initialState ?? const UiInitial());

  final ValueNotifier<UiState<T>> state;
  bool _running = false;
  bool _disposed = false;

  /// Runs [action] if no other call is in progress.
  /// Returns null when skipped due to a concurrent execution.
  Future<Either<Failure, T>?> run(
    Future<Either<Failure, T>> Function() action,
  ) async {
    if (_running) return null;
    _running = true;
    if (!_disposed) state.value = const UiLoading();

    try {
      final result = await action();
      if (!_disposed) {
        result.fold(
          (l) => state.value = UiError(l),
          (r) => state.value = UiData(r),
        );
      }
      return result;
    } finally {
      _running = false;
    }
  }

  /// Resets state to [UiInitial], e.g. to dismiss an error.
  void reset() => state.value = const UiInitial();

  void dispose() {
    _disposed = true;
    state.dispose();
  }
}
