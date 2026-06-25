import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/state/app_state.dart';
import 'admin_drawer.dart';
import 'admin_floating_nav_bar.dart';

class AdminShell extends StatelessWidget {
  final Widget child;
  final GoRouterState state;

  const AdminShell({
    super.key,
    required this.child,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final path = state.uri.path;

    // Determine active index for floating nav bar based on path
    int currentIndex = 0;
    if (path.startsWith('/admin/dashboard')) {
      currentIndex = 0;
    } else if (path.startsWith('/admin/instructors') || path.startsWith('/admin/roles')) {
      currentIndex = 1;
    } else if (path.startsWith('/admin/students')) {
      currentIndex = 2;
    } else if (path.startsWith('/admin/subjects')) {
      currentIndex = 3;
    }

    final bool isEnrollmentCodes = path == '/admin/enrollment-codes';
    final appState = context.watch<AppState>();
    final displayName = appState.currentUser?.displayName ?? 'Admin';

    return Scaffold(
      backgroundColor: AppColors.adminPageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.adminPrimary,
        elevation: 0,
        toolbarHeight: 70,
        title: const Row(
          children: [
            Icon(Icons.school, color: Colors.white, size: 28),
            SizedBox(width: 8),
            Text(
              'STUDFY',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
        automaticallyImplyLeading: isEnrollmentCodes,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: isEnrollmentCodes ? const AdminDrawer() : null,
      body: Stack(
        children: [
          // Inner page content transitions within the shell
          child,
          if (!isEnrollmentCodes)
            AdminFloatingNavBar(currentIndex: currentIndex),
        ],
      ),
    );
  }
}
