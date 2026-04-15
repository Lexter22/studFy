import '../enums/user_role.dart';

abstract class UserProfileRepository {
  Future<UserRole> getRoleByUid(String uid);

  Future<void> upsertUserProfile({
    required String uid,
    required String email,
    required String displayName,
    required UserRole role,
  });
}
