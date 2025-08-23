import 'package:dartz/dartz.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/domain/services/auth_service.dart';

class LoginWithGoogleCommand {
  LoginWithGoogleCommand(this._auth);

  final AuthService _auth;

  Future<Either<Failure, AuthUser>> call() => _auth.loginWithGoogle();
}
