import 'package:gasosa_app/application/auth/login_email_password_use_case.dart';
import 'package:gasosa_app/application/auth/login_with_google_use_case.dart';
import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/core/presentation/command.dart';
import 'package:gasosa_app/domain/services/auth_service.dart';
import 'package:injectable/injectable.dart';

@injectable
class LoginViewModel {
  LoginViewModel(
    this._loginGoogle,
    this._loginEmailPassword,
  ) : googleCommand = Command<AuthUser>(),
      loginCommand = Command<AuthUser>();

  final LoginWithGoogleUseCase _loginGoogle;
  final LoginEmailPasswordUseCase _loginEmailPassword;

  final Command<AuthUser> googleCommand;
  final Command<AuthUser> loginCommand;

  String email = '';
  String password = '';

  void setEmail(String v) => email = v;
  void setPassword(String v) => password = v;

  Future<Either<Failure, AuthUser>?> googleSignIn() => googleCommand.run(() => _loginGoogle());

  Future<Either<Failure, AuthUser>?> loginWithEmailPassword() =>
      loginCommand.run(() => _loginEmailPassword(email: email, password: password));

  void dispose() {
    googleCommand.dispose();
    loginCommand.dispose();
  }
}
