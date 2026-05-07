import '../../domain/enums/user_role.dart';
import '../../domain/repositories/user_profile_repository.dart';

class LocalUserProfileRepository implements UserProfileRepository {
  const LocalUserProfileRepository();

  static final Map<String, UserRole> _rolesByUid = <String, UserRole>{};
  static final Map<String, UserRole> _rolesByEmail = <String, UserRole>{};

  @override
  Future<UserRole> getRoleByUid(String uid) async {
    return _rolesByUid[uid] ?? UserRole.unknown;
  }

  @override
  Future<UserRole> getRoleByEmail(String email) async {
    return _rolesByEmail[email.trim().toLowerCase()] ?? UserRole.unknown;
  }

  @override
  Future<String?> getUidByEmail(String email) async {
    // In local repo, find the UID that maps to this email's role
    final role = _rolesByEmail[email.trim().toLowerCase()];
    if (role == null) return null;
    return _rolesByUid.entries
        .where((e) => e.value == role)
        .map((e) => e.key)
        .firstOrNull;
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
    _rolesByEmail[email.trim().toLowerCase()] = role;
  }
}
