import '../../domain/models/auth_exception.dart';
import '../../domain/models/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class LocalAuthRepository implements AuthRepository {
  const LocalAuthRepository();

  static AppUser? _currentUser;

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      throw const AuthException(
        code: 'invalid-credentials',
        message: 'Email and password are required.',
      );
    }

    _currentUser = AppUser(
      uid: normalizedEmail,
      email: normalizedEmail,
      displayName: normalizedEmail.split('@').first,
      isEmailVerified: true,
    );

    return _currentUser!;
  }

  @override
  Future<void> sendEmailVerification() async {
    if (_currentUser == null) {
      throw const AuthException(
        code: 'no-current-user',
        message: 'No authenticated user found.',
      );
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email, String? redirectTo}) async {
    if (email.trim().isEmpty) {
      throw const AuthException(
        code: 'invalid-email',
        message: 'Please enter a valid email address.',
      );
    }
  }

  @override
  Future<AppUser?> reloadCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
  }

  @override
  Stream<AppUser?> authStateChanges() {
    return Stream<AppUser?>.value(_currentUser);
  }
}
