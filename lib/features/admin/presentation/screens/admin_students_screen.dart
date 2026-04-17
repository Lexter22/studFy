import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/state/app_state.dart';
import '../../domain/models/student.dart';

class AdminStudentsScreen extends StatefulWidget {
  const AdminStudentsScreen({super.key});

  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> {
  int _hoveredNavIndex = -1;

  final TextEditingController _studentNameController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _yearSectionController = TextEditingController();

  final List<StudentData> _allStudents = const [
    StudentData(name: 'Juan Santos', course: 'BSIT', yearSection: '2nd Year - A'),
    StudentData(name: 'Maria Garcia', course: 'BSIT', yearSection: '3rd Year - B'),
    StudentData(name: 'Pedro Reyes', course: 'BSCS', yearSection: '2nd Year - A'),
    StudentData(name: 'Rosa Lopez', course: 'BSIE', yearSection: '1st Year - C'),
    StudentData(name: 'Carlos Tan', course: 'BSIT', yearSection: '4th Year - A'),
    StudentData(name: 'Anna De Guzman', course: 'BSCS', yearSection: '3rd Year - B'),
    StudentData(name: 'Miguel Cruz', course: 'DIT', yearSection: '2nd Year - A'),
    StudentData(name: 'Sofia Mendoza', course: 'BSHE', yearSection: '1st Year - D'),
  ];

  final List<String> _courseList = ['BSIT', 'BSIE', 'DIT', 'BSCS', 'BSHM'];
  final List<String> _yearSectionList = [
    '1st Year - A',
    '1st Year - B',
    '1st Year - C',
    '2nd Year - A',
    '2nd Year - B',
    '3rd Year - A',
    '3rd Year - B',
    '4th Year - A',
  ];

  late List<StudentData> _filteredStudents;

  @override
  void initState() {
    super.initState();
    _filteredStudents = _allStudents;
  }

  @override
  void dispose() {
    _studentNameController.dispose();
    _courseController.dispose();
    _yearSectionController.dispose();
    super.dispose();
  }

  void _filterList() {
    setState(() {
      _filteredStudents = _allStudents.where((student) {
        final nameMatch = student.name.toLowerCase().contains(_studentNameController.text.toLowerCase());
        final courseMatch = student.course.toLowerCase().contains(_courseController.text.toLowerCase());
        final yearSectionMatch = student.yearSection.toLowerCase().contains(_yearSectionController.text.toLowerCase());
        return nameMatch && courseMatch && yearSectionMatch;
      }).toList();
      // Sort alphabetically by name
      _filteredStudents.sort((a, b) => a.name.compareTo(b.name));
    });
  }

  void _clearFilters() {
    _studentNameController.clear();
    _courseController.clear();
    _yearSectionController.clear();
    setState(() {
      _filteredStudents = _allStudents;
    });
  }

  void _navigateToStudentProfile(StudentData student, String? request) {
    context.pushNamed(
      AppRoutes.adminStudentsProfile,
      extra: {
        'student': {
          'name': student.name,
          'course': student.course,
          'yearSection': student.yearSection,
        },
        'request': request,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adminPageBackground,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Pending Enrollment', null),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 160),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          _buildRequestItem('Juan Santos', 'Pending Verification'),
                          _buildRequestItem('Maria Garcia', 'Missing Documents'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Student List', 'Total: ${_filteredStudents.length}'),
                  _buildSearchArea(),
                  const SizedBox(height: 12),
                  _buildStudentListArea(),
                ],
              ),
            ),
          ),
          _buildFooter(),
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
              Text('STUDFY', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            ],
          ),
          Text('Admin 1', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String? trailingText) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.adminPrimary)),
          if (trailingText != null)
            Text(trailingText, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.adminPrimary)),
        ],
      ),
    );
  }

  Widget _buildSearchArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.adminItemBackground, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                  child: TextField(
                    controller: _studentNameController,
                    onChanged: (_) => _filterList(),
                    decoration: const InputDecoration(
                      hintText: 'Student Name',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(onPressed: _clearFilters, icon: const Icon(Icons.filter_alt_off, color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildComboField('Course', _courseController, _courseList)),
              const SizedBox(width: 8),
              Expanded(child: _buildComboField('Year & Section', _yearSectionController, _yearSectionList)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComboField(String hint, TextEditingController controller, List<String> items) {
    return Container(
      height: 40,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (_) => _filterList(),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: InputBorder.none,
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
            onSelected: (val) { controller.text = val; _filterList(); },
            itemBuilder: (ctx) => items.map((choice) => PopupMenuItem(value: choice, child: Text(choice))).toList(),
          ),
        ],
      ),
    );
  }

  Map<String, List<StudentData>> _groupStudentsByCourseAndSection() {
    final grouped = <String, List<StudentData>>{};
    for (final student in _filteredStudents) {
      final key = '${student.course} - ${student.yearSection}';
      grouped.putIfAbsent(key, () => []).add(student);
    }
    // Sort group keys alphabetically
    final sortedGroups = Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    return sortedGroups;
  }

  Widget _buildStudentListArea() {
    if (_filteredStudents.isEmpty) {
      return Expanded(
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: const Center(child: Text("No students found.")),
        ),
      );
    }

    final groupedStudents = _groupStudentsByCourseAndSection();
    return Expanded(
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: groupedStudents.length * 2 + _filteredStudents.length,
          itemBuilder: (context, index) {
            int itemCount = 0;
            for (final entry in groupedStudents.entries) {
              // Header for this course/section group
              if (itemCount == index) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.adminPrimary,
                    ),
                  ),
                );
              }
              itemCount++;

              // Students in this group
              for (final student in entry.value) {
                if (itemCount == index) {
                  return StudentListItem(
                    student: student,
                    onTap: () => _navigateToStudentProfile(student, null),
                  );
                }
                itemCount++;
              }
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildRequestItem(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: AppColors.adminItemBackground, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          const Icon(Icons.account_circle_outlined, size: 40, color: Colors.black),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
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
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isHovered = _hoveredNavIndex == index;
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredNavIndex = index),
      onExit: (_) => setState(() => _hoveredNavIndex = -1),
      child: GestureDetector(
        onTap: () {
          if (index == 4) {
            context.read<AppState>().logout();
            context.goNamed(AppRoutes.login);
          } else if (index == 0) {
            context.goNamed(AppRoutes.adminInstructors);
          } else if (index == 1) {
            // Already on students
          } else if (index == 2) {
            context.goNamed(AppRoutes.adminDashboard);
          } else if (index == 3) {
            context.goNamed(AppRoutes.adminRoleManager);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isHovered ? AppColors.adminPrimaryHover : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 26),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class StudentListItem extends StatelessWidget {
  final StudentData student;
  final VoidCallback onTap;

  const StudentListItem({super.key, required this.student, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.adminItemBackground.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(flex: 3, child: Text(student.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
            Expanded(flex: 2, child: Text(student.course, style: const TextStyle(fontSize: 13, color: Colors.black54))),
            Expanded(flex: 3, child: Text(student.yearSection, style: const TextStyle(fontSize: 13, color: Colors.black54), overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}
