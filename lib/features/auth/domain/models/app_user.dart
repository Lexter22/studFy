import '../enums/user_role.dart';

class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final bool isEmailVerified;
  final UserRole role;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.isEmailVerified,
    this.role = UserRole.unknown,
  });

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    bool? isEmailVerified,
    UserRole? role,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      role: role ?? this.role,
    );
  }
}
