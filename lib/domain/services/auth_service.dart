import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';

class AuthUser {
  const AuthUser(
    this.id,
    this.name,
    this.email, {
    this.photoUrl = '',
  });

  final String id, name, email;
  final String? photoUrl;
}

abstract interface class AuthService {
  Future<AuthUser?> currentUser();
  Stream<AuthUser?> userChanges();
  Future<Either<Failure, AuthUser>> register(String name, String email, String password);
  Future<Either<Failure, AuthUser>> loginWithEmail(String email, String password);
  Future<Either<Failure, AuthUser>> loginWithGoogle();
  Future<Either<Failure, Either<Failure, void>>> linkGoogleAfterPasswordLogin();
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, void>> sendPasswordReset(String email);
  Future<Either<Failure, void>> deleteAccount();
}
