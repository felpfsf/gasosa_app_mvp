import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/core/services/observability/observability_service.dart';
import 'package:gasosa_app/domain/services/auth_service.dart';
import 'package:injectable/injectable.dart';

@injectable
class LogoutUseCase {
  LogoutUseCase({
    required AuthService auth,
    required ObservabilityService observability,
  }) : _auth = auth,
       _observability = observability;

  final AuthService _auth;
  final ObservabilityService _observability;

  Future<Either<Failure, void>> call() async {
    _observability.logBreadcrumb('logout_attempt');

    final result = await _auth.logout();

    await result.fold(
      (failure) async {
        await _observability.logError(failure, context: {'action': 'logout'});
      },
      (_) async {
        await _observability.logEvent('logout_success');
        _observability.clearContext();
      },
    );

    return result;
  }
}
