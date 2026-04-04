import 'package:flutter_test/flutter_test.dart';
import 'package:gasosa_app/core/either/either.dart';

void main() {
  // ─── Left ────────────────────────────────────────────────────────────────

  group('Left', () {
    test('isLeft returns true', () {
      const Either<String, int> e = Left('error');
      expect(e.isLeft, isTrue);
    });

    test('isRight returns false', () {
      const Either<String, int> e = Left('error');
      expect(e.isRight, isFalse);
    });

    test('fold calls leftFn', () {
      const Either<String, int> e = Left('error');
      final result = e.fold((l) => 'got: $l', (r) => 'wrong');
      expect(result, 'got: error');
    });

    test('map preserves Left without calling fn', () {
      const Either<String, int> e = Left('error');
      final mapped = e.map((r) => r * 2);
      expect(mapped.isLeft, isTrue);
      expect((mapped as Left).value, 'error');
    });

    test('flatMap preserves Left without calling fn', () {
      const Either<String, int> e = Left('error');
      final result = e.flatMap((r) => Right<String, int>(r * 2));
      expect(result.isLeft, isTrue);
      expect((result as Left).value, 'error');
    });

    test('getOrElse returns fallback value', () {
      const Either<String, int> e = Left('error');
      final value = e.getOrElse((_) => -1);
      expect(value, -1);
    });

    test('equality: two Left with same value are equal', () {
      expect(const Left<String, int>('err'), equals(const Left<String, int>('err')));
    });

    test('equality: two Left with different values are not equal', () {
      expect(const Left<String, int>('a'), isNot(equals(const Left<String, int>('b'))));
    });

    test('hashCode matches value hashCode', () {
      const l = Left<String, int>('err');
      expect(l.hashCode, 'err'.hashCode);
    });
  });

  // ─── Right ───────────────────────────────────────────────────────────────

  group('Right', () {
    test('isRight returns true', () {
      const Either<String, int> e = Right(42);
      expect(e.isRight, isTrue);
    });

    test('isLeft returns false', () {
      const Either<String, int> e = Right(42);
      expect(e.isLeft, isFalse);
    });

    test('fold calls rightFn', () {
      const Either<String, int> e = Right(42);
      final result = e.fold((l) => 'wrong', (r) => 'got: $r');
      expect(result, 'got: 42');
    });

    test('map transforms value', () {
      const Either<String, int> e = Right(10);
      final mapped = e.map((r) => r * 3);
      expect(mapped.isRight, isTrue);
      expect((mapped as Right).value, 30);
    });

    test('flatMap chains to another Right', () {
      const Either<String, int> e = Right(10);
      final result = e.flatMap((r) => Right<String, String>('value: $r'));
      expect(result.isRight, isTrue);
      expect((result as Right).value, 'value: 10');
    });

    test('flatMap can chain to Left', () {
      const Either<String, int> e = Right(10);
      final result = e.flatMap<String>((_) => const Left('chained error'));
      expect(result.isLeft, isTrue);
      expect((result as Left).value, 'chained error');
    });

    test('getOrElse returns the right value', () {
      const Either<String, int> e = Right(99);
      final value = e.getOrElse((_) => -1);
      expect(value, 99);
    });

    test('equality: two Right with same value are equal', () {
      expect(const Right<String, int>(1), equals(const Right<String, int>(1)));
    });

    test('equality: two Right with different values are not equal', () {
      expect(const Right<String, int>(1), isNot(equals(const Right<String, int>(2))));
    });

    test('hashCode matches value hashCode', () {
      const r = Right<String, int>(42);
      expect(r.hashCode, 42.hashCode);
    });
  });

  // ─── Helpers ─────────────────────────────────────────────────────────────

  group('left / right helpers', () {
    test('left() creates a Left', () {
      final e = left<String, int>('err');
      expect(e.isLeft, isTrue);
    });

    test('right() creates a Right', () {
      final e = right<String, int>(1);
      expect(e.isRight, isTrue);
    });
  });
}
