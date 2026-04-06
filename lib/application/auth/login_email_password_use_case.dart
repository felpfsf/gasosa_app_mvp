import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/core/services/observability/observability_service.dart';
import 'package:gasosa_app/domain/services/auth_service.dart';
import 'package:injectable/injectable.dart';

@injectable
class LoginEmailPasswordUseCase {
  LoginEmailPasswordUseCase({
    required AuthService auth,
    required ObservabilityService observability,
  }) : _auth = auth,
       _observability = observability;

  final AuthService _auth;
  final ObservabilityService _observability;

  Future<Either<Failure, AuthUser>> call({
    required String email,
    required String password,
  }) async {
    _observability.logBreadcrumb('login_email_attempt');

    final result = await _auth.loginWithEmail(email, password);

    await result.fold(
      (failure) async {
        await _observability.logError(failure, context: {'action': 'login_email'});
        await _observability.logEvent('login_email_failure');
      },
      (user) async {
        _observability.setUserId(user.id);
        await _observability.logEvent('login_email_success');
      },
    );

    return result;
  }
}
