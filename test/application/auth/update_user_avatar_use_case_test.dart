import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gasosa_app/application/auth/update_user_avatar_use_case.dart';
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
  late MockSavePhotoUseCase mockSavePhoto;
  late MockObservabilityService mockObservability;
  late UpdateUserAvatarUseCase useCase;

  const tUser = AuthUser('user-123', 'João', 'joao@email.com');
  final tFailure = const DatabaseFailure('Erro no banco', null, null);

  setUpAll(() {
    registerFallbackValue(File('/tmp/fake.jpg'));
    registerFallbackValue(const DatabaseFailure('', null, null));
    registerFallbackValue(const UnexpectedFailure('', null, null));
    registerFallbackValue(const AuthUser('', '', ''));
  });

  setUp(() {
    mockAuth = MockAuthService();
    mockUserRepository = MockUserRepository();
    mockSavePhoto = MockSavePhotoUseCase();
    mockObservability = MockObservabilityService();

    useCase = UpdateUserAvatarUseCase(
      auth: mockAuth,
      userRepository: mockUserRepository,
      savePhoto: mockSavePhoto,
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

  group('UpdateUserAvatarUseCase -', () {
    group('sucesso', () {
      setUp(() {
        when(() => mockAuth.currentUser()).thenAnswer((_) async => tUser);
        when(() => mockUserRepository.getUserById(any())).thenAnswer(
          (_) async => right(const AuthUser('user-123', 'João', 'joao@email.com')),
        );
        when(
          () => mockSavePhoto(
            file: any(named: 'file'),
            oldPath: any(named: 'oldPath'),
          ),
        ).thenAnswer((_) async => right('/storage/avatar_new.jpg'));
        when(() => mockUserRepository.saveUser(any())).thenAnswer((_) async => right(unit));
      });

      test('retorna Right com novo path', () async {
        final result = await useCase(File('/tmp/foto.jpg'));

        expect(result, isRight());
      });

      test('passa o novo path correto no retorno', () async {
        final result = await useCase(File('/tmp/foto.jpg'));

        result.fold((_) => fail('esperava Right'), (path) => expect(path, '/storage/avatar_new.jpg'));
      });

      test('chama updatePhotoPath com novo path', () async {
        await useCase(File('/tmp/foto.jpg'));

        verify(() => mockUserRepository.saveUser(any())).called(1);
      });

      test('registra evento de sucesso', () async {
        await useCase(File('/tmp/foto.jpg'));

        verify(() => mockObservability.logEvent('update_avatar_success')).called(1);
      });

      test('passa oldPath do usuário existente para savePhoto', () async {
        when(() => mockUserRepository.getUserById(any())).thenAnswer(
          (_) async => right(const AuthUser('user-123', 'João', 'joao@email.com', photoUrl: '/storage/avatar_old.jpg')),
        );

        await useCase(File('/tmp/foto.jpg'));

        verify(
          () => mockSavePhoto(
            file: any(named: 'file'),
            oldPath: '/storage/avatar_old.jpg',
          ),
        ).called(1);
      });
    });

    group('falha - usuário não autenticado', () {
      setUp(() {
        when(() => mockAuth.currentUser()).thenAnswer((_) async => null);
      });

      test('retorna Left quando não há usuário logado', () async {
        final result = await useCase(File('/tmp/foto.jpg'));

        expect(result, isLeft());
      });

      test('não chama savePhoto quando não autenticado', () async {
        await useCase(File('/tmp/foto.jpg'));

        verifyNever(
          () => mockSavePhoto(
            file: any(named: 'file'),
            oldPath: any(named: 'oldPath'),
          ),
        );
      });
    });

    group('falha - erro ao salvar arquivo', () {
      setUp(() {
        when(() => mockAuth.currentUser()).thenAnswer((_) async => tUser);
        when(() => mockUserRepository.getUserById(any())).thenAnswer(
          (_) async => right(const AuthUser('user-123', 'João', 'joao@email.com')),
        );
        when(
          () => mockSavePhoto(
            file: any(named: 'file'),
            oldPath: any(named: 'oldPath'),
          ),
        ).thenAnswer((_) async => left(tFailure));
      });

      test('retorna Left quando savePhoto falha', () async {
        final result = await useCase(File('/tmp/foto.jpg'));

        expect(result, isLeft());
        expect(leftFailure(result).message, tFailure.message);
      });

      test('não chama updatePhotoPath quando savePhoto falha', () async {
        await useCase(File('/tmp/foto.jpg'));

        verifyNever(() => mockUserRepository.saveUser(any()));
      });

      test('registra evento de falha quando savePhoto falha', () async {
        await useCase(File('/tmp/foto.jpg'));

        verify(() => mockObservability.logEvent('update_avatar_failure')).called(1);
      });
    });

    group('falha - erro ao persistir no repositório', () {
      setUp(() {
        when(() => mockAuth.currentUser()).thenAnswer((_) async => tUser);
        when(() => mockUserRepository.getUserById(any())).thenAnswer(
          (_) async => right(const AuthUser('user-123', 'João', 'joao@email.com')),
        );
        when(
          () => mockSavePhoto(
            file: any(named: 'file'),
            oldPath: any(named: 'oldPath'),
          ),
        ).thenAnswer((_) async => right('/storage/avatar_new.jpg'));
        when(() => mockUserRepository.saveUser(any())).thenAnswer((_) async => left(tFailure));
      });

      test('retorna Left quando updatePhotoPath falha', () async {
        final result = await useCase(File('/tmp/foto.jpg'));

        expect(result, isLeft());
        expect(leftFailure(result).message, tFailure.message);
      });

      test('registra evento de falha quando persist falha', () async {
        await useCase(File('/tmp/foto.jpg'));

        verify(() => mockObservability.logEvent('update_avatar_failure')).called(1);
      });
    });
  });
}
