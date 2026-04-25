enum UserRole { admin, professor, student, unknown }

extension UserRoleX on UserRole {
  String get value {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.professor:
        return 'professor';
      case UserRole.student:
        return 'student';
      case UserRole.unknown:
        return 'unknown';
    }
  }

  static UserRole fromString(String? role) {
    switch (role?.trim().toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'professor':
        return UserRole.professor;
      case 'student':
        return UserRole.student;
      default:
        return UserRole.unknown;
    }
  }
}
