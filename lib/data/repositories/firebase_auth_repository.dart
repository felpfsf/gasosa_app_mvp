import 'package:firebase_auth/firebase_auth.dart';
import 'package:gasosa_app/domain/auth/auth_repository.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({required FirebaseAuth? auth, required GoogleSignIn? google})
    : _auth = auth ?? FirebaseAuth.instance,
      _google = google ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _google;

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  @override
  Future<void> loginWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> loginWithGoogle() async {
    try {
      final account = await _google.authenticate(
        scopeHint: ['email', 'profile', 'openid'],
      );
    } on Exception catch (e) {
      // TODO
      print('Error during Google sign-in: $e');
    }
  }

  @override
  Future<void> logout() async {
    await _auth.signOut();
  }

  @override
  Future<void> registerWithEmail(String email, String password) {
    return _auth.createUserWithEmailAndPassword(email: email, password: password);
  }
}
