import 'package:gasosa_app/application/photos/delete_photo_use_case.dart';
import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/core/services/observability/observability_service.dart';
import 'package:gasosa_app/domain/repositories/user_repository.dart';
import 'package:gasosa_app/domain/services/auth_service.dart';
import 'package:injectable/injectable.dart';

@injectable
class RemoveUserAvatarUseCase {
  RemoveUserAvatarUseCase({
    required AuthService auth,
    required UserRepository userRepository,
    required DeletePhotoUseCase deletePhoto,
    required ObservabilityService observability,
  }) : _auth = auth,
       _userRepository = userRepository,
       _deletePhoto = deletePhoto,
       _observability = observability;

  final AuthService _auth;
  final UserRepository _userRepository;
  final DeletePhotoUseCase _deletePhoto;
  final ObservabilityService _observability;

  Future<Either<Failure, void>> call() async {
    _observability.logBreadcrumb('remove_avatar_attempt');

    final currentUser = await _auth.currentUser();
    if (currentUser == null) {
      return left(const UnexpectedFailure('Usuário não autenticado', null, null));
    }

    // Recupera path atual para deletar o arquivo
    final userResult = await _userRepository.getUserById(currentUser.id);
    String? currentPath;
    userResult.fold((f) => null, (u) => currentPath = u?.photoUrl);

    // Deleta arquivo local se existir (falha silenciosa — arquivo pode já não existir)
    if (currentPath != null && currentPath!.isNotEmpty) {
      await _deletePhoto(currentPath!);
    }

    // Remove path do repositório (upsert com photoUrl vazio garante que a linha exista)
    final clearResult = await _userRepository.saveUser(
      AuthUser(currentUser.id, currentUser.name, currentUser.email),
    );
    Failure? clearFailure;
    clearResult.fold((f) => clearFailure = f, (_) {});
    if (clearFailure != null) {
      await _observability.logError(clearFailure!, context: {'action': 'remove_avatar_persist'});
      await _observability.logEvent('remove_avatar_failure');
      return left(clearFailure!);
    }

    await _observability.logEvent('remove_avatar_success');
    return right(null);
  }
}
