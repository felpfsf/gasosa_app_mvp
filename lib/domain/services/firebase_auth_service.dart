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
    try {
      final account = await _google.authenticate(
        scopeHint: ['email', 'profile', 'openid'],
      );

      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        return left(const AuthFailure('Erro ao obter credenciais do Google'));
      }

      final credential = fb.GoogleAuthProvider.credential(idToken: idToken);
      final userCredentials = await _auth.signInWithCredential(credential);
      final user = userCredentials.user;
      if (user == null) {
        return left(const AuthFailure('Falha de autenticação, usuário nulo'));
      }

      final email = user.email ?? account.email;
      final displayName = (user.displayName?.trim().isNotEmpty ?? false)
          ? user.displayName!.trim()
          : (account.displayName ?? (email.isNotEmpty ? email.split('@').first : ''));
      final photoUrl = user.photoURL ?? account.photoUrl;
      return right(AuthUser(user.uid, displayName, email, photoUrl: photoUrl));
    } on GoogleSignInException catch (e, s) {
      return left(_mapGoogleSignInError(e, s));
    } on fb.FirebaseAuthException catch (e, s) {
      return left(_mapFirebaseAuthError(e, s));
    } catch (e, s) {
      return left(AuthFailure('Erro inesperado de autenticação', cause: e, stackTrace: s));
    }
  }

  @override
  FResult<void> logout() async {
    try {
      await Future.wait([_auth.signOut(), _google.signOut()]);
      return right(null);
    } catch (e, s) {
      return left(AuthFailure('Falha ao sair', cause: e, stackTrace: s));
    }
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

  @override
  FResult<Result<void>> linkGoogleAfterPasswordLogin() async {
    try {
      final account = await _google.authenticate(
        scopeHint: ['email', 'profile', 'openid'],
      );
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        return left(const AuthFailure('Sem credenciais do Google'));
      }
      final credential = fb.GoogleAuthProvider.credential(idToken: idToken);

      await fb.FirebaseAuth.instance.currentUser?.linkWithCredential(credential);

      return right(right(null));
    } on fb.FirebaseAuthException catch (e, s) {
      return left(_mapFirebaseAuthError(e, s));
    } catch (e, s) {
      return left(AuthFailure('Falha ao vincular com o Google', cause: e, stackTrace: s));
    }
  }
}

Failure _mapFirebaseAuthError(fb.FirebaseAuthException e, StackTrace s) {
  switch (e.code) {
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return AuthFailure('Email ou senha inválidos', cause: e, stackTrace: s);
    case 'email-already-in-use':
      return AuthFailure('Email já está em uso', cause: e, stackTrace: s);
    case 'network-request-failed':
      return AuthFailure('Falha na conexão com a internet', cause: e, stackTrace: s);
    case 'account-exists-with-different-credential':
      return AuthFailure(
        'Este e-mail já está vinculado a outro método de login. '
        'Entre pelo método original e depois vincule o Google nas Configurações.',
        cause: e,
        stackTrace: s,
      );
    case 'user-disabled':
      return AuthFailure('Usuário desativado', cause: e, stackTrace: s);
    default:
      return AuthFailure('Erro inesperado de autenticação', cause: e, stackTrace: s);
  }
}

Failure _mapGoogleSignInError(GoogleSignInException e, StackTrace s) {
  final description = e.description ?? '';

  // [16] Account reauth failed: SHA-1/SHA-256 não configurados no Firebase
  if (description.contains('[16]') || description.toLowerCase().contains('reauth failed')) {
    return AuthFailure(
      'Erro de configuração do Google Sign-In. '
      'Verifique as credenciais SHA no Firebase Console.',
      cause: e,
      stackTrace: s,
    );
  }

  switch (e.code) {
    case GoogleSignInExceptionCode.canceled:
      // Se tem description relevante, use ela
      if (description.isNotEmpty && !description.toLowerCase().contains('cancel')) {
        return AuthFailure('Falha no Google Sign-In: $description', cause: e, stackTrace: s);
      }
      return AuthFailure('Login cancelado pelo usuário', cause: e, stackTrace: s);
    case GoogleSignInExceptionCode.interrupted:
      return AuthFailure('Login interrompido. Tente novamente.', cause: e, stackTrace: s);
    case GoogleSignInExceptionCode.uiUnavailable:
      return AuthFailure('UI de login indisponível.', cause: e, stackTrace: s);
    default:
      return AuthFailure('Falha no Google Sign-In', cause: e, stackTrace: s);
  }
}
