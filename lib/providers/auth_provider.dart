import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges();
});

/// The signed-in user, or `null`.
///
/// Falls back to the SDK's cached user while the stream delivers its first
/// value, so a restart with a persisted session never flickers through a
/// signed-out state.
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value ??
      ref.watch(authServiceProvider).currentUser;
});

/// Firestore key for the signed-in account. Empty while signed out.
///
/// Every data provider watches this, so switching accounts tears down the old
/// controllers and rebuilds them against the new user's collections.
final currentUserIdProvider = Provider<String>((ref) {
  return ref.watch(currentUserProvider)?.uid ?? '';
});

/// Sets up the account's Firestore tree. Returns `null` on success, or the
/// error that stopped it.
///
/// A failure must not block an otherwise valid sign-in — it is retried on the
/// next one — but it must not be invisible either: undeployed security rules
/// reject the profile write, and silently swallowing that looks exactly like
/// "my data vanished".
Future<Object?> syncUserWorkspace(FirestoreService service, User user) async {
  try {
    await service.prepareUserWorkspace(
      userId: user.uid,
      email: user.email,
      displayName: user.displayName,
    );
    return null;
  } catch (error) {
    debugPrint('Workspace setup failed for ${user.uid}: $error');
    return error;
  }
}
