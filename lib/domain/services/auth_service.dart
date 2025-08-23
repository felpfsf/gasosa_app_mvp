import 'package:gasosa_app/core/either/either.dart';

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
  FResult<AuthUser> register(String name, String email, String password);
  FResult<AuthUser> loginWithEmail(String email, String password);
  FResult<AuthUser> loginWithGoogle();
  FResult<void> logout();
}
