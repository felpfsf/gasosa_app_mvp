abstract class Failure implements Exception {
  const Failure(
    this.message, {
    this.cause,
    this.stackTrace,
  });

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => '$runtimeType: $message';
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, {super.cause, super.stackTrace});
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}
