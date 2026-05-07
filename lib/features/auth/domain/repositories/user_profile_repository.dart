import '../enums/user_role.dart';

abstract class UserProfileRepository {
  Future<UserRole> getRoleByUid(String uid);

  /// Fallback lookup for OAuth sign-ins where the provider UID differs from
  /// the pre-created account UID. Returns [UserRole.unknown] if not found.
  Future<UserRole> getRoleByEmail(String email);

  /// Returns the profile UID for a given email, or null if not found.
  /// Used to resolve the original UID when an OAuth user signs in with an
  /// email that matches a pre-created profile.
  Future<String?> getUidByEmail(String email);

  Future<bool> isLoginApproved({required String uid, required UserRole role});

  Future<void> upsertUserProfile({
    required String uid,
    required String email,
    required String displayName,
    required UserRole role,
  });
}
