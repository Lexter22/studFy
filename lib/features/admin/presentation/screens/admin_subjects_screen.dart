import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/state/app_state.dart';

class AdminSubjectsScreen extends StatefulWidget {
  const AdminSubjectsScreen({super.key});

  @override
  State<AdminSubjectsScreen> createState() => _AdminSubjectsScreenState();
}

class _AdminSubjectsScreenState extends State<AdminSubjectsScreen> {
  int? _hoveredIndex;

  final TextEditingController _subjectNameController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _professorController = TextEditingController();

  // Pending subject items (top section — matches the picture)
  final List<Map<String, String>> _pendingSubjects = const [
    {'name': 'Ethics', 'status': 'Pending Prof. Designation'},
    {'name': 'Ethics', 'status': 'Pending Student Enrollment'},
    {'name': 'Ethics', 'status': 'Edit Subject'},
  ];

  // Subject list (bottom section — matches the picture)
  final List<Map<String, String>> _allSubjects = const [
    {'name': 'Computer Programming', 'course': 'BSIT', 'section': '3-1', 'professor': 'Juan Dela Cruz'},
    {'name': 'Data Structures',       'course': 'BSIT', 'section': '3-2', 'professor': 'Juan Dela Cruz'},
    {'name': 'Web Development',       'course': 'BSIT', 'section': '2-1', 'professor': 'Ricardo Dalisay'},
    {'name': 'Networking',            'course': 'BSIT', 'section': '2-2', 'professor': 'Ricardo Dalisay'},
    {'name': 'Database Management',   'course': 'BSCS', 'section': '3-1', 'professor': 'Maria Santos'},
    {'name': 'Algorithms',            'course': 'BSCS', 'section': '3-2', 'professor': 'Maria Santos'},
    {'name': 'Mathematics',           'course': 'BSIE', 'section': '1-1', 'professor': 'Pedro'},
    {'name': 'Calculus',              'course': 'BSIE', 'section': '1-2', 'professor': 'Pedro'},
    {'name': 'Communication',         'course': 'DIT',  'section': '2-1', 'professor': 'Jose'},
    {'name': 'Technical Writing',     'course': 'DIT',  'section': '2-2', 'professor': 'Jose'},
    {'name': 'Ethics',                'course': 'BSHM', 'section': '1-1', 'professor': 'Ana Reyes'},
  ];

  final List<String> _courseList = ['BSIT', 'BSIE', 'DIT', 'BSCS', 'BSHM'];
  final List<String> _professorList = [
    'Juan Dela Cruz',
    'Pedro',
    'Jose',
    'Maria Santos',
    'Ricardo Dalisay',
    'Ana Reyes',
  ];

  late List<Map<String, String>> _filteredSubjects;

  @override
  void initState() {
    super.initState();
    _filteredSubjects = _allSubjects;
  }

  @override
  void dispose() {
    _subjectNameController.dispose();
    _courseController.dispose();
    _professorController.dispose();
    super.dispose();
  }

  void _filterList() {
    setState(() {
      _filteredSubjects = _allSubjects.where((subject) {
        final nameMatch = subject['name']!
            .toLowerCase()
            .contains(_subjectNameController.text.toLowerCase());
        final courseMatch = subject['course']!
            .toLowerCase()
            .contains(_courseController.text.toLowerCase());
        final professorMatch = subject['professor']!
            .toLowerCase()
            .contains(_professorController.text.toLowerCase());
        return nameMatch && courseMatch && professorMatch;
      }).toList();
    });
  }

