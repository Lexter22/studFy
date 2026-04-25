import '../../../../core/services/error_telemetry.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';
import '../models/auth_exception.dart' as app_auth;
import '../enums/user_role.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_profile_repository.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../data/repositories/supabase_user_profile_repository.dart';

class AuthService {
  final AuthRepository _repository;
  final UserProfileRepository _userProfileRepository;

  const AuthService({
    AuthRepository repository = const SupabaseAuthRepository(),
    UserProfileRepository userProfileRepository =
        const SupabaseUserProfileRepository(),
  }) : _repository = repository,
       _userProfileRepository = userProfileRepository;

  SupabaseClient get _client => Supabase.instance.client;

  Future<bool> signInWithGoogle() {
    return _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'http://localhost:8080',
    );
  }

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
    return _repository.sendPasswordResetEmail(
      email: email,
      redirectTo: 'http://localhost:${const String.fromEnvironment('PORT', defaultValue: '8080')}/change-password',
    );
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

  Future<void> registerPendingAccount({
    required String email,
    required String password,
    required String firstName,
    required String middleName,
    required String lastName,
    required UserRole role,
    String? studentNumber,
    String? enrollmentCode,
    String? instructorId,
    String? department,
  }) async {
    if (role != UserRole.student && role != UserRole.professor) {
      throw const app_auth.AuthException(
        code: 'invalid-role',
        message: 'Only student or professor accounts can self-register.',
      );
    }

    final cleanEmail = email.trim().toLowerCase();
    final cleanFirst = firstName.trim();
    final cleanMiddle = middleName.trim();
    final cleanLast = lastName.trim();
    final displayName = '$cleanFirst $cleanLast'.trim();

    try {
      final response = await _client.auth.signUp(
        email: cleanEmail,
        password: password,
        data: {
          'first_name': cleanFirst,
          'middle_name': cleanMiddle.isEmpty ? null : cleanMiddle,
          'last_name': cleanLast,
          'display_name': displayName,
          'role': role.value,
        },
      );

      final user = response.user;
      if (user == null) {
        throw const app_auth.AuthException(
          code: 'signup-failed',
          message: 'Account registration failed. Please try again.',
        );
      }

      // On web, signUp may not establish a session immediately.
      if (response.session == null) {
        await _client.auth.signInWithPassword(
          email: cleanEmail,
          password: password,
        );
      }

      if (role == UserRole.student) {
        // Redeem enrollment code via Edge Function
        final codeResponse = await _client.functions.invoke(
          'redeem-enrollment-code',
          body: {'code': (enrollmentCode ?? '').trim()},
        );
        if (codeResponse.status != 200) {
          // Rollback: delete the auth user
          await _client.auth.admin.deleteUser(user.id);
          final message = codeResponse.data?['error']?.toString() ?? 'Invalid enrollment code.';
          throw app_auth.AuthException(code: 'invalid-code', message: message);
        }
      } else {
        // Professor: submit pending request as before
        final metadata = <String, dynamic>{
          'requested_role': role.value,
          'email': cleanEmail,
          'display_name': displayName,
          'instructor_id': (instructorId ?? '').trim(),
          'department': (department ?? '').trim(),
        };
        await _client.from('requests').insert({
          'kind': 'role_assignment',
          'title': displayName,
          'details': 'New ${role.value} account registration',
          'status': 'pending',
          'requester_profile_id': user.id,
          'metadata': metadata,
        });
      }

      if (_client.auth.currentSession != null) {
        await _client.auth.signOut();
      }
    } on AuthApiException catch (error) {
      throw app_auth.AuthException(
        code: error.code ?? 'auth-error',
        message: error.message,
      );
    } on AuthRetryableFetchException catch (error) {
      throw app_auth.AuthException(
        code: 'network-error',
        message: 'Unable to reach Supabase. Details: ${error.message}',
      );
    } on PostgrestException catch (error) {
      throw app_auth.AuthException(
        code: error.code ?? 'db-error',
        message: error.message,
      );
    }
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

      // If student role but no student_profiles row = not pre-registered
      // If professor role but no instructor_profiles row = not pre-registered  
      // Only admin, or users with matching role profiles, are allowed
      final approved = await _userProfileRepository.isLoginApproved(
        uid: user.uid,
        role: role,
      );

      if (!approved) {
        await _client.auth.signOut();
        return user.copyWith(role: UserRole.unknown);
      }

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
