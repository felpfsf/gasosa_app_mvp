import 'package:gasosa_app/core/app_strings.dart';
import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/core/services/observability/observability_service.dart';
import 'package:gasosa_app/domain/services/auth_service.dart';
import 'package:injectable/injectable.dart';

@injectable
class UpdateDisplayNameUseCase {
  UpdateDisplayNameUseCase({
    required AuthService auth,
    required ObservabilityService observability,
  })  : _auth = auth,
        _observability = observability;

  final AuthService _auth;
  final ObservabilityService _observability;

  static const int _maxLength = 50;

  Future<Either<Failure, void>> call(String name) async {
    final trimmed = name.trim();

    if (trimmed.isEmpty) {
      return left(ValidationFailure(ProfileStrings.errorNameEmpty));
    }

    if (trimmed.length > _maxLength) {
      return left(ValidationFailure(ProfileStrings.errorNameTooLong));
    }

    final currentUser = await _auth.currentUser();
    if (currentUser == null) {
      return left(const UnexpectedFailure('Usuário não autenticado', null, null));
    }

    final result = await _auth.updateDisplayName(trimmed);

    await result.fold(
      (failure) async {
        await _observability.logError(failure, context: {'action': 'update_display_name'});
        await _observability.logEvent('update_display_name_failure');
      },
      (_) async {
        await _observability.logEvent('update_display_name_success');
      },
    );

    return result;
  }
}
