import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/core/services/observability/observability_service.dart';
import 'package:gasosa_app/domain/services/auth_service.dart';
import 'package:injectable/injectable.dart';

@injectable
class RegisterUseCase {
  RegisterUseCase({
    required AuthService auth,
    required ObservabilityService observability,
  }) : _auth = auth,
       _observability = observability;

  final AuthService _auth;
  final ObservabilityService _observability;

  Future<Either<Failure, AuthUser>> call({
    required String name,
    required String email,
    required String password,
  }) async {
    _observability.logBreadcrumb('register_attempt');

    final result = await _auth.register(name, email, password);

    await result.fold(
      (failure) async {
        await _observability.logError(failure, context: {'action': 'register'});
        await _observability.logEvent('register_failure');
      },
      (user) async {
        _observability.setUserId(user.id);
        await _observability.logEvent('register_success');
      },
    );

    return result;
  }
}
