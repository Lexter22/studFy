import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/state/app_state.dart';
import '../../../auth/domain/services/auth_service.dart';

class ProfessorFloatingNavBar extends StatefulWidget {
  final int currentIndex;

  const ProfessorFloatingNavBar({
    super.key,
    required this.currentIndex,
  });

  @override
  State<ProfessorFloatingNavBar> createState() => _ProfessorFloatingNavBarState();
}

class _ProfessorFloatingNavBarState extends State<ProfessorFloatingNavBar> {
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
              color: AppColors.authPrimary,
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
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(Icons.layers_rounded, 'CLASSES', 0),
                _buildNavItem(Icons.menu_book_rounded, 'MODULES', 1),
                _buildNavItem(Icons.home_rounded, 'DASHBOARD', 2),
                _buildNavItem(Icons.edit_rounded, 'ASSIGNMENT', 3),
                _buildNavItem(Icons.logout_rounded, 'LOGOUT', 4),
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

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: GestureDetector(
        onTap: () {
          if (index == 4) {
            _handleLogout();
          } else if (index == 2) {
            context.goNamed(AppRoutes.professorDashboard);
          } else {
            // Map other categories to dashboard for now or show a brief toast
            context.goNamed(AppRoutes.professorDashboard);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$label view is integrated natively inside specific classes.'),
                duration: const Duration(seconds: 2),
                backgroundColor: AppColors.authPrimary,
              ),
            );
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive 
                ? Colors.white.withOpacity(0.15) 
                : (isHovered ? Colors.white.withOpacity(0.08) : Colors.transparent),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon, 
                color: Colors.white, 
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: (isHovered || isActive) ? FontWeight.bold : FontWeight.normal,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    await _authService.signOut();

    if (!mounted) {
      return;
    }

    context.read<AppState>().logout();
    context.goNamed(AppRoutes.login);
  }
}
