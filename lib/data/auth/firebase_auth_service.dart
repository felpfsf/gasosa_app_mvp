import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/domain/services/auth_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: AuthService)
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({
    required fb.FirebaseAuth auth,
    required GoogleSignIn google,
  }) : _auth = auth,
       _google = google;

  final fb.FirebaseAuth _auth;
  final GoogleSignIn _google;

  @override
  Future<Either<Failure, AuthUser>> loginWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final user = credential.user!;
      return right(AuthUser(user.uid, user.displayName ?? '', user.email ?? email));
    } on fb.FirebaseAuthException catch (e, s) {
      return left(_mapFirebaseAuthError(e, s));
    } catch (e, s) {
      return left(UnexpectedFailure('Erro inesperado de autenticação', e, s));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> loginWithGoogle() async {
    try {
      final account = await _google.authenticate(
        scopeHint: ['email', 'profile', 'openid'],
      );

      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        return left(const UnexpectedFailure('Erro ao obter credenciais do Google', null, null));
      }

      final credential = fb.GoogleAuthProvider.credential(idToken: idToken);
      final userCredentials = await _auth.signInWithCredential(credential);
      final user = userCredentials.user;
      if (user == null) {
        return left(const UnexpectedFailure('Falha de autenticação, usuário nulo', null, null));
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
      return left(UnexpectedFailure('Erro inesperado de autenticação', e, s));
    }
  }

  @override
  Future<AuthUser?> currentUser() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;
    return AuthUser(fbUser.uid, fbUser.displayName ?? '', fbUser.email ?? '');
  }

  @override
  Stream<AuthUser?> userChanges() => _auth.userChanges().map(
    (fbUser) => fbUser == null ? null : AuthUser(fbUser.uid, fbUser.displayName ?? '', fbUser.email ?? ''),
  );

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await Future.wait([_auth.signOut(), _google.signOut()]);
      return right(null);
    } catch (e, s) {
      return left(UnexpectedFailure('Falha ao sair', e, s));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> register(String name, String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final user = credential.user!;
      await user.updateDisplayName(name);
      await user.reload();
      final refreshedUser = _auth.currentUser!;

      return right(AuthUser(refreshedUser.uid, refreshedUser.displayName ?? name, refreshedUser.email ?? email));
    } on fb.FirebaseAuthException catch (e, s) {
      return left(_mapFirebaseAuthError(e, s));
    } catch (e, s) {
      return left(UnexpectedFailure('Erro inesperado de autenticação', e, s));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return right(null);
    } on fb.FirebaseAuthException catch (e, s) {
      return left(_mapFirebaseAuthError(e, s));
    } catch (e, s) {
      return left(UnexpectedFailure('Erro ao enviar e-mail de redefinição', e, s));
    }
  }

  @override
  Future<Either<Failure, Either<Failure, void>>> linkGoogleAfterPasswordLogin() async {
    try {
      final account = await _google.authenticate(
        scopeHint: ['email', 'profile', 'openid'],
      );
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        return left(const UnexpectedFailure('Sem credenciais do Google', null, null));
      }
      final credential = fb.GoogleAuthProvider.credential(idToken: idToken);

      await _auth.currentUser?.linkWithCredential(credential);

      return right(right(null));
    } on fb.FirebaseAuthException catch (e, s) {
      return left(_mapFirebaseAuthError(e, s));
    } catch (e, s) {
      return left(UnexpectedFailure('Falha ao vincular com o Google', e, s));
    }
  }
}

Failure _mapFirebaseAuthError(fb.FirebaseAuthException e, StackTrace s) {
  switch (e.code) {
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return UnexpectedFailure('Email ou senha inválidos', e, s);
    case 'email-already-in-use':
      return UnexpectedFailure('Email já está em uso', e, s);
    case 'network-request-failed':
      return UnexpectedFailure('Falha na conexão com a internet', e, s);
    case 'account-exists-with-different-credential':
      return UnexpectedFailure(
        'Este e-mail já está vinculado a outro método de login. '
        'Entre pelo método original e depois vincule o Google nas Configurações.',
        e,
        s,
      );
    case 'user-disabled':
      return UnexpectedFailure('Usuário desativado', e, s);
    default:
      return UnexpectedFailure('Erro inesperado de autenticação', e, s);
  }
}

Failure _mapGoogleSignInError(GoogleSignInException e, StackTrace s) {
  final description = e.description ?? '';

  // [16] Account reauth failed: SHA-1/SHA-256 não configurados no Firebase
  if (description.contains('[16]') || description.toLowerCase().contains('reauth failed')) {
    return UnexpectedFailure(
      'Erro de configuração do Google Sign-In. '
      'Verifique as credenciais SHA no Firebase Console.',
      e,
      s,
    );
  }

  switch (e.code) {
    case GoogleSignInExceptionCode.canceled:
      // Se tem description relevante, use ela
      if (description.isNotEmpty && !description.toLowerCase().contains('cancel')) {
        return UnexpectedFailure('Falha no Google Sign-In: $description', e, s);
      }
      return UnexpectedFailure('Login cancelado pelo usuário', e, s);
    case GoogleSignInExceptionCode.interrupted:
      return UnexpectedFailure('Login interrompido. Tente novamente.', e, s);
    case GoogleSignInExceptionCode.uiUnavailable:
      return UnexpectedFailure('UI de login indisponível.', e, s);
    default:
      return UnexpectedFailure('Falha no Google Sign-In', e, s);
  }
}
