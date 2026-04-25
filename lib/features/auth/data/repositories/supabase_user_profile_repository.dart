import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/enums/user_role.dart';
import '../../domain/models/auth_exception.dart' as app_auth;
import '../../domain/repositories/user_profile_repository.dart';

class SupabaseUserProfileRepository implements UserProfileRepository {
  const SupabaseUserProfileRepository();

  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<UserRole> getRoleByUid(String uid) async {
    try {
      final Map<String, dynamic>? row = await _client
          .from('profiles')
          .select('role')
          .eq('id', uid)
          .maybeSingle();

      return UserRoleX.fromString(row?['role'] as String?);
    } on PostgrestException catch (error) {
      throw app_auth.AuthException(
        code: error.code ?? 'db-error',
        message: error.message,
      );
    }
  }

  @override
  Future<bool> isLoginApproved({
    required String uid,
    required UserRole role,
  }) async {
    if (role == UserRole.admin) return true;

    try {
      if (role == UserRole.student) {
        // Must have a student_profiles row to be approved
        final row = await _client
            .from('student_profiles')
            .select('profile_id')
            .eq('profile_id', uid)
            .maybeSingle();
        return row != null;
      }

      if (role == UserRole.professor) {
        // Must have an instructor_profiles row to be approved
        final row = await _client
            .from('instructor_profiles')
            .select('profile_id')
            .eq('profile_id', uid)
            .maybeSingle();
        return row != null;
      }

      return false;
    } on PostgrestException catch (error) {
      throw app_auth.AuthException(
        code: error.code ?? 'db-error',
        message: error.message,
      );
    }
  }

  @override
  Future<void> upsertUserProfile({
    required String uid,
    required String email,
    required String displayName,
    required UserRole role,
  }) async {
    try {
      // Only insert if profile doesn't exist — never overwrite existing role
      await _client.from('profiles').upsert({
        'id': uid,
        'email': email.trim().toLowerCase(),
        'display_name': displayName.trim(),
        'first_name': displayName.trim().split(' ').first,
        'last_name': displayName.trim().split(' ').length > 1 ? displayName.trim().split(' ').last : '',
        'role': UserRole.unknown == role ? 'student' : role.value,
      }, onConflict: 'id', ignoreDuplicates: true);
    } on PostgrestException catch (error) {
      throw app_auth.AuthException(
        code: error.code ?? 'db-error',
        message: error.message,
      );
    }
  }
}
