import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/domain/models/instructor.dart';
import '../../features/admin/domain/models/student.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_instructor_profile_screen.dart';
import '../../features/admin/presentation/screens/admin_instructor_screen.dart';
import '../../features/admin/presentation/screens/admin_role_manager_screen.dart';
import '../../features/admin/presentation/screens/admin_students_profile_screen.dart';
import '../../features/admin/presentation/screens/admin_students_screen.dart';
import '../../features/admin/presentation/screens/admin_subjects_screen.dart';
import '../../features/admin/presentation/screens/admin_subjects_profile_screen.dart';
import '../../features/auth/domain/enums/user_role.dart';
import '../../features/auth/presentation/screens/change_password_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/account_creation_screen.dart';
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
  static const accountCreation = 'account-creation';
  static const adminDashboard = 'admin-dashboard';
  static const adminInstructors = 'admin-instructors';
  static const adminInstructorProfile = 'admin-instructor-profile';
  static const adminRoleManager = 'admin-role-manager';
  static const adminStudents = 'admin-students';
  static const adminStudentsProfile = 'admin-students-profile';
  static const adminSubjects = 'admin-subjects';
  static const adminSubjectsProfile = 'admin-subjects-profile';
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
      final bool isGoingToForgotPassword = state.matchedLocation == '/forgot-password';
      final bool isGoingToChangePassword = state.matchedLocation == '/change-password';
      final bool isGoingToVerifyEmail = state.matchedLocation == '/verify-email';
      
      final bool isAdminRoute = state.matchedLocation.startsWith('/admin');
      final bool isProfessorRoute = state.matchedLocation.startsWith('/professor');
      final bool isStudentRoute = state.matchedLocation.startsWith('/student');
      
      final bool isGoingToAccountCreation = state.matchedLocation == '/account-creation';

      final bool isAuthRoute = isGoingToLogin || isGoingToForgotPassword || 
                               isGoingToChangePassword || isGoingToVerifyEmail ||
                               isGoingToAccountCreation;
      
      final role = appState.currentUser?.role ?? UserRole.unknown;

      // Basic Auth Guard
      if (!appState.isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      // Email Verification Guard
      if (appState.isAuthenticated && 
          appState.currentUser != null && 
          !appState.currentUser!.isEmailVerified && 
          !isGoingToVerifyEmail) {
        return '/verify-email';
      }

      // Already logged in redirect
      if (appState.isAuthenticated && isGoingToLogin) {
        return AppRoutes.pathForRole(role);
      }

      // Role-based protection
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
        path: '/account-creation',
        name: AppRoutes.accountCreation,
        builder: (context, state) => const AccountCreationScreen(),
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
          // FIX: Handle the Map passed via state.extra
          final extraData = state.extra as Map<String, dynamic>;
          final Instructor instructor = extraData['instructor'] as Instructor;
          final String? request = extraData['request'] as String?;
          
          return AdminInstructorProfileScreen(
            instructor: instructor,
            initialRequest: request, // Pass the request to the profile screen
          );
        },
      ),
      GoRoute(
        path: '/admin/roles',
        name: AppRoutes.adminRoleManager,
        builder: (context, state) => const AdminRoleManagerScreen(),
      ),
      GoRoute(
        path: '/admin/students',
        name: AppRoutes.adminStudents,
        builder: (context, state) => const AdminStudentsScreen(),
        routes: [
          GoRoute(
            name: AppRoutes.adminStudentsProfile,
            path: 'profile',
            pageBuilder: (context, state) {
              final extraData = state.extra as Map<String, dynamic>;
              final studentMap = extraData['student'] as Map<String, dynamic>;
              final studentData = StudentData(
                name: studentMap['name'] as String,
                course: studentMap['course'] as String,
                yearSection: studentMap['yearSection'] as String,
                subjects: (studentMap['subjects'] as List?)?.cast<String>() ?? [],
              );

              return CustomTransitionPage(
                key: state.pageKey,
                child: AdminStudentsProfileScreen(student: studentData),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 200),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/admin/subjects',
        name: AppRoutes.adminSubjects,
        builder: (context, state) => const AdminSubjectsScreen(),
      ),
      GoRoute(
        path: '/admin/subjects/profile',
        name: AppRoutes.adminSubjectsProfile,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return AdminSubjectsProfileScreen(
            subjectName: extra['subjectName'] as String,
            courseSection: extra['courseSection'] as String,
            professor: extra['professor'] as String,
          );
        },
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