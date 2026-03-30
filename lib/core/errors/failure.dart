sealed class Failure {
  const Failure(
    this.message,
    this.cause,
    this.stackTrace,
  );

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() {
    return 'Failure(message: $message, cause: $cause, stackTrace: $stackTrace)';
  }
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(
    super.message,
    super.cause,
    super.stackTrace,
  );
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure(
    super.message,
    super.cause,
    super.stackTrace,
  );
}

class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message, null, null);
}
