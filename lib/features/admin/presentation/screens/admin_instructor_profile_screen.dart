import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/state/app_state.dart';
import '../../domain/models/instructor.dart';

// ── Simple model for a handled subject row ────────────────────────────────────
class _HandledSubject {
  final String subjectName;
  final String courseSection; 
  final String timeRoom;      

  const _HandledSubject({
    required this.subjectName,
    required this.courseSection,
    required this.timeRoom,
  });
}

class AdminInstructorProfileScreen extends StatefulWidget {
  final Instructor instructor;
  final String? initialRequest;

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
  // ── Profile edit state ────────────────────────────────────────────────────
  bool _isEditing = false;
  late Instructor _currentInstructor;
  late TextEditingController _nameController;
  late TextEditingController _courseController;
  final TextEditingController _passwordController = TextEditingController();

  // ── Assign Class form controllers ─────────────────────────────────────────
  final TextEditingController _courseCodeCtrl    = TextEditingController();
  final TextEditingController _subjectNameCtrl   = TextEditingController();
  final TextEditingController _academicYearCtrl  = TextEditingController();
  
  // Dropdown Selections
  String? _selectedCourse;
  String? _selectedSemester;
  String? _selectedYearLevel;
  String? _selectedSection;
  String? _selectedDay;
  String? _selectedTime;
  String? _selectedRoom;

  // ── Subjects handled list ────────────────────────────────────────────────
  final List<_HandledSubject> _handledSubjects = [
    const _HandledSubject(subjectName: 'Subject Name', courseSection: 'BSIT 2-1', timeRoom: 'MWF 8:00 / MC-101'),
    const _HandledSubject(subjectName: 'Subject Name', courseSection: 'BSIT 3-1', timeRoom: 'TTH 10:00 / C-202'),
    const _HandledSubject(subjectName: 'Subject Name', courseSection: 'BSCS 1-2', timeRoom: 'MWF 1:00 / MC-305'),
    const _HandledSubject(subjectName: 'Subject Name', courseSection: 'BSIT 4-1', timeRoom: 'TTH 3:00 / C-110'),
  ];

  @override
  void initState() {
    super.initState();
    _currentInstructor = widget.instructor;
    _nameController   = TextEditingController(text: _currentInstructor.name);
    _courseController = TextEditingController(text: _currentInstructor.course);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _courseController.dispose();
    _passwordController.dispose();
    _courseCodeCtrl.dispose();
    _subjectNameCtrl.dispose();
    _academicYearCtrl.dispose();
    super.dispose();
  }

  // ── Profile helpers ───────────────────────────────────────────────────────

