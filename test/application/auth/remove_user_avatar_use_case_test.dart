import 'package:flutter_test/flutter_test.dart';
import 'package:gasosa_app/application/auth/remove_user_avatar_use_case.dart';
import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/domain/services/auth_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mock_repositories.dart';
import '../../helpers/mock_services.dart';
import '../../helpers/mock_use_cases.dart';
import '../../helpers/test_helpers.dart';

void main() {
  late MockAuthService mockAuth;
  late MockUserRepository mockUserRepository;
  late MockDeletePhotoUseCase mockDeletePhoto;
  late MockObservabilityService mockObservability;
  late RemoveUserAvatarUseCase useCase;

  const tUser = AuthUser('user-123', 'João', 'joao@email.com');
  const tUserWithPhoto = AuthUser('user-123', 'João', 'joao@email.com', photoUrl: '/storage/avatar.jpg');
  final tFailure = const DatabaseFailure('Erro no banco', null, null);

  setUpAll(() {
    registerFallbackValue(const DatabaseFailure('', null, null));
    registerFallbackValue(const UnexpectedFailure('', null, null));
    registerFallbackValue(const AuthUser('', '', ''));
  });

  setUp(() {
    mockAuth = MockAuthService();
    mockUserRepository = MockUserRepository();
    mockDeletePhoto = MockDeletePhotoUseCase();
    mockObservability = MockObservabilityService();

    useCase = RemoveUserAvatarUseCase(
      auth: mockAuth,
      userRepository: mockUserRepository,
      deletePhoto: mockDeletePhoto,
      observability: mockObservability,
    );

    when(() => mockObservability.logBreadcrumb(any())).thenReturn(null);
    when(() => mockObservability.logEvent(any(), parameters: any(named: 'parameters'))).thenAnswer((_) async {});
    when(
      () => mockObservability.logError(
        any(),
        stackTrace: any(named: 'stackTrace'),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async {});
  });

  group('RemoveUserAvatarUseCase -', () {
    group('sucesso', () {
      setUp(() {
        when(() => mockAuth.currentUser()).thenAnswer((_) async => tUser);
        when(() => mockUserRepository.getUserById(any())).thenAnswer((_) async => right(tUserWithPhoto));
        when(() => mockDeletePhoto(any())).thenAnswer((_) async => right(null));
        when(() => mockUserRepository.saveUser(any())).thenAnswer((_) async => right(unit));
      });

      test('retorna Right quando remoção bem-sucedida', () async {
        final result = await useCase();

        expect(result, isRight());
      });

      test('chama updatePhotoPath com null para limpar foto', () async {
        await useCase();

        verify(() => mockUserRepository.saveUser(any())).called(1);
      });

      test('chama deletePhoto com path correto', () async {
        await useCase();

        verify(() => mockDeletePhoto('/storage/avatar.jpg')).called(1);
      });

      test('registra evento de sucesso', () async {
        await useCase();

        verify(() => mockObservability.logEvent('remove_avatar_success')).called(1);
      });
    });

    group('sem foto para remover', () {
      setUp(() {
        when(() => mockAuth.currentUser()).thenAnswer((_) async => tUser);
        when(() => mockUserRepository.getUserById(any())).thenAnswer(
          (_) async => right(const AuthUser('user-123', 'João', 'joao@email.com')),
        );
        when(() => mockUserRepository.saveUser(any())).thenAnswer((_) async => right(unit));
      });

      test('retorna Right mesmo sem foto salva', () async {
        final result = await useCase();

        expect(result, isRight());
      });

      test('não chama deletePhoto quando photoUrl é null/vazio', () async {
        await useCase();

        verifyNever(() => mockDeletePhoto(any()));
      });
    });

    group('falha silenciosa ao deletar arquivo', () {
      setUp(() {
        when(() => mockAuth.currentUser()).thenAnswer((_) async => tUser);
        when(() => mockUserRepository.getUserById(any())).thenAnswer((_) async => right(tUserWithPhoto));
        // deletePhoto falha, mas deve ser ignorado
        when(
          () => mockDeletePhoto(any()),
        ).thenAnswer((_) async => left(const UnexpectedFailure('Arquivo não encontrado', null, null)));
        when(() => mockUserRepository.saveUser(any())).thenAnswer((_) async => right(unit));
      });

      test('retorna Right mesmo quando deletePhoto falha', () async {
        final result = await useCase();

        expect(result, isRight());
      });

      test('ainda chama updatePhotoPath mesmo com erro no deletePhoto', () async {
        await useCase();

        verify(() => mockUserRepository.saveUser(any())).called(1);
      });
    });

    group('falha - usuário não autenticado', () {
      setUp(() {
        when(() => mockAuth.currentUser()).thenAnswer((_) async => null);
      });

      test('retorna Left quando não há usuário logado', () async {
        final result = await useCase();

        expect(result, isLeft());
      });

      test('não chama updatePhotoPath quando não autenticado', () async {
        await useCase();

        verifyNever(() => mockUserRepository.saveUser(any()));
      });
    });

    group('falha - erro ao persistir no repositório', () {
      setUp(() {
        when(() => mockAuth.currentUser()).thenAnswer((_) async => tUser);
        when(() => mockUserRepository.getUserById(any())).thenAnswer((_) async => right(tUserWithPhoto));
        when(() => mockDeletePhoto(any())).thenAnswer((_) async => right(null));
        when(() => mockUserRepository.saveUser(any())).thenAnswer((_) async => left(tFailure));
      });

      test('retorna Left quando updatePhotoPath falha', () async {
        final result = await useCase();

        expect(result, isLeft());
        expect(leftFailure(result).message, tFailure.message);
      });

      test('registra evento de falha quando persist falha', () async {
        await useCase();

        verify(() => mockObservability.logEvent('remove_avatar_failure')).called(1);
      });
    });
  });
}