  void _clearFilters() {
    _subjectNameController.clear();
    _courseController.clear();
    _professorController.clear();
    setState(() {
      _filteredSubjects = _allSubjects;
    });
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
                  _buildSectionTitle('Pending Tasks', null),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 160),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: _pendingSubjects
                            .map((s) => _buildSubjectItem(s['name']!, s['status']!))
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Subject List', 'Total: ${_filteredSubjects.length}'),
                  _buildSearchArea(),
                  const SizedBox(height: 12),
                  _buildSubjectListArea(),
                ],
              ),
            ),
          ),
          _buildNavBar(),
        ],
      ),
    );
  }

  // ── Header (identical to instructor screen) ──────────────────────────────
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

  Widget _buildSectionTitle(String title, String? trailingText) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.adminPrimary)),
          if (trailingText != null)
            Text(trailingText,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.adminPrimary)),
        ],
      ),
    );
  }

  // ── Pending subject card (book icon + name + status) ─────────────────────
  Widget _buildSubjectItem(String name, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: AppColors.adminItemBackground,
          borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          const Icon(Icons.menu_book, size: 40, color: Colors.black),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Text(status,
                    style: const TextStyle(fontSize: 14, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Search area: text field + Course/Professor dropdowns + Search button ──
  Widget _buildSearchArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppColors.adminItemBackground,
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6)),
                  child: TextField(
                    controller: _subjectNameController,
                    onChanged: (_) => _filterList(),
                    decoration: const InputDecoration(
                      hintText: 'Subject Name',
                      hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.filter_alt_off, color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _buildComboField(
                      'Course', _courseController, _courseList)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildComboField(
                      'Professor', _professorController, _professorList)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComboField(
      String hint, TextEditingController controller, List<String> items) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(6)),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (_) => _filterList(),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: InputBorder.none,
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
            onSelected: (val) {
              controller.text = val;
              _filterList();
            },
            itemBuilder: (ctx) => items
                .map((choice) =>
                    PopupMenuItem(value: choice, child: Text(choice)))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── Subject list area ─────────────────────────────────────────────────────
  Map<String, List<Map<String, String>>> _groupSubjectsByCourseSection() {
    final grouped = <String, List<Map<String, String>>>{};
    for (final subject in _filteredSubjects) {
      final key = '${subject['course']!} ${subject['section']!}';
      grouped.putIfAbsent(key, () => []).add(subject);
    }
    return Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  Widget _buildSubjectListArea() {
    if (_filteredSubjects.isEmpty) {
      return Expanded(
        child: Container(
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: const Center(child: Text('No subjects found.')),
        ),
      );
    }

    final grouped = _groupSubjectsByCourseSection();

    // Build a flat list of header + item widgets
    final List<Widget> rows = [];
    for (final entry in grouped.entries) {
      // Group header
      rows.add(Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
        child: Text(
          entry.key,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.adminPrimary,
          ),
        ),
      ));
      // Items in this group
      for (final subject in entry.value) {
        rows.add(GestureDetector(
          onTap: () => context.pushNamed(
            AppRoutes.adminSubjectsProfile,
            extra: {
              'subjectName': subject['name']!,
              'courseSection': '${subject['course']!} ${subject['section']!}',
              'professor': subject['professor']!,
            },
          ),
          child: _SubjectListItem(
            subjectName: subject['name']!,
            courseSection: '${subject['course']!} ${subject['section']!}',
            professor: subject['professor']!,
          ),
        ));
      }
    }

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 98),
          children: rows,
        ),
      ),
    );
  }

  // ── Footer (identical to instructor screen) ───────────────────────────────
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
            context.goNamed(AppRoutes.adminInstructors);
          } else if (index == 1) {
            context.goNamed(AppRoutes.adminStudents);
          } else if (index == 2) {
            context.goNamed(AppRoutes.adminDashboard);
          } else if (index == 3) {
            // Already on subjects
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

// ── Subject list row widget ───────────────────────────────────────────────────
class _SubjectListItem extends StatelessWidget {
  final String subjectName;
  final String courseSection;
  final String professor;

  const _SubjectListItem({
    required this.subjectName,
    required this.courseSection,
    required this.professor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.adminItemBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text(subjectName,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold))),
          Expanded(
              flex: 2,
              child: Text(courseSection,
                  style: const TextStyle(
                      fontSize: 13, color: Colors.black54))),
          Expanded(
              flex: 3,
              child: Text(professor,
                  style: const TextStyle(
                      fontSize: 13, color: Colors.black54),
                  overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
