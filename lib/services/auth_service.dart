import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Thin wrapper over [FirebaseAuth] so screens never talk to the SDK directly.
class AuthService {
  AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
      : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: const ['email']);

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Google sign-in: the native account picker on mobile, a popup on web.
  ///
  /// Firebase's generic OAuth flow (`signInWithProvider`) cannot be used here.
  /// Android special-cases `google.com` and expects Play Services, so the
  /// redirect flow fails there with a bare "An internal error has occurred".
  ///
  /// Google is a verified provider, so signing in with an address that already
  /// has a password account links the two and keeps the same uid — and
  /// therefore the same data.
  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider()..addScope('email');
      return _auth.signInWithPopup(provider);
    }

    final account = await _googleSignIn.signIn();
    if (account == null) {
      // Dismissing the account picker is not a failure worth reporting.
      throw FirebaseAuthException(
        code: 'canceled',
        message: 'Google sign-in was cancelled.',
      );
    }

    final authentication = await account.authentication;
    return _auth.signInWithCredential(
      GoogleAuthProvider.credential(
        accessToken: authentication.accessToken,
        idToken: authentication.idToken,
      ),
    );
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  /// Clears the cached Google account too, so the next sign-in shows the
  /// picker instead of silently reusing the account that just signed out.
  Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // Never block the Firebase sign-out on the plugin's cache.
      }
    }
    await _auth.signOut();
  }
}
