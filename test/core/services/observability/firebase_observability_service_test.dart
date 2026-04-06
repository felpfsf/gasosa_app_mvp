import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/core/services/observability/firebase_observability_service.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseCrashlytics extends Mock implements FirebaseCrashlytics {}

class MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

void main() {
  late MockFirebaseCrashlytics crashlytics;
  late MockFirebaseAnalytics analytics;
  late FirebaseObservabilityService sut;

  setUp(() {
    crashlytics = MockFirebaseCrashlytics();
    analytics = MockFirebaseAnalytics();
    sut = FirebaseObservabilityService(
      crashlytics: crashlytics,
      analytics: analytics,
    );

    // Stubs padrão para métodos void/future usados nos testes
    when(() => crashlytics.setCustomKey(any(), any())).thenAnswer((_) async {});
    when(() => crashlytics.recordError(any(), any(), reason: any(named: 'reason'))).thenAnswer((_) async {});
    when(() => crashlytics.log(any())).thenAnswer((_) async {});
    when(() => crashlytics.setUserIdentifier(any())).thenAnswer((_) async {});
    when(() => analytics.setUserId(id: any(named: 'id'))).thenAnswer((_) async {});
    when(
      () => analytics.logEvent(
        name: any(named: 'name'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) async {});
  });

  group('setCustomKey - sanitização de PII', () {
    test('deve ignorar key "email"', () {
      sut.setCustomKey('email', 'user@example.com');
      verifyNever(() => crashlytics.setCustomKey('email', any()));
    });

    test('deve ignorar key "name"', () {
      sut.setCustomKey('name', 'John Doe');
      verifyNever(() => crashlytics.setCustomKey('name', any()));
    });

    test('deve ignorar key "plate"', () {
      sut.setCustomKey('plate', 'ABC1234');
      verifyNever(() => crashlytics.setCustomKey('plate', any()));
    });

    test('deve ignorar key "token"', () {
      sut.setCustomKey('token', 'secret-token');
      verifyNever(() => crashlytics.setCustomKey('token', any()));
    });

    test('deve ignorar key contendo "password"', () {
      sut.setCustomKey('userPassword', 'secret');
      verifyNever(() => crashlytics.setCustomKey(any(), any()));
    });

    test('deve permitir key segura como "action"', () {
      sut.setCustomKey('action', 'login');
      verify(() => crashlytics.setCustomKey('action', 'login')).called(1);
    });

    test('deve permitir key segura como "route"', () {
      sut.setCustomKey('route', '/dashboard');
      verify(() => crashlytics.setCustomKey('route', '/dashboard')).called(1);
    });

    test('deve permitir key segura como "vehicleId"', () {
      sut.setCustomKey('vehicleId', 'abc-123');
      verify(() => crashlytics.setCustomKey('vehicleId', 'abc-123')).called(1);
    });
  });

  group('logError', () {
    test('deve registrar failure_type via setCustomKey', () async {
      final failure = DatabaseFailure('db error', null, null);

      await sut.logError(failure);

      verify(() => crashlytics.setCustomKey('failure_type', 'DatabaseFailure')).called(1);
    });

    test('NÃO deve registrar failure_message como custom key (bug fix de PII)', () async {
      final failure = DatabaseFailure('mensagem sensível', null, null);

      await sut.logError(failure);

      verifyNever(() => crashlytics.setCustomKey('failure_message', any()));
    });

    test('deve enviar como non-fatal via recordError', () async {
      final failure = UnexpectedFailure('unexpected', null, null);

      await sut.logError(failure);

      verify(
        () => crashlytics.recordError(
          failure,
          any(),
          reason: any(named: 'reason'),
        ),
      ).called(1);
    });

    test('deve sanitizar contexto antes de registrar custom keys', () async {
      final failure = DatabaseFailure('error', null, null);

      await sut.logError(failure, context: {'action': 'save', 'email': 'user@test.com'});

      verify(() => crashlytics.setCustomKey('action', 'save')).called(1);
      verifyNever(() => crashlytics.setCustomKey('email', any()));
    });
  });

  group('logEvent', () {
    test('deve enviar evento com parâmetros seguros', () async {
      await sut.logEvent('login_success', parameters: {'method': 'email'});

      verify(
        () => analytics.logEvent(
          name: 'login_success',
          parameters: {'method': 'email'},
        ),
      ).called(1);
    });

    test('deve remover PII dos parâmetros antes de enviar', () async {
      await sut.logEvent(
        'register_attempt',
        parameters: {
          'method': 'email',
          'email': 'user@test.com',
          'name': 'John',
        },
      );

      verify(
        () => analytics.logEvent(
          name: 'register_attempt',
          parameters: {'method': 'email'},
        ),
      ).called(1);
    });

    test('deve enviar evento sem parâmetros quando todos são PII', () async {
      await sut.logEvent('event', parameters: {'email': 'user@test.com', 'name': 'John'});

      verify(() => analytics.logEvent(name: 'event', parameters: {})).called(1);
    });
  });

  group('logBreadcrumb', () {
    test('deve registrar mensagem no Crashlytics', () {
      sut.logBreadcrumb('navigation_push', data: {'route': '/dashboard'});

      verify(() => crashlytics.log(any())).called(1);
    });

    test('deve sanitizar data antes de logar', () {
      sut.logBreadcrumb('action', data: {'route': '/home', 'email': 'user@test.com'});

      // Verifica que o breadcrumb foi logado sem incluir email
      final captured = verify(() => crashlytics.log(captureAny())).captured.single as String;
      expect(captured, contains('route=/home'));
      expect(captured, isNot(contains('email')));
    });

    test('deve truncar breadcrumb com mais de 512 caracteres', () {
      final longData = {'key': 'x' * 600};

      sut.logBreadcrumb('msg', data: longData);

      final captured = verify(() => crashlytics.log(captureAny())).captured.single as String;
      expect(captured.length, lessThanOrEqualTo(512));
    });
  });

  group('setUserId', () {
    test('deve definir userId em Crashlytics e Analytics', () async {
      sut.setUserId('user-uuid-123');

      verify(() => crashlytics.setUserIdentifier('user-uuid-123')).called(1);
      verify(() => analytics.setUserId(id: 'user-uuid-123')).called(1);
    });

    test('deve limpar userId passando string vazia ao Crashlytics', () async {
      sut.setUserId(null);

      verify(() => crashlytics.setUserIdentifier('')).called(1);
      verify(() => analytics.setUserId(id: null)).called(1);
    });
  });
}
