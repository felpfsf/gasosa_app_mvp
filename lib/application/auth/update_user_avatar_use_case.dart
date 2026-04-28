import 'dart:io';

import 'package:gasosa_app/application/photos/save_photo_use_case.dart';
import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/core/services/observability/observability_service.dart';
import 'package:gasosa_app/domain/repositories/user_repository.dart';
import 'package:gasosa_app/domain/services/auth_service.dart';
import 'package:injectable/injectable.dart';

@injectable
class UpdateUserAvatarUseCase {
  UpdateUserAvatarUseCase({
    required AuthService auth,
    required UserRepository userRepository,
    required SavePhotoUseCase savePhoto,
    required ObservabilityService observability,
  }) : _auth = auth,
       _userRepository = userRepository,
       _savePhoto = savePhoto,
       _observability = observability;

  final AuthService _auth;
  final UserRepository _userRepository;
  final SavePhotoUseCase _savePhoto;
  final ObservabilityService _observability;

  Future<Either<Failure, String>> call(File file) async {
    _observability.logBreadcrumb('update_avatar_attempt');

    final currentUser = await _auth.currentUser();
    if (currentUser == null) {
      return left(const UnexpectedFailure('Usuário não autenticado', null, null));
    }

    // Recupera path atual para deletar após salvar o novo
    String? oldPath;
    final userResult = await _userRepository.getUserById(currentUser.id);
    userResult.fold((f) => null, (u) => oldPath = u?.photoUrl);

    // Salva novo arquivo local (já remove o antigo internamente se oldPath informado)
    final saveResult = await _savePhoto(file: file, oldPath: oldPath);
    Failure? saveFailure;
    saveResult.fold((f) => saveFailure = f, (_) {});
    if (saveFailure != null) {
      await _observability.logError(saveFailure!, context: {'action': 'update_avatar_save_file'});
      await _observability.logEvent('update_avatar_failure');
      return left(saveFailure!);
    }

    final newPath = saveResult.fold((_) => '', (p) => p);

    // Persiste novo path no repositório local (upsert garante que a linha exista)
    final updateResult = await _userRepository.saveUser(
      AuthUser(currentUser.id, currentUser.name, currentUser.email, photoUrl: newPath),
    );
    Failure? updateFailure;
    updateResult.fold((f) => updateFailure = f, (_) {});
    if (updateFailure != null) {
      await _observability.logError(updateFailure!, context: {'action': 'update_avatar_persist'});
      await _observability.logEvent('update_avatar_failure');
      return left(updateFailure!);
    }

    await _observability.logEvent('update_avatar_success');
    return right(newPath);
  }
}
