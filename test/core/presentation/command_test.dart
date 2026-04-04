import 'package:flutter_test/flutter_test.dart';
import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/core/presentation/command.dart';
import 'package:gasosa_app/core/presentation/ui_state.dart';

void main() {
  // ─── Estado inicial ───────────────────────────────────────────────────────

  group('Command - estado inicial', () {
    test('estado inicial é UiInitial por padrão', () {
      final cmd = Command<int>();
      expect(cmd.state.value, isA<UiInitial>());
      cmd.dispose();
    });

    test('estado inicial pode ser customizado', () {
      final cmd = Command<int>(initialState: const UiData(42));
      expect(cmd.state.value, const UiData(42));
      cmd.dispose();
    });
  });

  // ─── run() — caminho feliz ────────────────────────────────────────────────

  group('Command.run() - sucesso', () {
    test('estado vai para UiLoading durante execução', () async {
      final cmd = Command<int>();
      final states = <UiState<int>>[];
      cmd.state.addListener(() => states.add(cmd.state.value));

      await cmd.run(() async {
        await Future<void>.delayed(Duration.zero);
        return right(1);
      });

      expect(states.first, isA<UiLoading>());
      cmd.dispose();
    });

    test('estado vai para UiData após sucesso', () async {
      final cmd = Command<int>();

      await cmd.run(() async => right(42));

      expect(cmd.state.value, const UiData(42));
      cmd.dispose();
    });

    test('retorna Right com o valor correto', () async {
      final cmd = Command<int>();
      final result = await cmd.run(() async => right(7));
      expect(result?.isRight, isTrue);
      expect((result! as Right).value, 7);
      cmd.dispose();
    });
  });

  // ─── run() — caminho de erro ──────────────────────────────────────────────

  group('Command.run() - falha', () {
    test('estado vai para UiError quando action retorna Left', () async {
      final cmd = Command<int>();
      const failure = ValidationFailure('erro de validação');

      await cmd.run(() async => const Left(failure));

      expect(cmd.state.value, isA<UiError>());
      expect((cmd.state.value as UiError).failure, failure);
      cmd.dispose();
    });

    test('retorna Left quando action falha', () async {
      final cmd = Command<int>();
      const failure = DatabaseFailure('db error', null, null);

      final result = await cmd.run(() async => const Left(failure));

      expect(result?.isLeft, isTrue);
      cmd.dispose();
    });

    test('estado volta a não-running após falha', () async {
      final cmd = Command<int>();
      await cmd.run(() async => const Left(ValidationFailure('err')));

      // Se _running fosse true, este run seria ignorado (retornaria null)
      final result = await cmd.run(() async => right(99));
      expect(result, isNotNull);
      expect(cmd.state.value, const UiData(99));
      cmd.dispose();
    });
  });

  // ─── Concorrência ────────────────────────────────────────────────────────

  group('Command.run() - concorrência', () {
    test('segunda chamada simultânea retorna null', () async {
      final cmd = Command<int>();
      Either<Failure, int>? secondResult;

      // Inicia primeira chamada sem await
      final first = cmd.run(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return right(1);
      });

      // Tenta segunda chamada imediatamente
      secondResult = await cmd.run(() async => right(2));

      await first;

      expect(secondResult, isNull); // segunda foi bloqueada
      expect(cmd.state.value, const UiData(1)); // apenas a primeira concluiu
      cmd.dispose();
    });

    test('após conclusão aceita nova chamada', () async {
      final cmd = Command<int>();
      await cmd.run(() async => right(1));
      final result = await cmd.run(() async => right(2));
      expect(result, isNotNull);
      expect(cmd.state.value, const UiData(2));
      cmd.dispose();
    });
  });

  // ─── reset() ─────────────────────────────────────────────────────────────

  group('Command.reset()', () {
    test('volta estado para UiInitial', () async {
      final cmd = Command<int>();
      await cmd.run(() async => const Left(ValidationFailure('err')));
      expect(cmd.state.value, isA<UiError>());

      cmd.reset();

      expect(cmd.state.value, isA<UiInitial>());
      cmd.dispose();
    });
  });
}
