import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/state/app_state.dart';
import '../../../auth/domain/services/auth_service.dart';
import '../../../../core/widgets/app_dialog.dart';

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
  final TextEditingController _professorNameController =
      TextEditingController();
  final TextEditingController _courseSectionController =
      TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();

  final TextEditingController _studentNumberController =
      TextEditingController();
  final TextEditingController _academicYearController =
      TextEditingController();
  final TextEditingController _semesterController = TextEditingController();

  // Mock student list — 30 students, alphabetical by surname (Surname, First M.)
  final List<String> _students = const [
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
    _professorNameController.dispose();
    _courseSectionController.dispose();
    _timeController.dispose();
    _roomController.dispose();
    _studentNumberController.dispose();
    _academicYearController.dispose();
    _semesterController.dispose();
    super.dispose();
  }

  void _confirmAction(String action, VoidCallback onConfirm) {
    final isDelete = action == 'Delete';
    AppDialog.confirm(
      context,
      title: 'Confirm $action',
      message: 'Are you sure you want to $action?',
      type: isDelete ? DialogType.error : DialogType.success,
      confirmLabel: action,
      onConfirm: () {
        onConfirm();
        AppDialog.result(
          context,
          type: isDelete ? DialogType.error : DialogType.success,
          message: '$action completed successfully.',
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
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 90.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Subject Offered card ──────────────────────────────
                  _buildSectionTitle('Subject Offered'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.adminItemBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.subjectName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Professor Assigned',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey[700]),
                              ),
                              Text(
                                widget.courseSection,
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey[700]),
                              ),
                              Text(
                                'Time',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800]),
                              ),
                              Text(
                                'Room #',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            _buildActionButton(
                              'Edit',
                              Colors.blue.shade600,
                              Icons.edit_note,
                            ),
                            const SizedBox(height: 8),
                            _buildActionButton(
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

                  // ── Edit Subject form ─────────────────────────────────
                  _buildSectionTitle('Edit Subject'),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Column(
                      children: [
                        _buildInputField(
                            'Professor Name', _professorNameController),
                        const SizedBox(height: 8),
                        _buildInputField(
                            'Course & Section', _courseSectionController),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                                child: _buildInputField('Time', _timeController)),
                            const SizedBox(width: 8),
                            Expanded(
                                child:
                                    _buildInputField('Room #', _roomController)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _buildActionButton(
                                'Discard', AppColors.adminPrimary, Icons.block),
                            const SizedBox(width: 8),
                            _buildActionButton(
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

                  const SizedBox(height: 20),

                  // ── Enroll Student/s form ─────────────────────────────
                  _buildSectionTitle('Enroll Student/s (For Specific Students)'),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Column(
                      children: [
                        _buildInputField(
                            'Student Number / Student Name',
                            _studentNumberController),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                                child: _buildInputField(
                                    'Academic Year', _academicYearController)),
                            const SizedBox(width: 8),
                            Expanded(
                                child: _buildInputField(
                                    'Semester', _semesterController)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _buildActionButton(
                                'Discard', AppColors.adminPrimary, Icons.block),
                            const SizedBox(width: 8),
                            _buildActionButton(
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

                  const SizedBox(height: 20),

                  // ── Student List ──────────────────────────────────────
                  _buildSectionTitleWithCount('Student List', _students.length),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.adminItemBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _students.length,
                      itemBuilder: (context, index) =>
                          _buildStudentRow(_students[index]),
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

  Widget _buildInputField(String hint, TextEditingController controller) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: controller,
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

  Widget _buildActionButton(
    String label,
    Color color,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return SizedBox(
      width: _btnSize.width,
      height: _btnSize.height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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

  // ── Student list row with edit + delete icons ─────────────────────────────
  Widget _buildStudentRow(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(name,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.edit_note,
                color: Colors.blue.shade600, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () =>
                _confirmAction('Delete', () {}),
            icon: Icon(Icons.delete_outline,
                color: Colors.red.shade600, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
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
