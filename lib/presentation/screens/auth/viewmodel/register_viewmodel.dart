import 'package:gasosa_app/application/auth/register_use_case.dart';
import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/core/presentation/command.dart';
import 'package:gasosa_app/domain/services/auth_service.dart';
import 'package:injectable/injectable.dart';

@injectable
class RegisterViewModel {
  RegisterViewModel(this._registerUseCase) : registerCommand = Command<AuthUser>();

  final RegisterUseCase _registerUseCase;

  final Command<AuthUser> registerCommand;

  String name = '';
  String email = '';
  String password = '';

  void setName(String v) => name = v;
  void setEmail(String v) => email = v;
  void setPassword(String v) => password = v;

  Future<Either<Failure, AuthUser>?> register() =>
      registerCommand.run(() => _registerUseCase(name: name, email: email, password: password));

  void dispose() => registerCommand.dispose();
}
