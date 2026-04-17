import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/state/app_state.dart';
import '../../../auth/domain/services/auth_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AuthService _authService = const AuthService();
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adminPageBackground,
      body: Column(
        children: [
          // FIXED HEADER
          Container(
            height: 70,
            width: double.infinity,
            color: AppColors.adminPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.school, color: Colors.white, size: 28),
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
                Text(
                  'Admin 1',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // SCROLLABLE CONTENT AREA
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ROLE INDICATOR REMOVED FROM HERE
                    
                    _buildSectionTitle('Instructor'),
                    _buildFixedList([
                      _buildListItem(Icons.account_circle_outlined, 'Prof Name 1', 'Pending Request'),
                      _buildListItem(Icons.account_circle_outlined, 'Prof Name 2', 'Pending Request'),
                      _buildListItem(Icons.account_circle_outlined, 'Prof Name 3', 'Pending Request'),
                      _buildListItem(Icons.account_circle_outlined, 'Prof Name 4', 'Pending Request'),
                    ]),
                    
                    const SizedBox(height: 20),
                    _buildSectionTitle('Course'),
                    _buildFixedList([
                      _buildListItem(Icons.person, 'BSIT - 1A', 'Prof Name'),
                      _buildListItem(Icons.person, 'BSIT - 2B', 'Prof Name'),
                      _buildListItem(Icons.person, 'BSCS - 3A', 'Prof Name'),
                      _buildListItem(Icons.person, 'BSCS - 4C', 'Prof Name'),
                    ]),
                    
                    const SizedBox(height: 20),
                    _buildSectionTitle('Subjects'),
                    _buildFixedList([
                      _buildListItem(Icons.menu_book, 'Ethics', 'Pending Prof. Designation'),
                      _buildListItem(Icons.menu_book, 'Computing', 'Pending Prof. Designation'),
                      _buildListItem(Icons.menu_book, 'Mathematics', 'Pending Prof. Designation'),
                      _buildListItem(Icons.menu_book, 'Programming', 'Pending Prof. Designation'),
                      _buildListItem(Icons.menu_book, 'Networking', 'Pending Prof. Designation'),
                    ]),
                    
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.goNamed(AppRoutes.adminRoleManager);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.adminPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.manage_accounts, color: Colors.white),
                        label: const Text(
                          'Assign User Roles',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20), // Bottom padding for scroll
                  ],
                ),
              ),
            ),
          ),
          
          // FIXED BOTTOM NAVIGATION
          Container(
            height: 70,
            width: double.infinity,
            color: AppColors.adminPrimary,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(Icons.layers, 'INSTRUCTOR', 0),
                _buildNavItem(Icons.group, 'STUDENTS', 1),
                _buildNavItem(Icons.home, 'DASHBOARD', 2),
                _buildNavItem(Icons.book, 'SUBJECTS', 3),
                _buildNavItem(Icons.logout, 'LOGOUT', 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper to keep the list sections consistent
  Widget _buildFixedList(List<Widget> children) {
    return SizedBox(
      height: 180,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.adminPrimary,
        ),
      ),
    );
  }

  Widget _buildListItem(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.adminItemBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(icon, size: 40, color: Colors.black),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isHovered = _hoveredIndex == index;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: GestureDetector(
        onTap: () {
          if (index == 4) {
            _handleLogout();
          } else if (index == 0) {
            context.goNamed(AppRoutes.adminInstructors);
          } else if (index == 1) {
            context.goNamed(AppRoutes.adminStudents);
          } else if (index == 3) {
            context.goNamed(AppRoutes.adminRoleManager);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isHovered ? AppColors.adminPrimaryHover : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: isHovered ? 30 : 26),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: isHovered ? FontWeight.w900 : FontWeight.bold,
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