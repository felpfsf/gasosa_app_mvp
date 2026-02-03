import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasosa_app/core/errors/failure.dart';

/// Matcher customizado para Either<Failure, T> - verifica se é Right
Matcher isRight() => _IsRight();

/// Matcher customizado para Either<Failure, T> - verifica se é Left
Matcher isLeft() => _IsLeft();

/// Matcher customizado para Either<Failure, T> - verifica se Right contém valor específico
Matcher isRightWith<T>(T value) => _IsRightWith<T>(value);

/// Matcher customizado para Either<Failure, T> - verifica se Left contém Failure do tipo especificado
Matcher isLeftWith<F extends Failure>() => _IsLeftWith<F>();

/// Matcher customizado para Either<Failure, T> - verifica se Left contém Failure com mensagem específica
Matcher isLeftWithMessage(String message) => _IsLeftWithMessage(message);

class _IsRight extends Matcher {
  @override
  bool matches(dynamic item, Map matchState) {
    if (item is Either) {
      return item.isRight();
    }
    return false;
  }

  @override
  Description describe(Description description) {
    return description.add('is Right');
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (item is Either) {
      return mismatchDescription.add('was Left');
    }
    return mismatchDescription.add('is not an Either');
  }
}

class _IsLeft extends Matcher {
  @override
  bool matches(dynamic item, Map matchState) {
    if (item is Either) {
      return item.isLeft();
    }
    return false;
  }

  @override
  Description describe(Description description) {
    return description.add('is Left');
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (item is Either) {
      return mismatchDescription.add('was Right');
    }
    return mismatchDescription.add('is not an Either');
  }
}

class _IsRightWith<T> extends Matcher {
  _IsRightWith(this.expectedValue);

  final T expectedValue;

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is Either) {
      return item.fold(
        (l) => false,
        (r) => r == expectedValue,
      );
    }
    return false;
  }

  @override
  Description describe(Description description) {
    return description.add('is Right with value $expectedValue');
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (item is Either) {
      return item.fold(
        (l) => mismatchDescription.add('was Left with $l'),
        (r) => mismatchDescription.add('was Right with $r but expected $expectedValue'),
      );
    }
    return mismatchDescription.add('is not an Either');
  }
}

class _IsLeftWith<F extends Failure> extends Matcher {
  @override
  bool matches(dynamic item, Map matchState) {
    if (item is Either) {
      return item.fold(
        (l) => l is F,
        (r) => false,
      );
    }
    return false;
  }

  @override
  Description describe(Description description) {
    return description.add('is Left with $F');
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (item is Either) {
      return item.fold(
        (l) => mismatchDescription.add('was Left with ${l.runtimeType} but expected $F'),
        (r) => mismatchDescription.add('was Right with $r'),
      );
    }
    return mismatchDescription.add('is not an Either');
  }
}

class _IsLeftWithMessage extends Matcher {
  _IsLeftWithMessage(this.expectedMessage);

  final String expectedMessage;

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is Either) {
      return item.fold(
        (l) => l.message.contains(expectedMessage),
        (r) => false,
      );
    }
    return false;
  }

  @override
  Description describe(Description description) {
    return description.add('is Left with message containing "$expectedMessage"');
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (item is Either) {
      return item.fold(
        (l) => mismatchDescription.add('was Left with message "${l.message}"'),
        (r) => mismatchDescription.add('was Right with $r'),
      );
    }
    return mismatchDescription.add('is not an Either');
  }
}

/// Helper para extrair valor Right de Either ou falhar o teste
T rightValue<T>(Either<Failure, T> either) {
  return either.fold(
    (failure) => throw TestFailure('Expected Right but got Left with: $failure'),
    (value) => value,
  );
}

/// Helper para extrair Failure de Left ou falhar o teste
Failure leftFailure<T>(Either<Failure, T> either) {
  return either.fold(
    (failure) => failure,
    (value) => throw TestFailure('Expected Left but got Right with: $value'),
  );
}

/// Helper para criar delay assíncrono nos testes
Future<void> delay([Duration duration = const Duration(milliseconds: 100)]) {
  return Future.delayed(duration);
}
