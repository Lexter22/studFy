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
                    fontSize: 15,
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
          
          // CAPSULE BOTTOM NAVIGATION
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              // Changed to .all to give equal margin (10px) to all sides
              padding: const EdgeInsets.all(10), 
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  // We subtract twice the padding (20) from the total width to keep it perfectly even
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
              ),
            ),
          )
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
        } else if (index == 2) {
          // Already on dashboard
        } else if (index == 3) {
          context.goNamed(AppRoutes.adminSubjects);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        // Adding a bit of horizontal padding to the individual item 
        // makes the hover highlight look like a smaller capsule inside
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          // Use a subtle white with low opacity for a modern look
          color: isHovered ? Colors.white.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20), 
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: isHovered ? FontWeight.bold : FontWeight.normal,
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