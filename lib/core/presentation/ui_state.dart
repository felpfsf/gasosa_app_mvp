import 'package:gasosa_app/core/errors/failure.dart';
import 'package:meta/meta.dart';

sealed class UiState<T> {
  const UiState();
}

final class UiInitial<T> extends UiState<T> {
  const UiInitial();
}

final class UiLoading<T> extends UiState<T> {
  const UiLoading();
}

@immutable
final class UiData<T> extends UiState<T> {
  const UiData(this.data);

  final T data;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UiData<T> && other.data == data;

  @override
  int get hashCode => data.hashCode;
}

@immutable
final class UiError<T> extends UiState<T> {
  const UiError(this.failure);

  final Failure failure;

  String get message => failure.message;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UiError<T> && other.failure == failure;

  @override
  int get hashCode => failure.hashCode;
}
