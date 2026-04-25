import '../enums/user_role.dart';

abstract class UserProfileRepository {
  Future<UserRole> getRoleByUid(String uid);

  Future<bool> isLoginApproved({required String uid, required UserRole role});

  Future<void> upsertUserProfile({
    required String uid,
    required String email,
    required String displayName,
    required UserRole role,
  });
}
