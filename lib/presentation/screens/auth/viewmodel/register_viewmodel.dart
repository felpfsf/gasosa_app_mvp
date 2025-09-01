import 'package:gasosa_app/application/commands/auth/register_command.dart';
import 'package:gasosa_app/core/viewmodel/base_viewmodel.dart';
import 'package:gasosa_app/core/viewmodel/loading_controller.dart';

class RegisterState {
  const RegisterState({
    this.isLoading = false,
    this.errorMessage,
    this.name = '',
    this.email = '',
    this.password = '',
  });

  final bool isLoading;
  final String? errorMessage;
  final String name, email, password;

  RegisterState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? name,
    String? email,
    String? password,
  }) => RegisterState(
    isLoading: isLoading ?? this.isLoading,
    errorMessage: errorMessage,
    name: name ?? this.name,
    email: email ?? this.email,
    password: password ?? this.password,
  );
}

class RegisterViewModel extends BaseViewModel {
  RegisterViewModel({
    required RegisterCommand registerCommand,
    required LoadingController loading,
  }) : _registerCommand = registerCommand,
       super(loading);

  final RegisterCommand _registerCommand;

  RegisterState _state = const RegisterState();
  RegisterState get state => _state;

  @override
  void setViewLoading({bool value = false}) {
    _state = _state.copyWith(isLoading: value);
    notifyListeners();
  }

  void _setError(String message) {
    _state = _state.copyWith(isLoading: false, errorMessage: message);
    notifyListeners();
  }

  void setName(String name) {
    _state = _state.copyWith(name: name);
    notifyListeners();
  }

  void setEmail(String email) {
    _state = _state.copyWith(email: email);
    notifyListeners();
  }

  void setPassword(String password) {
    _state = _state.copyWith(password: password);
    notifyListeners();
  }

  Future<bool> register() async {
    // _setLoading(true);
    // final response = await _registerCommand(email: _state.email, name: _state.name, password: _state.password);
    // return response.fold(
    //   (failure) {
    //     _setLoading(false);
    //     _setError(failure.message);
    //     return false;
    //   },
    //   (_) {
    //     _setLoading(false);
    //     return true;
    //   },
    // );
    return track(
      () async {
        final response = await _registerCommand(
          email: _state.email,
          name: _state.name,
          password: _state.password,
        );
        return response.fold(
          (failure) {
            _setError(failure.message);
            return false;
          },
          (_) {
            return true;
          },
        );
      },
    );
  }
}
