import 'dart:math';
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
  int? _hoveredIndex;
  int? _hoveredStudentIndex;

  final TextEditingController _searchController = TextEditingController();

  String? _selectedCourse;
  String? _selectedSubject;

  late final List<String> _courseSectionList;
  final List<String> _subjectList = [
    'Programming',
    'Mathematics',
    'Communication',
    'Data Structures',
    'Networking',
    'Web Development',
    'Database Management',
    'Operating Systems',
    'Software Engineering',
    'Discrete Math',
  ];

  // Each student keeps its own selected course & subject for the row dropdowns.
  // We store them as parallel lists of the same index as _allStudents.
  late final List<StudentData> _allStudents;

  late List<StudentData> _filteredStudents;

  // Per-row selected subject (index-aligned with _allStudents)
  late List<String> _rowSubject;
  // Per-row randomized subjects (2-4 items)
  late List<List<String>> _studentSubjects;

  @override
  void initState() {
    super.initState();
    _allStudents = [
      const StudentData(name: 'Abad, Jose',        course: 'BSCS', yearSection: '1-1'),
      const StudentData(name: 'Bautista, Arnel',   course: 'BSIT', yearSection: '2-2'),
      const StudentData(name: 'Castillo, Elena',   course: 'BSIE', yearSection: '3-3'),
      const StudentData(name: 'Cruz, Miguel',      course: 'DIT',  yearSection: '2-1'),
      const StudentData(name: 'De Guzman, Anna',   course: 'BSCS', yearSection: '3-2'),
      const StudentData(name: 'Dela Cruz, Maria',  course: 'BSIT', yearSection: '1-1'),
      const StudentData(name: 'Evangelista, Mark', course: 'BSIT', yearSection: '4-1'),
      const StudentData(name: 'Ferrer, Grace',     course: 'BSHM', yearSection: '2-3'),
      const StudentData(name: 'Flores, Diane',     course: 'BSCS', yearSection: '1-1'),
      const StudentData(name: 'Garcia, Maria',     course: 'BSIT', yearSection: '3-2'),
      const StudentData(name: 'Gomez, Paolo',      course: 'DIT',  yearSection: '1-2'),
      const StudentData(name: 'Gonzales, Kevin',   course: 'BSIT', yearSection: '2-2'),
      const StudentData(name: 'Hernandez, Rico',   course: 'BSCS', yearSection: '4-2'),
      const StudentData(name: 'Ignacio, Jerome',   course: 'DIT',  yearSection: '3-1'),
      const StudentData(name: 'Javier, Lita',      course: 'BSIE', yearSection: '2-1'),
      const StudentData(name: 'Lopez, Rosa',       course: 'BSIE', yearSection: '1-3'),
      const StudentData(name: 'Luna, Antonio',     course: 'BSCS', yearSection: '3-1'),
      const StudentData(name: 'Mendoza, Sofia',    course: 'BSHM', yearSection: '1-4'),
      const StudentData(name: 'Mercado, Pilar',    course: 'BSIT', yearSection: '3-3'),
      const StudentData(name: 'Noble, Rey',        course: 'DIT',  yearSection: '4-1'),
      const StudentData(name: 'Ortega, Susan',     course: 'BSHM', yearSection: '1-1'),
      const StudentData(name: 'Pascual, Ben',      course: 'BSCS', yearSection: '2-2'),
      const StudentData(name: 'Quezon, Manuel',    course: 'BSIE', yearSection: '4-3'),
      const StudentData(name: 'Reyes, Pedro',      course: 'BSCS', yearSection: '2-1'),
      const StudentData(name: 'Rivera, Rosa',      course: 'BSIT', yearSection: '1-2'),
      const StudentData(name: 'Salazar, Jose',     course: 'DIT',  yearSection: '2-2'),
      const StudentData(name: 'Santos, Juan',      course: 'BSIT', yearSection: '3-1'),
      const StudentData(name: 'Tan, Carlos',       course: 'BSIT', yearSection: '4-1'),
      const StudentData(name: 'Tolentino, Linda',  course: 'BSHM', yearSection: '3-2'),
      const StudentData(name: 'Umali, Victor',     course: 'BSIE', yearSection: '1-2'),
      const StudentData(name: 'Valenzuela, Gina',  course: 'BSCS', yearSection: '4-1'),
    ]..sort((a, b) => a.name.compareTo(b.name));

    _filteredStudents = List.from(_allStudents);

    // Randomize 2-4 subjects per student
    final random = Random();
    _studentSubjects = _allStudents.map((_) {
      final count = random.nextInt(3) + 2; // 2, 3, or 4
      final shuffled = List<String>.from(_subjectList)..shuffle(random);
      return shuffled.take(count).toList();
    }).toList();

    // Set default selected subject
    _rowSubject = _studentSubjects.map((list) => list.first).toList();

    // Generate Course & Section list for dropdown
    final List<String> baseCourses = ['BSIT', 'BSIE', 'DIT', 'BSCS', 'BSHM'];
    _courseSectionList = [];
    for (var c in baseCourses) {
      for (var y = 1; y <= 4; y++) {
        for (var s = 1; s <= 3; s++) {
          _courseSectionList.add("$c $y-$s");
        }
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Filtering ─────────────────────────────────────────────────────────────

  void _applyFilter() {
    setState(() {
      _filteredStudents = _allStudents.where((s) {
        final nameMatch = s.name
            .toLowerCase()
            .contains(_searchController.text.toLowerCase());
        final courseMatch =
            _selectedCourse == null || "${s.course} ${s.yearSection}" == _selectedCourse;
        return nameMatch && courseMatch;
      }).toList();
    });
  }

  void _clearFilter() {
    _searchController.clear();
    setState(() {
      _selectedCourse = null;
      _selectedSubject = null;
      _filteredStudents = List.from(_allStudents);
    });
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Student List',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.adminPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSearchArea(),
                  const SizedBox(height: 12),
                  Expanded(child: _buildStudentList()),
                ],
              ),
            ),
          ),
          _buildNavBar(),
        ],
      ),
    );
  }

  // ── Search area ───────────────────────────────────────────────────────────

  Widget _buildSearchArea() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black12),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => _applyFilter(),
                  decoration: const InputDecoration(
                    hintText: 'Student Name/Student Number',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: AppColors.adminPrimary,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: _applyFilter,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: Colors.white, size: 18),
                      SizedBox(width: 4),
                      Text('Search',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _clearFilter,
              icon: const Icon(Icons.filter_alt_off, color: Colors.black54),
              tooltip: 'Clear filters',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildFilterDropdown(
              hint: 'Course & Section',
              value: _selectedCourse,
              items: _courseSectionList,
              onChanged: (val) {
                setState(() => _selectedCourse = val);
                _applyFilter();
              },
            )),
            const SizedBox(width: 8),
            Expanded(child: _buildFilterDropdown(
              hint: 'Subject',
              value: _selectedSubject,
              items: _subjectList,
              onChanged: (val) => setState(() => _selectedSubject = val),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownMenu<String>(
      expandedInsets: EdgeInsets.zero,
      initialSelection: value,
      hintText: hint,
      enableSearch: true,
      enableFilter: true,
      requestFocusOnTap: true,
      menuHeight: 300,
      onSelected: onChanged,
      dropdownMenuEntries: items.map((e) => DropdownMenuEntry(
        value: e,
        label: e,
        style: MenuItemButton.styleFrom(
          visualDensity: VisualDensity.compact,
        ),
      )).toList(),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        constraints: const BoxConstraints(maxHeight: 42),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.adminPrimary, width: 1),
        ),
      ),
    );
  }

  // ── Student list ──────────────────────────────────────────────────────────

  Widget _buildStudentList() {
    if (_filteredStudents.isEmpty) {
      return const Center(child: Text('No students found.'));
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 98),
        itemCount: _filteredStudents.length,
        separatorBuilder: (_, unused) =>
            const Divider(height: 1, color: Colors.black12, indent: 12, endIndent: 12),
        itemBuilder: (context, index) {
          final student = _filteredStudents[index];
          final originalIndex = _allStudents.indexOf(student);
          return _buildStudentRow(student, originalIndex);
        },
      ),
    );
  }

  Widget _buildStudentRow(StudentData student, int originalIndex) {
    final hasMeta = originalIndex >= 0;
    final isHovered = _hoveredStudentIndex == originalIndex;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredStudentIndex = originalIndex),
      onExit: (_) => setState(() => _hoveredStudentIndex = null),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          context.pushNamed(
            AppRoutes.adminStudentsProfile,
            extra: {
              'student': {
                'name': student.name,
                'course': student.course,
                'yearSection': student.yearSection,
                'subjects': hasMeta ? _studentSubjects[originalIndex] : <String>[],
              },
            },
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isHovered
                ? Colors.black.withOpacity(0.05)
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isHovered ? Colors.black12 : Colors.transparent,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Hero(
                  tag: 'student-name-${student.name}',
                  child: Material(
                    color: Colors.transparent,
                    child: Text(
                      student.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isHovered ? FontWeight.bold : FontWeight.w500,
                        color: isHovered ? AppColors.adminPrimary : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: Container(
                  height: 32,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Text(
                    "${student.course} ${student.yearSection}",
                    style: const TextStyle(fontSize: 11, color: Colors.black87),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: _buildRowDropdown(
                  value: hasMeta ? _rowSubject[originalIndex] : _subjectList.first,
                  items: hasMeta
                      ? _studentSubjects[originalIndex]
                      : [_subjectList.first],
                  onChanged: hasMeta
                      ? (val) {
                          if (val != null) {
                            setState(() => _rowSubject[originalIndex] = val);
                          }
                        }
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRowDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return DropdownMenu<String>(
      expandedInsets: EdgeInsets.zero,
      initialSelection: items.contains(value) ? value : items.first,
      enableSearch: true,
      enableFilter: true,
      requestFocusOnTap: true,
      menuHeight: 200,
      onSelected: onChanged,
      dropdownMenuEntries: items.map((e) => DropdownMenuEntry(
        value: e,
        label: e,
        style: MenuItemButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      )).toList(),
      textStyle: const TextStyle(fontSize: 11, color: Colors.black87),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        constraints: const BoxConstraints(maxHeight: 32),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Colors.black12),
        ),
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
            context.goNamed(AppRoutes.adminSubjects);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color:
                isHovered ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
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
}
