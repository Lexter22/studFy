import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/state/app_state.dart';
import '../../../auth/domain/services/auth_service.dart';

class StudentFloatingNavBar extends StatefulWidget {
  final int currentIndex;

  const StudentFloatingNavBar({
    super.key,
    required this.currentIndex,
  });

  @override
  State<StudentFloatingNavBar> createState() => _StudentFloatingNavBarState();
}

class _StudentFloatingNavBarState extends State<StudentFloatingNavBar> {
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
                ? 550
                : MediaQuery.of(context).size.width - 20,
          ),
          child: Container(
            height: 70,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFF0A5C36), // Green color matching screenshot
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
                _buildNavItem(Icons.home_rounded, 'DASHBOARD', 0),
                _buildNavItem(Icons.check_circle_rounded, "TO DO'S", 1),
                _buildNavItem(Icons.menu_book_rounded, 'MODULES', 2),
                _buildNavItem(Icons.logout_rounded, 'LOGOUT', 3),
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
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (index == 3) {
            _handleLogout();
            return;
          }

          while (Navigator.canPop(context)) {
            Navigator.pop(context);
          }

          if (index == 0) {
            context.goNamed(AppRoutes.studentDashboard);
          } else if (index == 1) {
            context.goNamed(AppRoutes.studentTodo);
          } else if (index == 2) {
            context.goNamed(AppRoutes.studentModules);
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
