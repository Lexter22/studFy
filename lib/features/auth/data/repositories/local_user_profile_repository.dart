import '../../domain/enums/user_role.dart';
import '../../domain/repositories/user_profile_repository.dart';

class LocalUserProfileRepository implements UserProfileRepository {
  const LocalUserProfileRepository();

  static final Map<String, UserRole> _rolesByUid = <String, UserRole>{};

  @override
  Future<UserRole> getRoleByUid(String uid) async {
    return _rolesByUid[uid] ?? UserRole.student;
  }

  @override
  Future<bool> isLoginApproved({
    required String uid,
    required UserRole role,
  }) async {
    return true;
  }

  @override
  Future<void> upsertUserProfile({
    required String uid,
    required String email,
    required String displayName,
    required UserRole role,
  }) async {
    _rolesByUid[uid] = role;
  }
}
