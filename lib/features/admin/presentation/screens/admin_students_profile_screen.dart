import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/state/app_state.dart';
import '../../../auth/domain/services/auth_service.dart';
import '../../domain/models/student.dart';
import '../../../../core/widgets/app_dialog.dart';

class AdminStudentsProfileScreen extends StatefulWidget {
  final StudentData student;

  const AdminStudentsProfileScreen({
    super.key,
    required this.student,
  });

  @override
  State<AdminStudentsProfileScreen> createState() =>
      _AdminStudentsProfileScreenState();
}

class _AdminStudentsProfileScreenState extends State<AdminStudentsProfileScreen> {
  final AuthService _authService = const AuthService();
  int? _hoveredIndex;

  // Edit state
  bool _isEditing = false;
  late StudentData _currentStudent;
  late TextEditingController _nameController;
  late TextEditingController _courseController;

  @override
  void initState() {
    super.initState();
    _currentStudent = widget.student;
    _nameController = TextEditingController(text: _currentStudent.name);
    _courseController = TextEditingController(
        text: '${_currentStudent.course} ${_currentStudent.yearSection}');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _courseController.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void _saveEdits() {
    setState(() {
      _currentStudent = StudentData(
        name: _nameController.text,
        // For simplicity, we keep the original course/section structure if they didn't change format
        course: _currentStudent.course,
        yearSection: _currentStudent.yearSection,
        subjects: _currentStudent.subjects,
      );
      _isEditing = false;
    });
    AppDialog.result(
      context,
      type: DialogType.success,
      message: 'Student profile updated successfully.',
    );
  }

  void _showDeleteDialog() {
    AppDialog.password(
      context,
      title: 'Confirm Deletion',
      message: 'Delete ${_currentStudent.name}? This cannot be undone.',
      type: DialogType.error,
      confirmLabel: 'Delete',
      onConfirm: (pw) async {
        if (pw == 'admin123') {
          await AppDialog.result(
            context,
            type: DialogType.error,
            message: 'Student record deleted successfully.',
            onDismiss: () => context.pop(true),
          );
        } else {
          AppDialog.alert(
            context,
            title: 'Incorrect Password',
            message: 'The admin password you entered is incorrect.',
          );
        }
      },
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.adminPageBackground,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 90.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Student Profile'),
                  _buildProfileCard(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Schedule for A.Y. 2025-2026 (1st sem)'),
                  _buildScheduleTable(),
                ],
              ),
            ),
          ),
          _buildNavBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 70,
      width: double.infinity,
      color: AppColors.adminPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school, color: Colors.white, size: 28),
              Text('STUDFY',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900)),
            ],
          ),
          Text('Admin 1',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.adminPrimary,
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black87, width: 2),
              color: Colors.white,
            ),
            child: const Icon(Icons.person_outline, size: 50, color: Colors.black87),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isEditing)
                  _buildEditField('Name', _nameController)
                else
                  Hero(
                    tag: 'student-name-${_currentStudent.name}',
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                        _currentStudent.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                if (_isEditing)
                  _buildEditField('Course & Section', _courseController)
                else ...[
                  Text(
                    '${_currentStudent.course} ${_currentStudent.yearSection}',
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const Text(
                    'Enrolled',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              if (_isEditing)
                _buildActionButton(
                  'Save',
                  Colors.green.shade600,
                  Icons.save,
                  _saveEdits,
                )
              else
                _buildActionButton(
                  'Edit',
                  const Color(0xFF2B67E1),
                  Icons.edit_document,
                  () => setState(() => _isEditing = true),
                ),
              const SizedBox(height: 12),
              _buildActionButton(
                'Delete',
                const Color(0xFF8B0000),
                Icons.warning,
                _showDeleteDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditField(String hint, TextEditingController controller) {
    return Container(
      height: 35,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black12),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget _buildActionButton(
      String label, Color color, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: 90,
      height: 32,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleTable() {
    final subjects = _currentStudent.subjects;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFF4F4F4),
            child: const Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text('Subject',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 3,
                    child: Text('Professor',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 2,
                    child: Text('Time & Room',
                        style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          if (subjects.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('No subjects in the list',
                  style: TextStyle(color: Colors.grey, fontSize: 14, fontStyle: FontStyle.italic)),
            )
          else
            ...subjects.asMap().entries.map((entry) => _buildScheduleRow(
                  entry.key,
                  entry.value,
                )),
        ],
      ),
    );
  }

  Widget _buildScheduleRow(int index, String subjectName) {
    final isEven = index % 2 == 0;
    // Mock data for professor and time
    final professors = [
      'Dr. Smith',
      'Prof. Johnson',
      'Ms. Davis',
      'Mr. Wilson',
      'Dr. Brown'
    ];
    final times = [
      'MWF 8:00 / MC-101',
      'TTH 10:30 / C-202',
      'SAT 1:00 / MC-305',
      'MWF 2:30 / C-110'
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: isEven ? Colors.white : const Color(0xFFF9F9F9),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text(subjectName, style: const TextStyle(fontSize: 13))),
          Expanded(
              flex: 3,
              child: Text(professors[index % professors.length],
                  style: const TextStyle(fontSize: 13))),
          Expanded(
              flex: 2,
              child: Text(times[index % times.length],
                  style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildNavBar() {
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
            color:
                isHovered ? Colors.white.withOpacity(0.1) : Colors.transparent,
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
                  fontWeight:
                      isHovered ? FontWeight.bold : FontWeight.normal,
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
