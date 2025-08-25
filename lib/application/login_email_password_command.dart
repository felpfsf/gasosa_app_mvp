import 'package:dartz/dartz.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/domain/services/auth_service.dart';

class LoginEmailPasswordCommand {
  LoginEmailPasswordCommand({required AuthService auth}) : _auth = auth;

  final AuthService _auth;

  Future<Either<Failure, AuthUser>> call({required String email, required String password}) =>
      _auth.loginWithEmail(email, password);
}
