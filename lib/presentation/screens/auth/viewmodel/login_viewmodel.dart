import 'package:gasosa_app/application/auth/login_email_password_use_case.dart';
import 'package:gasosa_app/application/auth/login_with_google_use_case.dart';
import 'package:gasosa_app/application/auth/send_password_reset_use_case.dart';
import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/core/presentation/command.dart';
import 'package:gasosa_app/core/presentation/ui_state.dart';
import 'package:gasosa_app/domain/services/auth_service.dart';
import 'package:injectable/injectable.dart';

@injectable
class LoginViewModel {
  LoginViewModel(
    this._loginGoogle,
    this._loginEmailPassword,
    this._sendPasswordReset,
  ) : googleCommand = Command<AuthUser>(),
      loginCommand = Command<AuthUser>(),
      resetCommand = Command<void>();

  final LoginWithGoogleUseCase _loginGoogle;
  final LoginEmailPasswordUseCase _loginEmailPassword;
  final SendPasswordResetUseCase _sendPasswordReset;

  final Command<AuthUser> googleCommand;
  final Command<AuthUser> loginCommand;
  final Command<void> resetCommand;

  bool get isLoading =>
      googleCommand.state.value is UiLoading ||
      loginCommand.state.value is UiLoading ||
      resetCommand.state.value is UiLoading;

  Future<Either<Failure, AuthUser>?> googleSignIn() => googleCommand.run(() => _loginGoogle());

  Future<Either<Failure, AuthUser>?> loginWithEmailPassword({
    required String email,
    required String password,
  }) => loginCommand.run(() => _loginEmailPassword(email: email, password: password));

  Future<Either<Failure, void>?> sendPasswordReset(String email) => resetCommand.run(() => _sendPasswordReset(email));

  void dispose() {
    googleCommand.dispose();
    loginCommand.dispose();
    resetCommand.dispose();
  }
}
