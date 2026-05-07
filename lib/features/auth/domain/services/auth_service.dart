import '../../../../core/services/error_telemetry.dart';
import 'package:flutter/foundation.dart';
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
    // On web, redirect back to the current app origin so the OAuth callback
    // lands on the running Flutter app regardless of which port it's on.
    final redirectTo = kIsWeb
        ? Uri.base.origin
        : 'http://localhost:${const String.fromEnvironment('PORT', defaultValue: '8080')}';

    return _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectTo,
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
      UserRole role = await _userProfileRepository.getRoleByUid(user.uid);

      // The UID used for approval checks — may differ from the OAuth UID if
      // this is the user's first Google sign-in against a pre-created profile.
      String approvalUid = user.uid;

      // OAuth sign-in (e.g. Google) creates a new UID that won't match a
      // pre-created profile. Fall back to email lookup.
      if (role == UserRole.unknown && user.email != null) {
        role = await _userProfileRepository.getRoleByEmail(user.email!);

        if (role != UserRole.unknown) {
          // Use the original profile UID for the approval check so that
          // student_profiles / instructor_profiles rows are found correctly.
          // We do NOT update the PK to avoid FK cascade issues.
          final originalUid =
              await _userProfileRepository.getUidByEmail(user.email!);
          if (originalUid != null) {
            approvalUid = originalUid;
          }
        }
      }

      // If still unknown after email fallback, the user has no profile.
      if (role == UserRole.unknown) {
        await _client.auth.signOut();
        return user.copyWith(role: UserRole.unknown);
      }

      // Check that the profile is fully approved (has student/instructor row).
      final approved = await _userProfileRepository.isLoginApproved(
        uid: approvalUid,
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
