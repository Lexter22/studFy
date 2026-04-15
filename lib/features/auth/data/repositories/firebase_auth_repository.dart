import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/models/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  const FirebaseAuthRepository();

  FirebaseAuth get _auth => FirebaseAuth.instance;

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final UserCredential credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final User user = credential.user ?? _auth.currentUser!;
    return AppUser.fromFirebaseUser(user);
  }

  @override
  Future<void> sendEmailVerification() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No authenticated user found.',
      );
    }

    await user.sendEmailVerification();
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  @override
  Future<AppUser?> reloadCurrentUser() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      return null;
    }

    await user.reload();
    final User? reloaded = _auth.currentUser;
    if (reloaded == null) {
      return null;
    }

    return AppUser.fromFirebaseUser(reloaded);
  }

  @override
  Future<void> signOut() {
    return _auth.signOut();
  }

  @override
  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().map(
      (user) => user == null ? null : AppUser.fromFirebaseUser(user),
    );
  }
}
