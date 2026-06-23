import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../auth/domain/services/auth_service.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: AppColors.adminPageBackground,
        child: Column(
          children: [
            // Drawer Header
            Container(
              height: 120,
              width: double.infinity,
              color: AppColors.adminPrimary,
              padding: const EdgeInsets.only(top: 40, left: 24, right: 24, bottom: 20),
              child: const Row(
                children: [
                  Icon(Icons.school, color: Colors.white, size: 36),
                  SizedBox(width: 12),
                  Text(
                    'STUDFY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Navigation Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildDrawerItem(
                    context,
                    icon: Icons.home,
                    title: 'Dashboard',
                    onTap: () {
                      context.pop(); // Close drawer
                      context.goNamed(AppRoutes.adminDashboard);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.layers,
                    title: 'Instructors',
                    onTap: () {
                      context.pop();
                      context.goNamed(AppRoutes.adminInstructors);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.group,
                    title: 'Students',
                    onTap: () {
                      context.pop();
                      context.goNamed(AppRoutes.adminStudents);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.qr_code,
                    title: 'Registration Codes',
                    onTap: () {
                      context.pop();
                      context.goNamed(AppRoutes.adminEnrollmentCodes);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.book,
                    title: 'Subjects',
                    onTap: () {
                      context.pop();
                      context.goNamed(AppRoutes.adminSubjects);
                    },
                  ),
                ],
              ),
            ),
            // Logout Button at bottom
            const Divider(color: Colors.black12, height: 1),
            _buildDrawerItem(
              context,
              icon: Icons.logout,
              title: 'Logout',
              iconColor: const Color(0xFF800000),
              textColor: const Color(0xFF800000),
              onTap: () {
                AppDialog.confirm(
                  context,
                  title: 'Logout',
                  message: 'Are you sure you want to logout?',
                  type: DialogType.info,
                  confirmLabel: 'Logout',
                  onConfirm: () async {
                    final authService = const AuthService();
                    await authService.signOut();
                    if (context.mounted) {
                      context.read<AppState>().logout();
                      context.goNamed(AppRoutes.login);
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = AppColors.adminPrimary,
    Color textColor = Colors.black87,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 26),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      onTap: onTap,
    );
  }
}
