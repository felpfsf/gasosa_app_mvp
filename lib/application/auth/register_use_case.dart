import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/domain/services/auth_service.dart';
import 'package:injectable/injectable.dart';

@injectable
class RegisterUseCase {
  RegisterUseCase({required AuthService auth}) : _auth = auth;

  final AuthService _auth;

  Future<Either<Failure, AuthUser>> call({required String name, required String email, required String password}) =>
      _auth.register(name, email, password);
}
