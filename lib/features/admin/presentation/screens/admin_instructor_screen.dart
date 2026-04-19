import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/state/app_state.dart';
import '../../domain/models/instructor.dart';

class AdminInstructorScreen extends StatefulWidget {
  const AdminInstructorScreen({super.key});

  @override
  State<AdminInstructorScreen> createState() => _AdminInstructorScreenState();
}

class _AdminInstructorScreenState extends State<AdminInstructorScreen> {
  int? _hoveredIndex;

  final TextEditingController _profNameController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();

  final List<Instructor> _allInstructors = const [
    Instructor(name: 'Juan Dela Cruz', course: 'BSIT', subject: 'Computer Programming'),
    Instructor(name: 'Pedro', course: 'BSIE', subject: 'Mathematics'),
    Instructor(name: 'Jose', course: 'DIT', subject: 'Communication'),
    Instructor(name: 'Maria Santos', course: 'BSCS', subject: 'Data Structures'),
    Instructor(name: 'Ricardo Dalisay', course: 'BSIT', subject: 'Networking'),
  ];

  final List<String> _courseList = ['BSIT', 'BSIE', 'DIT', 'BSCS', 'BSHM'];
  final List<String> _subjectList = ['Computer Programming', 'Mathematics', 'Communication', 'Ethics', 'Networking'];

  late List<Instructor> _filteredInstructors;

  @override
  void initState() {
    super.initState();
    _filteredInstructors = _allInstructors;
  }

  @override
  void dispose() {
    _profNameController.dispose();
    _courseController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  void _filterList() {
    setState(() {
      _filteredInstructors = _allInstructors.where((instructor) {
        final nameMatch = instructor.name.toLowerCase().contains(_profNameController.text.toLowerCase());
        final courseMatch = instructor.course.toLowerCase().contains(_courseController.text.toLowerCase());
        final subjectMatch = instructor.subject.toLowerCase().contains(_subjectController.text.toLowerCase());
        return nameMatch && courseMatch && subjectMatch;
      }).toList();
      // Sort alphabetically by name
      _filteredInstructors.sort((a, b) => a.name.compareTo(b.name));
    });
  }

  void _clearFilters() {
    _profNameController.clear();
    _courseController.clear();
    _subjectController.clear();
    setState(() {
      _filteredInstructors = _allInstructors;
    });
  }

  // UPDATED NAVIGATION LOGIC
  void _navigateToInstructorProfile(String name, String? request) {
    final instructor = _allInstructors.firstWhere(
      (i) => i.name == name,
      orElse: () => _allInstructors.first,
    );
    
    context.pushNamed(
      AppRoutes.adminInstructorProfile,
      extra: {
        'instructor': instructor,
        'request': request, // Passing the specific request string
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
          _buildHeader(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Pending Requests', null),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 160),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          _buildRequestItem('Juan Dela Cruz', 'Class Creation'),
                          _buildRequestItem('Pedro', 'Removal of Student'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Instructor List', 'Total: ${_filteredInstructors.length}'),
                  _buildSearchArea(),
                  const SizedBox(height: 12),
                  _buildInstructorListArea(),
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
                    controller: _profNameController,
                    onChanged: (_) => _filterList(),
                    decoration: const InputDecoration(
                      hintText: 'Professor Name',
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
              Expanded(child: _buildComboField('Subject', _subjectController, _subjectList)),
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

  Map<String, List<Instructor>> _groupInstructorsByCourse() {
    final grouped = <String, List<Instructor>>{};
    for (final instructor in _filteredInstructors) {
      grouped.putIfAbsent(instructor.course, () => []).add(instructor);
    }
    // Sort course keys alphabetically
    final sortedGroups = Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    return sortedGroups;
  }

  Widget _buildInstructorListArea() {
    if (_filteredInstructors.isEmpty) {
      return Expanded(
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: const Center(child: Text("No instructors found.")),
        ),
      );
    }

    final groupedInstructors = _groupInstructorsByCourse();
    return Expanded(
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 98),
          itemCount: groupedInstructors.length * 2 + _filteredInstructors.length,
          itemBuilder: (context, index) {
            int itemCount = 0;
            for (final entry in groupedInstructors.entries) {
              // Header for this course group
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

              // Instructors in this group
              for (final instructor in entry.value) {
                if (itemCount == index) {
                  return InstructorListItem(
                    instructor: instructor,
                    onTap: () => _navigateToInstructorProfile(instructor.name, null),
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
    return GestureDetector(
      onTap: () => _navigateToInstructorProfile(title, subtitle),
      child: Container(
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
            context.read<AppState>().logout();
            context.goNamed(AppRoutes.login);
          } else if (index == 0) {
            // Already on instructors
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
}

class InstructorListItem extends StatelessWidget {
  final Instructor instructor;
  final VoidCallback onTap;

  const InstructorListItem({super.key, required this.instructor, required this.onTap});

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
            Expanded(flex: 3, child: Text(instructor.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
            Expanded(flex: 2, child: Text(instructor.course, style: const TextStyle(fontSize: 13, color: Colors.black54))),
            Expanded(flex: 3, child: Text(instructor.subject, style: const TextStyle(fontSize: 13, color: Colors.black54), overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}