import 'package:gasosa_app/application/loggin_with_google_command.dart';
import 'package:gasosa_app/application/login_email_password_command.dart';
import 'package:gasosa_app/core/viewmodel/base_viewmodel.dart';
import 'package:gasosa_app/core/viewmodel/loading_controller.dart';

class LoginState {
  const LoginState({
    this.isLoading = false,
    this.errorMessage,
    this.email = '',
    this.password = '',
  });

  final bool isLoading;
  final String? errorMessage;
  final String email;
  final String password;

  LoginState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? email,
    String? password,
  }) => LoginState(
    isLoading: isLoading ?? this.isLoading,
    errorMessage: errorMessage,
    email: email ?? this.email,
    password: password ?? this.password,
  );
}

class LoginViewModel extends BaseViewModel {
  LoginViewModel({
    required LoginWithGoogleCommand loginGoogle,
    required LoginEmailPasswordCommand loginEmailPassword,
    required LoadingController loading,
  }) : _loginGoogle = loginGoogle,
      _loginEmailPassword = loginEmailPassword,
      super(loading);

  final LoginWithGoogleCommand _loginGoogle;
  final LoginEmailPasswordCommand _loginEmailPassword;

  LoginState _state = const LoginState();
  LoginState get state => _state;

  @override
  void setViewLoading({bool value = false}) {
    _state = _state.copyWith(isLoading: value);
    notifyListeners();
  }

  void _setError(String message) {
    _state = _state.copyWith(isLoading: false, errorMessage: message);
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

  Future<bool> googleSignIn() async {
    // _setLoading(true);
    // final response = await _loginGoogle();
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
    return track(() async {
      final response = await _loginGoogle();
      return response.fold(
        (failure) {
          _setError(failure.message);
          return false;
        },
        (_) {
          return true;
        },
      );
    });
  }

  Future<bool> loginWithEmailPassword() async {
    // _setLoading(true);
    // final response = await _loginEmailPassword(email: _state.email, password: _state.password);
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
    return track(() async {
      final response = await _loginEmailPassword(email: _state.email, password: _state.password);
      return response.fold(
        (failure) {
          _setError(failure.message);
          return false;
        },
        (_) {
          return true;
        },
      );
    });
  }
}
