import 'package:meta/meta.dart';

sealed class Either<L, R> {
  const Either();

  T fold<T>(T Function(L l) leftFn, T Function(R r) rightFn);

  bool get isLeft => this is Left<L, R>;
  bool get isRight => this is Right<L, R>;

  Either<L, R2> map<R2>(R2 Function(R r) fn) => fold(Left.new, (r) => Right(fn(r)));

  Either<L, R2> flatMap<R2>(Either<L, R2> Function(R r) fn) => fold(Left.new, fn);

  R getOrElse(R Function(L l) fallback) => fold(fallback, (r) => r);
}

@immutable
final class Left<L, R> extends Either<L, R> {
  const Left(this.value);

  final L value;

  @override
  T fold<T>(T Function(L l) leftFn, T Function(R r) rightFn) => leftFn(value);

  @override
  bool operator ==(Object other) => other is Left<L, R> && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

@immutable
final class Right<L, R> extends Either<L, R> {
  const Right(this.value);

  final R value;

  @override
  T fold<T>(T Function(L l) leftFn, T Function(R r) rightFn) => rightFn(value);

  @override
  bool operator ==(Object other) => other is Right<L, R> && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// Tipo unitário — substituto sem dependência do dartz.
@immutable
final class Unit {
  const Unit._();
}

/// Única instância de [Unit].
const unit = Unit._();

/// Constrói um [Left] de forma concisa.
Either<L, R> left<L, R>(L value) => Left(value);

/// Constrói um [Right] de forma concisa.
Either<L, R> right<L, R>(R value) => Right(value);
