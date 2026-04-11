import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/core/services/observability/observability_service.dart';
import 'package:gasosa_app/domain/repositories/vehicle_repository.dart';
import 'package:gasosa_app/domain/services/auth_service.dart';
import 'package:injectable/injectable.dart';

@injectable
class DeleteAccountUseCase {
  DeleteAccountUseCase({
    required AuthService auth,
    required VehicleRepository vehicleRepository,
    required ObservabilityService observability,
  })  : _auth = auth,
        _vehicleRepository = vehicleRepository,
        _observability = observability;

  final AuthService _auth;
  final VehicleRepository _vehicleRepository;
  final ObservabilityService _observability;

  Future<Either<Failure, void>> call() async {
    _observability.logBreadcrumb('delete_account_attempt');

    final currentUser = await _auth.currentUser();
    if (currentUser == null) {
      return left(const UnexpectedFailure('Usuário não autenticado', null, null));
    }

    // 1. Deletar todos os dados locais do usuário (veículos + abastecimentos em cascade)
    final deleteLocalResult = await _vehicleRepository.deleteAllByUserId(currentUser.id);
    Failure? localFailure;
    deleteLocalResult.fold((f) => localFailure = f, (_) {});
    if (localFailure != null) {
      await _observability.logError(
        localFailure!,
        context: {'action': 'delete_account_local_data'},
      );
      return left(localFailure!);
    }

    // 2. Deletar conta no Firebase Auth
    final deleteAuthResult = await _auth.deleteAccount();

    await deleteAuthResult.fold(
      (failure) async {
        await _observability.logError(failure, context: {'action': 'delete_account_firebase'});
        await _observability.logEvent('delete_account_failure');
      },
      (_) async {
        await _observability.logEvent('delete_account_success');
        _observability.clearContext();
      },
    );

    return deleteAuthResult;
  }
}
