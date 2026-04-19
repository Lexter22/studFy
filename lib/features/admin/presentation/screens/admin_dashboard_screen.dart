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
      body: Stack(
        children: [
          // 1. MAIN CONTENT LAYER
          Column(
            children: [
              // FIXED HEADER
              Container(
                height: 70,
                width: double.infinity,
                color: AppColors.adminPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    top: 16.0,
                    bottom: 120.0, // Space for floating capsule
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Overview',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF800000),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // OVERVIEW CARDS
                      _buildOverviewCards(),

                      const SizedBox(height: 24),
                      _buildSectionTitle('Instructor'),

                      // INSTRUCTOR LIST (With Buttons)
                      _buildFixedList([
                        _buildActionListItem('Prof Name', 'Pending Request'),
                        _buildActionListItem('Prof Name', 'Pending Request'),
                      ]),

                      const SizedBox(height: 24),
                      _buildSectionTitle('Subjects'),

                      // SUBJECTS LIST (Simple)
                      _buildFixedList([
                        _buildSimpleListItem('Prof Name', 'Pending Request'),
                        _buildSimpleListItem('Prof Name', 'Pending Request'),
                      ]),

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () => context.goNamed(AppRoutes.adminRoleManager),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.adminPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.manage_accounts, color: Colors.white),
                          label: const Text('Assign User Roles', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 2. FLOATING CAPSULE NAVIGATION LAYER
          Align(
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
          ),
        ],
      ),
    );
  }

  // --- OVERVIEW WIDGETS ---
  Widget _buildOverviewCards() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatCard(Icons.assignment_ind, 'Total\nInstructor', '10', Colors.blue),
        _buildStatCard(Icons.book, 'Total\nSubjects', '10', Colors.orange),
        _buildStatCard(Icons.group, 'Total\nStudents', '300', Colors.green),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String label, String count, Color color) {
  return Container(
    // Increased width from ~0.28 to 0.30 to make them fill more space
    width: MediaQuery.of(context).size.width * 0.30,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18), // Increased vertical padding
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20), // More rounded for a bigger "pop"
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        )
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 22, color: color), // Bigger Icon
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14, // Increased font size
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16), // More space before the count
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              count,
              style: const TextStyle(
                fontSize: 26, // Much bigger count font
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

  // --- LIST WIDGETS ---
  Widget _buildFixedList(List<Widget> children) {
    return Column(children: children);
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF800000)),
      ),
    );
  }

Widget _buildActionListItem(String name, String status) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF8F9FA),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.black12),
    ),
    child: Column(
      children: [
        Row(
          children: [
            const Icon(Icons.account_circle, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(status, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            _buildStatusBadge(),
          ],
        ),
        const SizedBox(height: 16), // Space sa pagitan ng profile at buttons
        
        // DITO ANG PAGBABAGO: Row para magkakatabi ang buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Kakalat sila sa buong lapad
          children: [
            // Ginamit ang Expanded para maging pantay-pantay ang laki nila kung gusto mo
            _buildSmallButton('Approve', Icons.check, Colors.green.shade100, Colors.green),
            _buildSmallButton('Reject', Icons.close, Colors.red.shade100, Colors.red),
            _buildViewDetailsButton(),
          ],
        ),
      ],
    ),
  );
}

  Widget _buildSimpleListItem(String name, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_circle, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(status, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          _buildStatusBadge(),
        ],
      ),
    );
  }

  // --- SMALLER UI COMPONENTS ---
  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: const Color(0xFFF2EECF), // background
          borderRadius: BorderRadius.circular(20),
          ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(
            '● Pending',
            style: TextStyle(
              color: Color(0xFFBDA702), // text + dot
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
    );
  }

  // Increased horizontal padding from 12 to 20 for a wider look
  Widget _buildSmallButton(String label, IconData icon, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), // Wider padding
      decoration: BoxDecoration(
        color: bg, 
        borderRadius: BorderRadius.circular(8), // Slightly more rounded
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: text),
          const SizedBox(width: 6),
          Text(
            label, 
            style: TextStyle(
              color: text, 
              fontSize: 12, // Slightly larger text
              fontWeight: FontWeight.bold
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewDetailsButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), // Wider padding
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text(
            'View Details', 
            style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)
          ),
          SizedBox(width: 6),
          Icon(Icons.chevron_right, size: 14, color: Colors.grey),
        ],
      ),
    );
  }

  // --- NAVIGATION WIDGET ---
  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isHovered = _hoveredIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: GestureDetector(
        onTap: () {
          if (index == 4) _handleLogout();
          else if (index == 0) context.goNamed(AppRoutes.adminInstructors);
          else if (index == 1) context.goNamed(AppRoutes.adminStudents);
          else if (index == 3) context.goNamed(AppRoutes.adminSubjects);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isHovered ? Colors.white.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 24),
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
    if (!mounted) return;
    context.read<AppState>().logout();
    context.goNamed(AppRoutes.login);
  }
}