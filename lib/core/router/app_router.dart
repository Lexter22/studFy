import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/admin/domain/models/instructor.dart';
import '../../features/admin/domain/models/student.dart';
import '../../features/admin/presentation/screens/admin_enrollment_codes_screen.dart';
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
import '../../features/professor/presentation/screens/professor_classes_screen.dart';
import '../../features/professor/presentation/screens/professor_modules_screen.dart';
import '../../features/professor/presentation/screens/professor_assignments_screen.dart';
import '../../features/student/presentation/screens/student_dashboard_screen.dart';
import '../../features/student/presentation/screens/student_todo_screen.dart';
import '../../features/student/presentation/screens/student_modules_screen.dart';
import '../state/app_state.dart';

abstract class AppRoutes {
  static const login = 'login';
  static const forgotPassword = 'forgot-password';
  static const changePassword = 'change-password';
  static const verifyEmail = 'verify-email';
  static const accountCreation = 'account-creation';
  static const adminEnrollmentCodes = 'admin-enrollment-codes';
  static const adminDashboard = 'admin-dashboard';
  static const adminInstructors = 'admin-instructors';
  static const adminInstructorProfile = 'admin-instructor-profile';
  static const adminRoleManager = 'admin-role-manager';
  static const adminStudents = 'admin-students';
  static const adminStudentsProfile = 'admin-students-profile';
  static const adminSubjects = 'admin-subjects';
  static const adminSubjectsProfile = 'admin-subjects-profile';
  static const professorDashboard = 'professor-dashboard';
  static const professorClasses = 'professor-classes';
  static const professorModules = 'professor-modules';
  static const professorAssignments = 'professor-assignments';
  static const studentDashboard = 'student-dashboard';
  static const studentTodo = 'student-todo';
  static const studentModules = 'student-modules';

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

Page<dynamic> _seamlessPage(LocalKey key, Widget child) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 200),
  );
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

      // Forced password change guard (admin-created accounts on default password)
      if (appState.isAuthenticated &&
          appState.currentUser != null &&
          appState.currentUser!.isEmailVerified &&
          appState.currentUser!.mustChangePassword &&
          !isGoingToChangePassword) {
        return '/change-password';
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
        pageBuilder: (context, state) => _seamlessPage(state.pageKey, const LoginScreen()),
      ),
      GoRoute(
        path: '/forgot-password',
        name: AppRoutes.forgotPassword,
        pageBuilder: (context, state) => _seamlessPage(state.pageKey, const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: '/change-password',
        name: AppRoutes.changePassword,
        pageBuilder: (context, state) => _seamlessPage(state.pageKey, const ChangePasswordScreen()),
      ),
      GoRoute(
        path: '/verify-email',
        name: AppRoutes.verifyEmail,
        pageBuilder: (context, state) => _seamlessPage(state.pageKey, const VerifyEmailScreen()),
      ),
      GoRoute(
        path: '/account-creation',
        name: AppRoutes.accountCreation,
        pageBuilder: (context, state) => _seamlessPage(state.pageKey, const AccountCreationScreen()),
      ),
      GoRoute(
        path: '/admin/enrollment-codes',
        name: AppRoutes.adminEnrollmentCodes,
        pageBuilder: (context, state) => _seamlessPage(state.pageKey, const AdminEnrollmentCodesScreen()),
      ),
      GoRoute(
        path: '/admin/dashboard',
        name: AppRoutes.adminDashboard,
        pageBuilder: (context, state) => _seamlessPage(state.pageKey, const AdminDashboardScreen()),
      ),
      GoRoute(
        path: '/admin/instructors',
        name: AppRoutes.adminInstructors,
        pageBuilder: (context, state) => _seamlessPage(state.pageKey, const AdminInstructorScreen()),
      ),
      GoRoute(
        path: '/admin/instructors/profile/:profileId',
        name: AppRoutes.adminInstructorProfile,
        pageBuilder: (context, state) {
          final profileId = state.pathParameters['profileId']!;
          final extra = state.extra;
          final extraData = extra is Map<String, dynamic> ? extra : <String, dynamic>{};
          
          Instructor? instructor = extraData['instructor'] as Instructor?;
          if (instructor == null) {
            final instructors = context.read<AppState>().instructors;
            instructor = instructors.where((i) => i.profileId == profileId).firstOrNull;
          }
          final String? request = extraData['request']?.toString();

          // Guard: if instructor is missing/not found, bounce back to instructors list
          if (instructor == null) {
            return _seamlessPage(state.pageKey, const AdminInstructorScreen());
          }

          return _seamlessPage(
            state.pageKey,
            AdminInstructorProfileScreen(
              profileId: profileId,
              instructor: instructor,
              initialRequest: request,
            ),
          );
        },
      ),
      GoRoute(
        path: '/admin/roles',
        name: AppRoutes.adminRoleManager,
        pageBuilder: (context, state) => _seamlessPage(state.pageKey, const AdminRoleManagerScreen()),
      ),
      GoRoute(
        path: '/admin/students',
        name: AppRoutes.adminStudents,
        pageBuilder: (context, state) => _seamlessPage(state.pageKey, const AdminStudentsScreen()),
        routes: [
          GoRoute(
            name: AppRoutes.adminStudentsProfile,
            path: 'profile/:profileId',
            pageBuilder: (context, state) {
              final profileId = state.pathParameters['profileId']!;
              final extra = state.extra;
              StudentData? student;
              if (extra is Map<String, dynamic>) {
                student = extra['student'] as StudentData?;
              }
              return _seamlessPage(state.pageKey, AdminStudentsProfileScreen(profileId: profileId, student: student));
            },
          ),
        ],
      ),
      GoRoute(
        path: '/admin/subjects',
        name: AppRoutes.adminSubjects,
        pageBuilder: (context, state) => _seamlessPage(state.pageKey, const AdminSubjectsScreen()),
      ),
      GoRoute(
        path: '/admin/subjects/profile',
        name: AppRoutes.adminSubjectsProfile,
        pageBuilder: (context, state) {
          final extra = state.extra;
          final extraData = extra is Map<String, dynamic> ? extra : <String, dynamic>{};

          final subjectName = extraData['subjectName']?.toString() ?? '';
          final courseSection = extraData['courseSection']?.toString() ?? '';
          final professor = extraData['professor']?.toString() ?? '';

          // Guard: if required fields are missing, bounce back to subjects list
          if (subjectName.isEmpty) {
            return _seamlessPage(state.pageKey, const AdminSubjectsScreen());
          }

          return _seamlessPage(
            state.pageKey,
            AdminSubjectsProfileScreen(
              subjectId: extraData['subjectId']?.toString(),
              subjectName: subjectName,
              courseSection: courseSection,
              professor: professor,
              pendingRequest: extraData['pendingRequest']?.toString(),
            ),
          );
        },
      ),
      GoRoute(
        path: '/professor/dashboard',
        name: AppRoutes.professorDashboard,
        pageBuilder: (context, state) => _seamlessPage(state.pageKey, const ProfessorDashboardScreen()),
      ),
      GoRoute(
        path: '/professor/classes',
        name: AppRoutes.professorClasses,
        pageBuilder: (context, state) => _seamlessPage(state.pageKey, const ProfessorClassesScreen()),
      ),
      GoRoute(
        path: '/professor/modules',
        name: AppRoutes.professorModules,
        pageBuilder: (context, state) => _seamlessPage(state.pageKey, const ProfessorModulesScreen()),
      ),
      GoRoute(
        path: '/professor/assignments',
        name: AppRoutes.professorAssignments,
        pageBuilder: (context, state) => _seamlessPage(state.pageKey, const ProfessorAssignmentsScreen()),
      ),
      GoRoute(
        path: '/student/dashboard',
        name: AppRoutes.studentDashboard,
        pageBuilder: (context, state) => _seamlessPage(state.pageKey, const StudentDashboardScreen()),
      ),
      GoRoute(
        path: '/student/todo',
        name: AppRoutes.studentTodo,
        pageBuilder: (context, state) => _seamlessPage(state.pageKey, const StudentTodoScreen()),
      ),
      GoRoute(
        path: '/student/modules',
        name: AppRoutes.studentModules,
        pageBuilder: (context, state) {
          final subjectId = state.uri.queryParameters['subjectId'];
          return _seamlessPage(state.pageKey, StudentModulesScreen(subjectId: subjectId));
        },
      ),
    ],
  );
}
