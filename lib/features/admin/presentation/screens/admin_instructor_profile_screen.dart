import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/state/app_state.dart';
import '../../../auth/domain/services/auth_service.dart';
import '../../domain/models/instructor.dart';

class AdminInstructorProfileScreen extends StatefulWidget {
  final Instructor instructor;
  final String? initialRequest; // New parameter to hold the clicked request

  const AdminInstructorProfileScreen({
    super.key, 
    required this.instructor, 
    this.initialRequest,
  });

  @override
  State<AdminInstructorProfileScreen> createState() =>
      _AdminInstructorProfileScreenState();
}

class _AdminInstructorProfileScreenState
    extends State<AdminInstructorProfileScreen> {
  final AuthService _authService = const AuthService();
  int? _hoveredIndex;

  final Size unifiedButtonSize = const Size(85, 32);

  void _confirmAction(String action, VoidCallback onConfirm) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm $action'),
          content: Text('Are you sure you want to $action?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              child: Text(
                action,
                style: TextStyle(
                  color: action == 'Delete' ? Colors.red : Colors.blue,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.adminPageBackground,
      body: Column(
        children: [
          _buildDashboardHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 90.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Instructor Profile'),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.adminItemBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.instructor.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Course: ${widget.instructor.course}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                'Subject: ${widget.instructor.subject}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            _buildSmallActionButton(
                              'Edit',
                              Colors.blue.shade600,
                              Icons.edit_note,
                            ),
                            const SizedBox(height: 8),
                            _buildSmallActionButton(
                              'Delete',
                              AppColors.adminPrimary,
                              Icons.delete,
                              onTap: () => _confirmAction('Delete', () {}),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // REQUESTS SECTION: Dynamic based on source
                  _buildSectionTitle('Requests'),
                  if (widget.initialRequest != null)
                    _buildRequestItem(
                      _getIconForRequest(widget.initialRequest!), 
                      widget.initialRequest!,
                    )
                  else ...[
                    // Default view if accessed via Search List
                    _buildRequestItem(Icons.person_add_alt_1, 'Class Creation'),
                    _buildRequestItem(
                      Icons.access_time_filled,
                      'Schedule Conflict Request',
                    ),
                  ],

                  const SizedBox(height: 20),
                  _buildSectionTitle('Subjects Handled'),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.adminItemBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        _buildSubjectHeader(),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 250),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const BouncingScrollPhysics(),
                            itemCount: 8,
                            itemBuilder: (context, index) =>
                                _buildSubjectDataRow(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Assign Class'),
                  _buildAssignClassForm(),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildSmallActionButton(
                        'Discard',
                        Colors.red.shade700,
                        Icons.block,
                      ),
                      const SizedBox(width: 10),
                      _buildSmallActionButton(
                        'Save',
                        Colors.blue.shade600,
                        Icons.save,
                        onTap: () => _confirmAction('Save', () {}),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _buildDashboardFooter(),
        ],
      ),
    );
  }

  IconData _getIconForRequest(String request) {
    if (request.toLowerCase().contains('creation')) return Icons.person_add_alt_1;
    if (request.toLowerCase().contains('removal')) return Icons.person_remove_alt_1;
    if (request.toLowerCase().contains('conflict')) return Icons.access_time_filled;
    return Icons.notifications;
  }

  Widget _buildDashboardHeader() {
    return Container(
      height: 75,
      width: double.infinity,
      color: AppColors.adminPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
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
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.adminPrimary,
        ),
      ),
    );
  }

  Widget _buildInputField(String hint) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        style: const TextStyle(fontSize: 13),
      ),
    );
  }

  Widget _buildAssignClassForm() {
    return Column(
      children: [
        _buildInputField('Course Code'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildInputField('Subject name by course code')),
            const SizedBox(width: 8),
            Expanded(child: _buildInputField('Academic Year')),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildInputField('Course')),
            const SizedBox(width: 8),
            Expanded(child: _buildInputField('Semester')),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildInputField('Year Level')),
            const SizedBox(width: 8),
            Expanded(child: _buildInputField('Parent Section')),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildInputField('Time Slot (Day & Time)')),
            const SizedBox(width: 8),
            Expanded(child: _buildInputField('Room #')),
          ],
        ),
      ],
    );
  }

  Widget _buildSubjectHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: Colors.black12,
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Subject',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Course & Section',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Time & Room',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectDataRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Text('Subject Name', style: TextStyle(fontSize: 14)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'BSIT - 1A',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '09:00 - Rm 1',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallActionButton(
    String label,
    Color color,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return SizedBox(
      width: unifiedButtonSize.width,
      height: unifiedButtonSize.height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: onTap ?? () {},
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestItem(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.adminItemBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28, color: Colors.black87),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildDashboardFooter() {
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
            context.goNamed(AppRoutes.adminDashboard);
          } else if (index == 3) {
            context.goNamed(AppRoutes.adminSubjects);
          }
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

    if (!mounted) {
      return;
    }

    context.read<AppState>().logout();
    context.goNamed(AppRoutes.login);
  }
}