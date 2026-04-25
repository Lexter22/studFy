import '../models/app_user.dart';

abstract class AuthRepository {
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> sendEmailVerification();

  Future<void> sendPasswordResetEmail({required String email, String? redirectTo});

  Future<AppUser?> reloadCurrentUser();

  Future<void> signOut();

  Stream<AppUser?> authStateChanges();
}
