import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/domain/services/auth_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({
    fb.FirebaseAuth? auth,
    GoogleSignIn? google,
  }) : _auth = auth ?? fb.FirebaseAuth.instance,
       _google = google ?? GoogleSignIn.instance;

  final fb.FirebaseAuth _auth;
  final GoogleSignIn _google;

  @override
  FResult<AuthUser> loginWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final user = credential.user!;

      return right(AuthUser(user.uid, user.displayName ?? '', user.email ?? email));
    } on fb.FirebaseAuthException catch (e, s) {
      return left(_mapFirebaseAuthError(e, s));
    } catch (e, s) {
      return left(AuthFailure('Erro inesperado de autenticação', cause: e, stackTrace: s));
    }
  }

  @override
  FResult<AuthUser> loginWithGoogle() async {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {
    await _auth.signOut();
  }

  @override
  FResult<AuthUser> register(String name, String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final user = credential.user!;
      return right(AuthUser(user.uid, name, user.email ?? email));
    } on fb.FirebaseAuthException catch (e, s) {
      return left(_mapFirebaseAuthError(e, s));
    } catch (e, s) {
      return left(AuthFailure('Erro inesperado de autenticação', cause: e, stackTrace: s));
    }
  }
}

Failure _mapFirebaseAuthError(fb.FirebaseAuthException e, StackTrace s) {
  switch (e.code) {
    case 'user-not-found':
    case 'wrong-password':
      return AuthFailure('Email ou senha inválidos', cause: e, stackTrace: s);
    case 'email-already-in-use':
      return AuthFailure('Email já está em uso', cause: e, stackTrace: s);
    case 'network-request-failed':
      return AuthFailure('Falha na conexão com a internet', cause: e, stackTrace: s);
    default:
      return AuthFailure('Erro inesperado de autenticação', cause: e, stackTrace: s);
  }
}
