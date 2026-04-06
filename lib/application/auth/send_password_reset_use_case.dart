import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/domain/services/auth_service.dart';
import 'package:injectable/injectable.dart';

@injectable
class SendPasswordResetUseCase {
  SendPasswordResetUseCase({required AuthService auth}) : _auth = auth;

  final AuthService _auth;

  Future<Either<Failure, void>> call(String email) => _auth.sendPasswordReset(email);
}
