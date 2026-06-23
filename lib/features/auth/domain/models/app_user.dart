import '../enums/user_role.dart';

class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final bool isEmailVerified;
  final UserRole role;

  /// True for admin-created accounts that still use the default password and
  /// must set their own password before using the app.
  final bool mustChangePassword;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.isEmailVerified,
    this.role = UserRole.unknown,
    this.mustChangePassword = false,
  });

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    bool? isEmailVerified,
    UserRole? role,
    bool? mustChangePassword,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      role: role ?? this.role,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
    );
  }
}
