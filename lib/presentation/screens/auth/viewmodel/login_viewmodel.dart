import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gasosa_app/application/loggin_with_google_command.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
    errorMessage: errorMessage ?? this.errorMessage,
    email: email ?? this.email,
    password: password ?? this.password,
  );
}

class LoginViewmodel extends ChangeNotifier {
  LoginViewmodel(this._loginGoogle);

  final LoginWithGoogleCommand _loginGoogle;

  LoginState _state = const LoginState();
  LoginState get state => _state;

  Future<bool> googleSignIn() async {
    _state = _state.copyWith(isLoading: true, errorMessage: '');
    notifyListeners();
    try {
      await _loginGoogle();
      return true;
    } on GoogleSignInException catch (e) {
      _state = _state.copyWith(isLoading: false, errorMessage: _mapGoogle(e));
      notifyListeners();
      return false;
    } on FirebaseAuthException catch (e) {
      _state = _state.copyWith(isLoading: false, errorMessage: _mapFirebase(e));
      notifyListeners();
      return false;
    } catch (_) {
      _state = _state.copyWith(
        isLoading: false,
        errorMessage: 'Erro desconhecido ao fazer login com o Google.',
      );
      notifyListeners();
      return false;
    }
  }

  String _mapFirebase(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'E‑mail inválido.';
      case 'user-disabled':
        return 'Usuário desativado.';
      case 'user-not-found':
        return 'Usuário não encontrado.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'account-exists-with-different-credential':
        return 'Já existe conta com outro provedor.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde.';
      case 'network-request-failed':
        return 'Sem conexão.';
    }
    return 'Erro de autenticação (${e.code}).';
  }

  String _mapGoogle(GoogleSignInException e) {
    // e.code pode variar por plataforma; trate cancelamento/erros comuns
    final code = e.code.toString().toLowerCase();
    if (code.contains('canceled') || code.contains('cancelled')) {
      return 'Login cancelado.';
    }
    if (code.contains('network')) {
      return 'Sem conexão.';
    }
    return 'Erro no Google Sign‑In.';
  }
}
