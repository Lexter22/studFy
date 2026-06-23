import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../auth/domain/services/auth_service.dart';

class AdminFloatingNavBar extends StatefulWidget {
  final int currentIndex;

  const AdminFloatingNavBar({
    super.key,
    required this.currentIndex,
  });

  @override
  State<AdminFloatingNavBar> createState() => _AdminFloatingNavBarState();
}

class _AdminFloatingNavBarState extends State<AdminFloatingNavBar> {
  final AuthService _authService = const AuthService();
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width > 800
                ? 650
                : MediaQuery.of(context).size.width - 20,
          ),
          child: Container(
            height: 70,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.adminPrimary,
              borderRadius: BorderRadius.circular(35),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildNavItem(Icons.home, 'DASHBOARD', 0),
                _buildNavItem(Icons.manage_accounts, 'ROLES', 1),
                _buildNavItem(Icons.layers, 'INSTRUCTOR', 2),
                _buildNavItem(Icons.group, 'STUDENTS', 3),
                _buildNavItem(Icons.book, 'SUBJECTS', 4),
                _buildNavItem(Icons.logout, 'LOGOUT', 5),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isHovered = _hoveredIndex == index;
    final bool isActive = widget.currentIndex == index;

    return Expanded(
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredIndex = index),
        onExit: (_) => setState(() => _hoveredIndex = null),
        child: GestureDetector(
          onTap: () {
            if (index == 5) {
              _handleLogout();
            } else if (index == 0) {
              context.goNamed(AppRoutes.adminDashboard);
            } else if (index == 1) {
              context.goNamed(AppRoutes.adminRoleManager);
            } else if (index == 2) {
              context.goNamed(AppRoutes.adminInstructors);
            } else if (index == 3) {
              context.goNamed(AppRoutes.adminStudents);
            } else if (index == 4) {
              context.goNamed(AppRoutes.adminSubjects);
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isActive 
                    ? Colors.white.withOpacity(0.15) 
                    : (isHovered ? Colors.white.withOpacity(0.08) : Colors.transparent),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon, 
                    color: Colors.white, 
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: (isHovered || isActive) ? FontWeight.bold : FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  Future<void> _handleLogout() async {
    AppDialog.confirm(
      context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      type: DialogType.info,
      confirmLabel: 'Logout',
      onConfirm: () async {
        await _authService.signOut();
        if (!mounted) return;
        context.read<AppState>().logout();
        context.goNamed(AppRoutes.login);
      },
    );
  }
}
