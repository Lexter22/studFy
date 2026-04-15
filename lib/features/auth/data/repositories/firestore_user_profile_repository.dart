import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/enums/user_role.dart';
import '../../domain/repositories/user_profile_repository.dart';

class FirestoreUserProfileRepository implements UserProfileRepository {
  const FirestoreUserProfileRepository();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  @override
  Future<UserRole> getRoleByUid(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      return UserRole.unknown;
    }

    final data = doc.data();
    if (data == null) {
      return UserRole.unknown;
    }

    final role = data['role'] as String?;
    return UserRoleX.fromString(role);
  }

  @override
  Future<void> upsertUserProfile({
    required String uid,
    required String email,
    required String displayName,
    required UserRole role,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'email': email.trim(),
      'displayName': displayName.trim(),
      'role': role.value,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
