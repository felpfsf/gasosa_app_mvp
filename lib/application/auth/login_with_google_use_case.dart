import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/core/services/observability/observability_service.dart';
import 'package:gasosa_app/domain/repositories/user_repository.dart';
import 'package:gasosa_app/domain/services/auth_service.dart';
import 'package:injectable/injectable.dart';

@injectable
class LoginWithGoogleUseCase {
  LoginWithGoogleUseCase({
    required AuthService auth,
    required UserRepository userRepository,
    required ObservabilityService observability,
  }) : _auth = auth,
       _userRepository = userRepository,
       _observability = observability;

  final AuthService _auth;
  final UserRepository _userRepository;
  final ObservabilityService _observability;

  Future<Either<Failure, AuthUser>> call() async {
    _observability.logBreadcrumb('login_google_attempt');

    final result = await _auth.loginWithGoogle();

    await result.fold(
      (failure) async {
        await _observability.logError(failure, context: {'action': 'login_google'});
        await _observability.logEvent('login_google_failure');
      },
      (user) async {
        _observability.setUserId(user.id);
        await _userRepository.saveUser(user);
        await _observability.logEvent('login_google_success');
      },
    );

    return result;
  }
}
