import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/state/app_state.dart';
import '../../../auth/domain/services/auth_service.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../domain/models/student.dart';

class AdminSubjectsProfileScreen extends StatefulWidget {
  final String subjectName;
  final String courseSection;
  final String professor;

  const AdminSubjectsProfileScreen({
    super.key,
    required this.subjectName,
    required this.courseSection,
    required this.professor,
  });

  @override
  State<AdminSubjectsProfileScreen> createState() =>
      _AdminSubjectsProfileScreenState();
}

class _AdminSubjectsProfileScreenState
    extends State<AdminSubjectsProfileScreen> {
  final AuthService _authService = const AuthService();
  int? _hoveredIndex;

  final Size _btnSize = const Size(85, 32);

  // ── Controllers ──────────────────────────────────────────────────────────
  final TextEditingController _subjectNameController = TextEditingController();
  final TextEditingController _professorNameController =
      TextEditingController();
  final TextEditingController _courseSectionController =
      TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();

  final TextEditingController _studentNumberController =
      TextEditingController();
  final TextEditingController _studentSearchController =
      TextEditingController();
  final TextEditingController _academicYearController =
      TextEditingController();
  final TextEditingController _semesterController = TextEditingController();

  bool _isSubjectEditing = false;
  bool _isEnrollEditing = false;

  late List<String> _filteredStudents;

  @override
  void initState() {
    super.initState();
    _subjectNameController.text = widget.subjectName;
    _professorNameController.text = widget.professor;
    _courseSectionController.text = widget.courseSection;
    _filteredStudents = List.from(_allStudents);
  }

  // Mock student list — 30 students, alphabetical by surname (Surname, First M.)
  final List<String> _allStudents = [
    'Aquino, Mark A.',
    'Bautista, Claire B.',
    'Castillo, Ryan C.',
    'Cruz, Miguel D.',
    'De Guzman, Anna E.',
    'Flores, Diane F.',
    'Garcia, Maria G.',
    'Gonzales, Kevin H.',
    'Herrera, Patricia I.',
    'Ignacio, Jerome J.',
    'Jimenez, Kristine K.',
    'Lim, Leonard L.',
    'Lopez, Rosa M.',
    'Manalo, Maricel N.',
    'Mendoza, Sofia O.',
    'Navarro, Nathan P.',
    'Ocampo, Olivia Q.',
    'Pascual, Paolo R.',
    'Quizon, Queenie S.',
    'Ramos, Jose T.',
    'Reyes, Pedro U.',
    'Reyes, Rodel V.',
    'Santos, Juan W.',
    'Santos, Sheila X.',
    'Tan, Carlos Y.',
    'Torres, Tristan Z.',
    'Uy, Ursula A.',
    'Valdez, Vincent B.',
    'Villanueva, Liza C.',
    'Wenceslao, Wendy D.',
  ];

  @override
  void dispose() {
    _subjectNameController.dispose();
    _professorNameController.dispose();
    _courseSectionController.dispose();
    _timeController.dispose();
    _roomController.dispose();
    _studentNumberController.dispose();
    _studentSearchController.dispose();
    _academicYearController.dispose();
    _semesterController.dispose();
    super.dispose();
  }

  void _filterStudents() {
    setState(() {
      _filteredStudents = _allStudents
          .where((s) => s
              .toLowerCase()
              .contains(_studentSearchController.text.toLowerCase()))
          .toList();
    });
  }

  void _clearStudentFilter() {
    _studentSearchController.clear();
    setState(() {
      _filteredStudents = List.from(_allStudents);
    });
  }

  void _confirmAction(String action, VoidCallback onConfirm) {
    final isDelete = action == 'Delete';

    if (isDelete) {
      AppDialog.password(
        context,
        title: 'Confirm Deletion',
        message: 'Are you sure you want to delete this record? This action cannot be undone.',
        type: DialogType.error,
        confirmLabel: 'Delete',
        onConfirm: (pw) async {
          if (pw == 'admin123') {
            onConfirm();
            AppDialog.result(
              context,
              type: DialogType.error,
              message: 'Record deleted successfully.',
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
    } else {
      AppDialog.confirm(
        context,
        title: 'Confirm $action',
        message: 'Are you sure you want to $action?',
        type: DialogType.success,
        confirmLabel: action,
        onConfirm: () {
          onConfirm();
          AppDialog.result(
            context,
            type: DialogType.success,
            message: '$action completed successfully.',
          );
        },
      );
    }
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 90.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Subject Offered section ──────────────────────────────
                  _buildSectionTitle('Subject Offered'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Column(
                      children: [
                        _buildInputField('Subject Name', _subjectNameController,
                            enabled: _isSubjectEditing),
                        const SizedBox(height: 8),
                        _buildInputField('Professor Name', _professorNameController,
                            enabled: _isSubjectEditing),
                        const SizedBox(height: 8),
                        _buildInputField(
                            'Course & Section', _courseSectionController,
                            enabled: _isSubjectEditing),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                                child: _buildInputField('Time', _timeController,
                                    enabled: _isSubjectEditing)),
                            const SizedBox(width: 8),
                            Expanded(
                                child: _buildInputField('Room #', _roomController,
                                    enabled: _isSubjectEditing)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _buildActionBtn(
                              _isSubjectEditing ? 'Discard' : 'Delete',
                              const Color(0xFF801E1E),
                              _isSubjectEditing ? Icons.warning : Icons.delete,
                              () {
                                if (_isSubjectEditing) {
                                  setState(() => _isSubjectEditing = false);
                                } else {
                                  _confirmAction('Delete', () {});
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildActionBtn(
                              _isSubjectEditing ? 'Save' : 'Edit',
                              const Color(0xFF1E63D2),
                              _isSubjectEditing
                                  ? Icons.save
                                  : Icons.edit_square,
                              () {
                                if (_isSubjectEditing) {
                                  _confirmAction('Save', () {
                                    setState(() => _isSubjectEditing = false);
                                  });
                                } else {
                                  setState(() => _isSubjectEditing = true);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Enroll Student/s section ─────────────────────────────
                  _buildSectionTitle('Enroll Student/s (For Specific Students)'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Column(
                      children: [
                        _buildInputField(
                            'Student Number / Student Name', _studentNumberController,
                            enabled: true),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _buildActionBtn(
                              'Add student',
                              const Color(0xFF1E63D2),
                              Icons.add_circle_outline,
                              () {
                                if (_studentNumberController.text.isNotEmpty) {
                                  _confirmAction('Enroll', () {
                                    setState(() {
                                      _allStudents.add(_studentNumberController.text);
                                      _filteredStudents = List.from(_allStudents);
                                      _studentNumberController.clear();
                                    });
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Enrolled Students section ─────────────────────────────
                  _buildSectionTitleWithCount(
                      'Enrolled Students', _allStudents.length),
                  
                  // Search area for student list
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            'Search Student Name',
                            _studentSearchController,
                            enabled: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildActionBtn(
                          'Search',
                          const Color(0xFF1E63D2),
                          Icons.search,
                          _filterStudents,
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6),
                          child: InkWell(
                            onTap: _clearStudentFilter,
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              child: const Icon(Icons.filter_alt_off,
                                  color: Colors.black54, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4D4D4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _filteredStudents.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(
                                  child: Text('No students match your search.',
                                      style: TextStyle(color: Colors.grey))),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _filteredStudents.length,
                              itemBuilder: (context, index) {
                                final isLast =
                                    index == _filteredStudents.length - 1;
                                return _buildStudentItem(
                                    _filteredStudents[index], !isLast);
                              },
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildSectionTitleWithCount(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.adminPrimary)),
          Text('Total: $count',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.adminPrimary)),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
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
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF800000),
        ),
      ),
    );
  }

  Widget _buildInputField(String hint, TextEditingController controller,
      {bool enabled = true}) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: enabled ? Colors.white : const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        style: TextStyle(
            fontSize: 13,
            color: enabled ? Colors.black87 : Colors.black54,
            fontWeight: enabled ? FontWeight.w500 : FontWeight.normal),
      ),
    );
  }

  Widget _buildActionBtn(
      String label, Color color, IconData icon, VoidCallback onTap) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentItem(String name, bool showBorder) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: showBorder
            ? const Border(bottom: BorderSide(color: Color(0xFFE0E0E0)))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(name,
                style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500)),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  context.pushNamed(
                    AppRoutes.adminStudentsProfile,
                    extra: {
                      'student': {
                        'name': name,
                        'course': 'BSIT',
                        'yearSection': '3-1',
                        'subjects': ['Programming', 'Mathematics'],
                      },
                    },
                  );
                },
                icon: const Icon(Icons.edit_square,
                    color: Color(0xFF1E63D2), size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 14),
              IconButton(
                onPressed: () => _confirmAction('Delete', () {}),
                icon: const Icon(Icons.delete,
                    color: Color(0xFFE74C3C), size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
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
    if (!mounted) return;
    context.read<AppState>().logout();
    context.goNamed(AppRoutes.login);
  }
}
