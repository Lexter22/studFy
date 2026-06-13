import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../features/auth/domain/services/auth_service.dart';

class ProfessorDrawer extends StatelessWidget {
  const ProfessorDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().currentUser;

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.authPrimary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 10),
                Text(
                  user?.displayName ?? 'Professor',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: AppColors.authPrimary),
            title: const Text('Dashboard', style: TextStyle(color: Colors.black87)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            onTap: () {
              Navigator.pop(context);
              context.goNamed(AppRoutes.professorDashboard);
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.black54),
            title: const Text('Logout', style: TextStyle(color: Colors.black87)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            onTap: () {
              Navigator.pop(context);
              AppDialog.confirm(
                context,
                title: 'Logout',
                message: 'Are you sure you want to logout?',
                type: DialogType.info,
                confirmLabel: 'Logout',
                onConfirm: () async {
                  await const AuthService().signOut();
                  if (!context.mounted) return;
                  context.read<AppState>().logout();
                  context.goNamed(AppRoutes.login);
                },
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
