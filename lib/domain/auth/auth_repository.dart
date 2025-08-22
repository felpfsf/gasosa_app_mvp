import 'package:firebase_auth/firebase_auth.dart';

abstract interface class AuthRepository {
  Stream<User?> authStateChanges();
  Future<void> loginWithEmail(String email, String password);
  Future<void> registerWithEmail(String email, String password);
  Future<void> loginWithGoogle();
  Future<void> logout();
}
