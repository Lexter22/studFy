import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/app_user.dart';
import '../../domain/models/auth_exception.dart' as app_auth;
import '../../domain/repositories/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  const SupabaseAuthRepository();

  GoTrueClient get _auth => Supabase.instance.client.auth;

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await _auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final User? user = response.user;
      if (user == null) {
        throw const app_auth.AuthException(
          code: 'no-current-user',
          message: 'No authenticated user found.',
        );
      }
      return _toAppUser(user);
    } on AuthApiException catch (error) {
      throw app_auth.AuthException(
        code: error.code ?? 'auth-error',
        message: error.message,
      );
    } on AuthRetryableFetchException catch (error) {
      throw app_auth.AuthException(
        code: 'network-error',
        message:
            'Unable to reach Supabase. Check internet, SUPABASE_URL, and project availability. Details: ${error.message}',
      );
    } catch (error) {
      throw app_auth.AuthException(
        code: 'auth-unexpected',
        message: 'Sign-in failed: $error',
      );
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null || user.email == null || user.email!.isEmpty) {
        throw const app_auth.AuthException(
          code: 'no-current-user',
          message: 'No authenticated user found.',
        );
      }

      await _auth.resend(type: OtpType.signup, email: user.email);
    } on AuthApiException catch (error) {
      throw app_auth.AuthException(
        code: error.code ?? 'auth-error',
        message: error.message,
      );
    } on AuthRetryableFetchException catch (error) {
      throw app_auth.AuthException(
        code: 'network-error',
        message:
            'Unable to reach Supabase. Check internet, SUPABASE_URL, and project availability. Details: ${error.message}',
      );
    } catch (error) {
      throw app_auth.AuthException(
        code: 'auth-unexpected',
        message: 'Unable to send verification email: $error',
      );
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email, String? redirectTo}) async {
    try {
      await _auth.resetPasswordForEmail(email.trim(), redirectTo: redirectTo);
    } on AuthApiException catch (error) {
      throw app_auth.AuthException(
        code: error.code ?? 'auth-error',
        message: error.message,
      );
    } on AuthRetryableFetchException catch (error) {
      throw app_auth.AuthException(
        code: 'network-error',
        message:
            'Unable to reach Supabase. Check internet, SUPABASE_URL, and project availability. Details: ${error.message}',
      );
    } catch (error) {
      throw app_auth.AuthException(
        code: 'auth-unexpected',
        message: 'Unable to send password reset email: $error',
      );
    }
  }

  @override
  Future<AppUser?> reloadCurrentUser() async {
    try {
      await _auth.refreshSession();
    } on AuthApiException {
      // Continue and fall back to currentUser to avoid hard-failing UI refresh.
    }

    final User? user = _auth.currentUser;
    if (user == null) {
      return null;
    }
    return _toAppUser(user);
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on AuthApiException catch (error) {
      throw app_auth.AuthException(
        code: error.code ?? 'auth-error',
        message: error.message,
      );
    } on AuthRetryableFetchException catch (error) {
      throw app_auth.AuthException(
        code: 'network-error',
        message:
            'Unable to reach Supabase. Check internet, SUPABASE_URL, and project availability. Details: ${error.message}',
      );
    } catch (error) {
      throw app_auth.AuthException(
        code: 'auth-unexpected',
        message: 'Sign-out failed: $error',
      );
    }
  }

  @override
  Stream<AppUser?> authStateChanges() {
    return _auth.onAuthStateChange.map((AuthState state) {
      final User? user = state.session?.user ?? _auth.currentUser;
      if (user == null) {
        return null;
      }
      return _toAppUser(user);
    });
  }

  AppUser _toAppUser(User user) {
    final String? firstName = user.userMetadata?['first_name'] as String?;
    final String? lastName = user.userMetadata?['last_name'] as String?;
    final String fallbackDisplay = [firstName, lastName]
        .whereType<String>()
        .where((name) => name.trim().isNotEmpty)
        .join(' ')
        .trim();

    return AppUser(
      uid: user.id,
      email: user.email,
      displayName:
          user.userMetadata?['display_name'] as String? ??
          user.email?.split('@').first ??
          (fallbackDisplay.isEmpty ? null : fallbackDisplay),
      isEmailVerified: user.emailConfirmedAt != null,
    );
  }
}
