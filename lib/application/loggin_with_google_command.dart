import 'package:gasosa_app/domain/auth/auth_repository.dart';

class LoginWithGoogleCommand {
  const LoginWithGoogleCommand(this._repo);
  final AuthRepository _repo;

  Future<void> call() => _repo.loginWithGoogle();
}
