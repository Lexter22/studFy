import 'package:flutter/material.dart';
// Ensure this file exists in your lib folder
import 'admin_instructor.dart'; 

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedNavIndex = 2; // Dashboard is index 2
  int? _hoveredIndex; 

  final Color adminMaroon = const Color(0xFF7A1313);
  final Color adminMaroonHover = const Color(0xFFA52A2A);
  final Color pageBackground = const Color(0xFFF5F5F5);
  final Color itemBackground = const Color(0xFFD9D9D9);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      body: Column(
        children: [
          // Header - FIXED HEIGHT 70 - Stacked Logo/Title on Left, Name on Right
          Container(
            height: 70,
            width: double.infinity,
            color: adminMaroon,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Vertically Stacked Icon and Text (Left Side)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.school, 
                      color: Colors.white,
                      size: 28,
                    ),
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
                // Admin 1 (Right Side)
                const Text(
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

          // Main Content Area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- INSTRUCTOR SECTION ---
                  _buildSectionTitle('Instructor'),
                  SizedBox(
                    height: 180, 
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          _buildListItem(Icons.account_circle_outlined, 'Prof Name 1', 'Pending Request'),
                          _buildListItem(Icons.account_circle_outlined, 'Prof Name 2', 'Pending Request'),
                          _buildListItem(Icons.account_circle_outlined, 'Prof Name 3', 'Pending Request'),
                          _buildListItem(Icons.account_circle_outlined, 'Prof Name 4', 'Pending Request'),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),

                  // --- COURSE SECTION ---
                  _buildSectionTitle('Course'),
                  SizedBox(
                    height: 180, 
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          _buildListItem(Icons.person, 'BSIT - 1A', 'Prof Name'),
                          _buildListItem(Icons.person, 'BSIT - 2B', 'Prof Name'),
                          _buildListItem(Icons.person, 'BSCS - 3A', 'Prof Name'),
                          _buildListItem(Icons.person, 'BSCS - 4C', 'Prof Name'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- SUBJECTS SECTION ---
                  _buildSectionTitle('Subjects'),
                  SizedBox(
                    height: 180, 
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          _buildListItem(Icons.menu_book, 'Ethics', 'Pending Prof. Designation'),
                          _buildListItem(Icons.menu_book, 'Computing', 'Pending Prof. Designation'),
                          _buildListItem(Icons.menu_book, 'Mathematics', 'Pending Prof. Designation'),
                          _buildListItem(Icons.menu_book, 'Programming', 'Pending Prof. Designation'),
                          _buildListItem(Icons.menu_book, 'Networking', 'Pending Prof. Designation'),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(), // Maximizes space at the bottom of the white area
                ],
              ),
            ),
          ),

          // Footer - FIXED HEIGHT 70
          Container(
            height: 70,
            width: double.infinity,
            color: adminMaroon,
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: adminMaroon,
        ),
      ),
    );
  }

  Widget _buildListItem(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 60,
      decoration: BoxDecoration(
        color: itemBackground,
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
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
            Navigator.pop(context); // Logout returns to Login screen
          } else if (index == 0) {
            // GO TO INSTRUCTOR SCREEN
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AdminInstructorScreen()),
            );
          } else {
            setState(() => _selectedNavIndex = index);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isHovered ? adminMaroonHover : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon, 
                color: Colors.white, 
                size: isHovered ? 30 : 26,
              ),
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
}