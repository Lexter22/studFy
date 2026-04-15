import '../../../../core/services/error_telemetry.dart';
import '../models/app_user.dart';
import '../enums/user_role.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_profile_repository.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../data/repositories/firestore_user_profile_repository.dart';

class AuthService {
  final AuthRepository _repository;
  final UserProfileRepository _userProfileRepository;

  const AuthService({
    AuthRepository repository = const FirebaseAuthRepository(),
    UserProfileRepository userProfileRepository =
        const FirestoreUserProfileRepository(),
  }) : _repository = repository,
       _userProfileRepository = userProfileRepository;

  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final user = await _repository.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _withRole(user);
  }

  Future<void> sendEmailVerification() {
    return _repository.sendEmailVerification();
  }

  Future<void> sendPasswordResetEmail({required String email}) {
    return _repository.sendPasswordResetEmail(email: email);
  }

  Future<AppUser?> reloadCurrentUser() async {
    final user = await _repository.reloadCurrentUser();
    if (user == null) {
      return null;
    }
    return _withRole(user);
  }

  Future<void> signOut() {
    return _repository.signOut();
  }

  Future<void> upsertUserProfile({
    required String uid,
    required String email,
    required String displayName,
    required UserRole role,
  }) {
    return _userProfileRepository.upsertUserProfile(
      uid: uid,
      email: email,
      displayName: displayName,
      role: role,
    );
  }

  Stream<AppUser?> authStateChanges() {
    return _repository.authStateChanges().asyncMap((user) async {
      if (user == null) {
        return null;
      }
      return _withRole(user);
    });
  }

  Future<AppUser> _withRole(AppUser user) async {
    try {
      final role = await _userProfileRepository.getRoleByUid(user.uid);
      return user.copyWith(role: role);
    } catch (error, stackTrace) {
      ErrorTelemetry.captureException(
        error,
        stackTrace,
        operation: 'auth.role_lookup',
        extras: {'uid': user.uid, 'email': user.email ?? ''},
      );
      return user.copyWith(role: UserRole.unknown);
    }
  }
}
