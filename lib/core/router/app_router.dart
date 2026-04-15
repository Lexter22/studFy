import 'package:go_router/go_router.dart';

import '../../features/admin/domain/models/instructor.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_instructor_profile_screen.dart';
import '../../features/admin/presentation/screens/admin_instructor_screen.dart';
import '../../features/admin/presentation/screens/admin_role_manager_screen.dart';
import '../../features/auth/domain/enums/user_role.dart';
import '../../features/auth/presentation/screens/change_password_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/verify_email_screen.dart';
import '../../features/professor/presentation/screens/professor_dashboard_screen.dart';
import '../../features/student/presentation/screens/student_dashboard_screen.dart';
import '../state/app_state.dart';

abstract class AppRoutes {
  static const login = 'login';
  static const forgotPassword = 'forgot-password';
  static const changePassword = 'change-password';
  static const verifyEmail = 'verify-email';
  static const adminDashboard = 'admin-dashboard';
  static const adminInstructors = 'admin-instructors';
  static const adminInstructorProfile = 'admin-instructor-profile';
  static const adminRoleManager = 'admin-role-manager';
  static const professorDashboard = 'professor-dashboard';
  static const studentDashboard = 'student-dashboard';

  static String pathForRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return '/admin/dashboard';
      case UserRole.professor:
        return '/professor/dashboard';
      case UserRole.student:
        return '/student/dashboard';
      case UserRole.unknown:
        return '/login';
    }
  }
}

GoRouter createAppRouter(AppState appState) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: appState,
    redirect: (context, state) {
      final bool isGoingToLogin = state.matchedLocation == '/login';
      final bool isGoingToForgotPassword =
          state.matchedLocation == '/forgot-password';
      final bool isGoingToChangePassword =
          state.matchedLocation == '/change-password';
      final bool isGoingToVerifyEmail =
          state.matchedLocation == '/verify-email';
      final bool isAdminRoute = state.matchedLocation.startsWith('/admin');
      final bool isProfessorRoute = state.matchedLocation.startsWith(
        '/professor',
      );
      final bool isStudentRoute = state.matchedLocation.startsWith('/student');
      final bool isAuthRoute =
          isGoingToLogin ||
          isGoingToForgotPassword ||
          isGoingToChangePassword ||
          isGoingToVerifyEmail;
      final role = appState.currentUser?.role ?? UserRole.unknown;

      final bool requiresVerifiedEmail =
          appState.currentUser != null &&
          !appState.currentUser!.isEmailVerified &&
          !isGoingToVerifyEmail;

      if (!appState.isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      if (appState.isAuthenticated && requiresVerifiedEmail) {
        return '/verify-email';
      }

      if (appState.isAuthenticated && isGoingToLogin) {
        if (appState.currentUser != null &&
            !appState.currentUser!.isEmailVerified) {
          return '/verify-email';
        }
        return AppRoutes.pathForRole(role);
      }

      if (appState.isAuthenticated &&
          appState.currentUser != null &&
          appState.currentUser!.isEmailVerified &&
          isGoingToVerifyEmail) {
        return AppRoutes.pathForRole(role);
      }

      if (appState.isAuthenticated && appState.currentUser != null) {
        if (role == UserRole.admin && (isProfessorRoute || isStudentRoute)) {
          return AppRoutes.pathForRole(role);
        }

        if (role == UserRole.professor && (isAdminRoute || isStudentRoute)) {
          return AppRoutes.pathForRole(role);
        }

        if (role == UserRole.student && (isAdminRoute || isProfessorRoute)) {
          return AppRoutes.pathForRole(role);
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/change-password',
        name: AppRoutes.changePassword,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        name: AppRoutes.verifyEmail,
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        name: AppRoutes.adminDashboard,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/instructors',
        name: AppRoutes.adminInstructors,
        builder: (context, state) => const AdminInstructorScreen(),
      ),
      GoRoute(
        path: '/admin/instructors/profile',
        name: AppRoutes.adminInstructorProfile,
        builder: (context, state) {
          final Instructor instructor = state.extra! as Instructor;
          return AdminInstructorProfileScreen(instructor: instructor);
        },
      ),
      GoRoute(
        path: '/admin/roles',
        name: AppRoutes.adminRoleManager,
        builder: (context, state) => const AdminRoleManagerScreen(),
      ),
      GoRoute(
        path: '/professor/dashboard',
        name: AppRoutes.professorDashboard,
        builder: (context, state) => const ProfessorDashboardScreen(),
      ),
      GoRoute(
        path: '/student/dashboard',
        name: AppRoutes.studentDashboard,
        builder: (context, state) => const StudentDashboardScreen(),
      ),
    ],
  );
}
