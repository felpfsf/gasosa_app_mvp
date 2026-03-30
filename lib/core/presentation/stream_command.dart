import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/core/presentation/ui_state.dart';

class StreamCommand<T> {
  StreamCommand({UiState<T>? initialState}) : state = ValueNotifier<UiState<T>>(initialState ?? const UiInitial());

  final ValueNotifier<UiState<T>> state;
  StreamSubscription<T>? _sub;

  /// Subscribes to [stream].
  /// If [keepLastData] is true and data is already displayed, skips the
  /// UiLoading flash and keeps showing the previous data while reloading.
  void watch(Stream<T> Function() stream, {bool keepLastData = false}) {
    final shouldShowLoading = !keepLastData || state.value is! UiData<T>;
    if (shouldShowLoading) state.value = const UiLoading();

    _sub?.cancel();
    _sub = stream().listen(
      (data) => state.value = UiData(data),
      onError: (Object e, StackTrace st) =>
          state.value = e is Failure ? UiError(e) : UiError(UnexpectedFailure(e.toString(), e, st)),
    );
  }

  /// Cancels the subscription and moves to [UiInitial] if still loading.
  void cancel() {
    _sub?.cancel();
    _sub = null;
    if (state.value is UiLoading) state.value = const UiInitial();
  }

  void dispose() {
    cancel();
    state.dispose();
  }
}