  void _saveEdits() {
    setState(() {
      _currentInstructor = Instructor(
        name: _nameController.text,
        course: _courseController.text,
        subject: _currentInstructor.subject,
      );
      _isEditing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully')),
    );
  }

  void _showDeleteDialog() {
    _passwordController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Deletion',
            style: TextStyle(color: Color(0xFF800000), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delete ${_currentInstructor.name}? This cannot be undone.'),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Admin Password',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              if (_passwordController.text == 'admin123') {
                Navigator.of(ctx).pop();
                await Future.delayed(Duration.zero);
                if (!mounted) return;
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Instructor deleted successfully')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incorrect Password')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF800000)),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Assign Class helpers ──────────────────────────────────────────────────

  void _clearAssignForm() {
    setState(() {
      _courseCodeCtrl.clear();
      _subjectNameCtrl.clear();
      _academicYearCtrl.clear();
      _selectedCourse = null;
      _selectedSemester = null;
      _selectedYearLevel = null;
      _selectedSection = null;
      _selectedDay = null;
      _selectedTime = null;
      _selectedRoom = null;
    });
  }

  void _commitAssignment() {
    final courseSection = '${_selectedCourse ?? ''} ${_selectedYearLevel ?? ''}-${_selectedSection ?? ''}';
    final timeRoom = '${_selectedDay ?? ''} ${_selectedTime ?? ''} / ${_selectedRoom ?? ''}';

    setState(() {
      _handledSubjects.add(_HandledSubject(
        subjectName: _subjectNameCtrl.text.trim(),
        courseSection: courseSection,
        timeRoom: timeRoom,
      ));
    });
    _clearAssignForm();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Class assigned successfully')));
  }

  void _showDeleteSubjectDialog(int index) {
    _passwordController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Removal', style: TextStyle(color: Color(0xFF800000), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Remove "${_handledSubjects[index].subjectName}"?'),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'Admin Password', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (_passwordController.text == 'admin123') {
                setState(() => _handledSubjects.removeAt(index));
                Navigator.pop(ctx);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incorrect Password')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF800000)),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel('Instructor Profile'),
                      _buildProfileCard(),
                      const SizedBox(height: 20),
                      _buildSectionLabel('Requests'),
                      _buildRequestItem(Icons.person_add, widget.initialRequest ?? 'Class Creation'),
                      const SizedBox(height: 8),
                      _buildRequestItem(Icons.access_time_filled, 'Schedule Conflict Request'),
                      const SizedBox(height: 24),
                      _buildSectionLabel('Subjects Handled'),
                      _buildSubjectsTable(),
                      const SizedBox(height: 24),
                      _buildSectionLabel('Assign Class'),
                      _buildAssignClassForm(),
                      const SizedBox(height: 16),
                      _buildFormActions(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          _buildFloatingNavBar(),
        ],
      ),
    );
  }

  // ── UI Components ─────────────────────────────────────────────────────────

  Widget _buildSubjectsTable() {
    return Container(
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          _buildSubjectRowRaw('Subject Name', 'Course & Section', 'Time & Room', isHeader: true),
          ..._handledSubjects.asMap().entries.map((entry) => 
              _buildSubjectRowRaw(entry.value.subjectName, entry.value.courseSection, entry.value.timeRoom, index: entry.key)),
        ],
      ),
    );
  }

  Widget _buildSubjectRowRaw(String col1, String col2, String col3, {bool isHeader = false, int? index}) {
    final style = TextStyle(fontSize: 12, fontWeight: isHeader ? FontWeight.bold : FontWeight.normal);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(col1, style: style)),
          Expanded(flex: 2, child: Text(col2, textAlign: TextAlign.center, style: style)),
          Expanded(flex: 2, child: Text(col3, textAlign: TextAlign.right, style: style)),
          if (!isHeader)
            SizedBox(
              width: 35,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.delete_outline, color: Color(0xFF800000), size: 18),
                onPressed: () => _showDeleteSubjectDialog(index!),
              ),
            )
          else
            const SizedBox(width: 35),
        ],
      ),
    );
  }

  Widget _buildAssignClassForm() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          _buildCourseCodeHybrid(),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _buildFormInput('Subject Name', controller: _subjectNameCtrl)),
            const SizedBox(width: 8),
            Expanded(child: _buildFormInput('Academic Year', controller: _academicYearCtrl)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _buildDropdown('Course', ['BSIT', 'BSCS', 'BSCpE'], _selectedCourse, (v) => setState(() => _selectedCourse = v))),
            const SizedBox(width: 8),
            Expanded(child: _buildDropdown('Semester', ['1st Semester', '2nd Semester'], _selectedSemester, (v) => setState(() => _selectedSemester = v))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _buildDropdown('Year Level', ['1', '2', '3', '4'], _selectedYearLevel, (v) => setState(() => _selectedYearLevel = v))),
            const SizedBox(width: 8),
            Expanded(child: _buildDropdown('Section', ['1', '2', '3'], _selectedSection, (v) => setState(() => _selectedSection = v))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _buildDropdown('Day', ['MWF', 'TTH', 'SAT'], _selectedDay, (v) => setState(() => _selectedDay = v))),
            const SizedBox(width: 8),
            Expanded(child: _buildDropdown('Time', ['7:00-9:00', '9:00-11:00', '1:00-3:00'], _selectedTime, (v) => setState(() => _selectedTime = v))),
            const SizedBox(width: 8),
            Expanded(child: _buildDropdown('Room #', ['MC-101', 'MC-305', 'C-110'], _selectedRoom, (v) => setState(() => _selectedRoom = v))),
          ]),
        ],
      ),
    );
  }

  Widget _buildCourseCodeHybrid() {
    return Row(
      children: [
        Expanded(child: _buildFormInput('Course Code (e.g. CSC101)', controller: _courseCodeCtrl)),
        const SizedBox(width: 4),
        Container(
          height: 35,
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(4)),
          child: PopupMenuButton<String>(
            icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
            onSelected: (val) => setState(() => _courseCodeCtrl.text = val),
            itemBuilder: (ctx) => ['CSC101', 'IT202', 'NET301'].map((c) => PopupMenuItem(value: c, child: Text(c))).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFormInput(String hint, {TextEditingController? controller}) {
    return Container(
      height: 35,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.black12)),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Center(
        child: TextField(
          controller: controller,
          textAlignVertical: TextAlignVertical.center,
          style: const TextStyle(fontSize: 11),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 11, color: Colors.grey),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String hint, List<String> items, String? value, ValueChanged<String?> onChanged) {
    return Container(
      height: 35,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.black12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          isExpanded: true,
          isDense: true,
          items: items.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 11)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 70, width: double.infinity, color: AppColors.adminPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => context.pop()),
            const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.school, color: Colors.white, size: 28), Text('STUDFY', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900))])
          ]),
          const Text('Admin 1', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black.withOpacity(0.05))),
      child: Row(
        children: [
          const CircleAvatar(radius: 40, backgroundColor: Colors.white, child: Icon(Icons.person_outline, size: 50, color: Colors.black)),
          const SizedBox(width: 16),
          Expanded(
            child: _isEditing 
              ? Column(children: [
                  _buildFormInput('Name', controller: _nameController),
                  const SizedBox(height: 4),
                  _buildFormInput('Course Handled', controller: _courseController),
                ])
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_currentInstructor.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('Course: ${_currentInstructor.course}', style: const TextStyle(color: Colors.black54)),
                ]),
          ),
          Column(children: [
            _isEditing 
              ? _buildSmallActionBtn('Save', Icons.save, Colors.green, onTap: _saveEdits)
              : _buildSmallActionBtn('Edit', Icons.edit_document, const Color(0xFF3B71CA), onTap: () => setState(() => _isEditing = true)),
            const SizedBox(height: 8),
            _buildSmallActionBtn('Delete', Icons.warning, const Color(0xFF800000), onTap: _showDeleteDialog),
          ]),
        ],
      ),
    );
  }

  Widget _buildFloatingNavBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: AppColors.adminPrimary, borderRadius: BorderRadius.circular(35),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5))],
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
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (index == 4) {
            context.read<AppState>().logout();
            if (mounted) context.goNamed(AppRoutes.login);
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
        child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.white, size: 24), Text(label, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))]),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF800000))));
  }

  Widget _buildRequestItem(IconData icon, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black12)),
      child: Row(children: [Icon(icon, color: const Color(0xFF800000), size: 24), const SizedBox(width: 16), Text(title)]),
    );
  }

  Widget _buildFormActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildActionBtn('Discard', Icons.block, const Color(0xFF800000), onTap: _clearAssignForm),
        const SizedBox(width: 12),
        _buildActionBtn('Save', Icons.save, const Color(0xFF3B71CA), onTap: _commitAssignment),
      ],
    );
  }

  Widget _buildSmallActionBtn(String label, IconData icon, Color color, {VoidCallback? onTap}) {
    return Material(color: color, borderRadius: BorderRadius.circular(4), child: InkWell(onTap: onTap, child: Container(width: 80, padding: const EdgeInsets.symmetric(vertical: 6), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 12, color: Colors.white), const SizedBox(width: 4), Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))]))));
  }

  Widget _buildActionBtn(String label, IconData icon, Color color, {VoidCallback? onTap}) {
    return Material(color: color, borderRadius: BorderRadius.circular(4), child: InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Row(children: [Icon(icon, size: 16, color: Colors.white), const SizedBox(width: 8), Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]))));
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}