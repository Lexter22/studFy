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
    return Hero(
      tag: 'admin_floating_nav_bar',
      flightShuttleBuilder: (flightContext, animation, flightDirection, fromHeroContext, toHeroContext) {
        return Material(
          type: MaterialType.transparency,
          child: toHeroContext.widget,
        );
      },
      child: Align(
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
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildNavItem(Icons.home, 'DASHBOARD', 0),
                _buildNavItem(Icons.layers, 'INSTRUCTOR', 1),
                _buildNavItem(Icons.group, 'STUDENTS', 2),
                _buildNavItem(Icons.book, 'SUBJECTS', 3),
                _buildNavItem(Icons.logout, 'LOGOUT', 4),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isHovered = _hoveredIndex == index;
    final bool isActive = widget.currentIndex == index;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 500;

    return Expanded(
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredIndex = index),
        onExit: (_) => setState(() => _hoveredIndex = null),
        child: GestureDetector(
          onTap: () {
            if (index == 4) {
              _handleLogout();
            } else if (index == 0) {
              context.goNamed(AppRoutes.adminDashboard);
            } else if (index == 1) {
              context.goNamed(AppRoutes.adminInstructors);
            } else if (index == 2) {
              context.goNamed(AppRoutes.adminStudents);
            } else if (index == 3) {
              context.goNamed(AppRoutes.adminSubjects);
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 4 : 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isActive 
                    ? Colors.white.withValues(alpha: 0.15) 
                    : (isHovered ? Colors.white.withValues(alpha: 0.08) : Colors.transparent),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon, 
                    color: Colors.white, 
                    size: isMobile ? 18 : 20,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 7.5 : 8.5,
                      fontWeight: (isHovered || isActive) ? FontWeight.bold : FontWeight.w500,
                      letterSpacing: 0.2,
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
