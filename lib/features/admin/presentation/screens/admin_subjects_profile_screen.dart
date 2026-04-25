import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../widgets/admin_drawer.dart';
import '../../domain/models/student.dart';

class AdminSubjectsProfileScreen extends StatefulWidget {
  final String? subjectId;
  final String subjectName;
  final String courseSection;
  final String professor;
  final String? pendingRequest;

  const AdminSubjectsProfileScreen({
    super.key,
    this.subjectId,
    required this.subjectName,
    required this.courseSection,
    required this.professor,
    this.pendingRequest,
  });

  @override
  State<AdminSubjectsProfileScreen> createState() => _AdminSubjectsProfileScreenState();
}

class _AdminSubjectsProfileScreenState extends State<AdminSubjectsProfileScreen> {
  final TextEditingController _subjectNameCtrl = TextEditingController();
  final TextEditingController _professorNameCtrl = TextEditingController();
  final TextEditingController _courseSectionCtrl = TextEditingController();
  final TextEditingController _roomCtrl = TextEditingController();
  final TextEditingController _scheduleCtrl = TextEditingController();
  final TextEditingController _studentSearchCtrl = TextEditingController();

  bool _isEditing = false;
  bool _isRequestHandled = false;
  bool _isLoadingEnrolled = true;

  List<String> _enrolledStudentIds = [];
  List<StudentData> _enrolledStudents = [];
  List<StudentData> _filteredEnrolled = [];

  @override
  void initState() {
    super.initState();
    _subjectNameCtrl.text = widget.subjectName;
    _professorNameCtrl.text = widget.professor;
    _courseSectionCtrl.text = widget.courseSection;
    if (widget.subjectId != null) _loadEnrolledStudents();
  }

  @override
  void dispose() {
    _subjectNameCtrl.dispose();
    _professorNameCtrl.dispose();
    _courseSectionCtrl.dispose();
    _roomCtrl.dispose();
    _scheduleCtrl.dispose();
    _studentSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEnrolledStudents() async {
    setState(() => _isLoadingEnrolled = true);
    try {
      final allStudents = context.read<AppState>().students;
      // Fetch all enrollments for this subject
      final rows = await context.read<AppState>().fetchStudentsEnrolledInSubject(widget.subjectId!);
      setState(() {
        _enrolledStudentIds = rows;
        _enrolledStudents = allStudents.where((s) => rows.contains(s.profileId)).toList();
        _filteredEnrolled = List.from(_enrolledStudents);
        _isLoadingEnrolled = false;
      });
    } catch (_) {
      setState(() => _isLoadingEnrolled = false);
    }
  }

  void _filterEnrolled() {
    setState(() {
      _filteredEnrolled = _enrolledStudents
          .where((s) => s.name.toLowerCase().contains(_studentSearchCtrl.text.toLowerCase()))
          .toList();
    });
  }

  Future<void> _saveEdits() async {
    if (widget.subjectId == null) return;
    try {
      final parts = _courseSectionCtrl.text.trim().split(' ');
      await context.read<AppState>().updateSubject(
        subjectId: widget.subjectId!,
        subjectName: _subjectNameCtrl.text,
        courseCode: parts.first,
        section: parts.length > 1 ? parts.last : parts.first,
        room: _roomCtrl.text,
        scheduleLabel: _scheduleCtrl.text,
      );
      if (!mounted) return;
      setState(() => _isEditing = false);
      await AppDialog.result(context, type: DialogType.success, message: 'Subject updated successfully.');
    } catch (e) {
      if (!mounted) return;
      await AppDialog.alert(context, title: 'Error', message: e.toString());
    }
  }

  void _showDeleteDialog() {
    if (widget.subjectId == null) return;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text('Delete "${widget.subjectName}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await context.read<AppState>().deleteSubject(widget.subjectId!);
                if (!mounted) return;
                context.pop();
              } catch (e) {
                if (!mounted) return;
                await AppDialog.alert(context, title: 'Error', message: e.toString());
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAssignProfessorDialog() {
    final instructors = context.read<AppState>().instructors;
    if (instructors.isEmpty) {
      AppDialog.alert(context, title: 'Notice', message: 'No instructors available.');
      return;
    }
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Assign Professor'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: instructors.length,
            itemBuilder: (ctx, index) {
              final instructor = instructors[index];
              return ListTile(
                title: Text(instructor.name),
                subtitle: Text(instructor.course),
                onTap: () async {
                  Navigator.pop(dialogCtx);
                  try {
                    await context.read<AppState>().assignProfessorToSubject(
                      subjectId: widget.subjectId!,
                      profileId: instructor.profileId,
                    );
                    if (!mounted) return;
                    setState(() => _professorNameCtrl.text = instructor.name);
                    await AppDialog.result(context, type: DialogType.success, message: 'Professor assigned successfully.');
                  } catch (e) {
                    if (!mounted) return;
                    await AppDialog.alert(context, title: 'Error', message: e.toString());
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
        ],
      ),
    );
  }

  void _showEnrollStudentDialog() {
    final allStudents = context.read<AppState>().students;
    if (allStudents.isEmpty) {
      AppDialog.alert(context, title: 'Notice', message: 'No students available.');
      return;
    }
    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: const Text('Enroll Students'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: allStudents.length,
              itemBuilder: (ctx, index) {
                final student = allStudents[index];
                final isEnrolled = _enrolledStudentIds.contains(student.profileId);
                return ListTile(
                  title: Text(student.name),
                  subtitle: Text('${student.course} ${student.yearSection}'),
                  trailing: isEnrolled
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.add_circle_outline, color: Colors.grey),
                  onTap: () async {
                    if (isEnrolled) {
                      await context.read<AppState>().unenrollStudentFromSubject(
                        studentProfileId: student.profileId,
                        subjectOfferingId: widget.subjectId!,
                      );
                      setDialogState(() => _enrolledStudentIds.remove(student.profileId));
                    } else {
                      await context.read<AppState>().enrollStudentInSubject(
                        studentProfileId: student.profileId,
                        subjectOfferingId: widget.subjectId!,
                      );
                      setDialogState(() => _enrolledStudentIds.add(student.profileId));
                    }
                    if (!mounted) return;
                    await _loadEnrolledStudents();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Close')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adminPageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.adminPrimary,
        elevation: 0,
        toolbarHeight: 70,
        title: const Row(
          children: [
            Icon(Icons.school, color: Colors.white, size: 28),
            SizedBox(width: 8),
            Text('STUDFY', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          ],
        ),
        actions: const [
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Admin 1', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const AdminDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.pendingRequest != null && !_isRequestHandled) ...[
              _buildPendingRequestBanner(),
              const SizedBox(height: 16),
            ],

            // ── Subject Info ──────────────────────────────────────────────
            _buildSectionTitle('Subject Information'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
              child: Column(
                children: [
                  _buildField('Subject Name', _subjectNameCtrl, enabled: _isEditing),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildField('Professor', _professorNameCtrl, enabled: false)),
                      if (widget.subjectId != null) ...[
                        const SizedBox(width: 8),
                        _buildBtn('Assign', const Color(0xFF1E63D2), Icons.person_add, _showAssignProfessorDialog),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildField('Course & Section', _courseSectionCtrl, enabled: _isEditing),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildField('Schedule', _scheduleCtrl, enabled: _isEditing)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildField('Room', _roomCtrl, enabled: _isEditing)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_isEditing) ...[
                        _buildBtn('Discard', Colors.grey, Icons.close, () => setState(() => _isEditing = false)),
                        const SizedBox(width: 8),
                        _buildBtn('Save', const Color(0xFF1E63D2), Icons.save, () => _saveEdits()),
                      ] else ...[
                        _buildBtn('Delete', const Color(0xFF801E1E), Icons.delete, _showDeleteDialog),
                        const SizedBox(width: 8),
                        _buildBtn('Edit', const Color(0xFF1E63D2), Icons.edit, () => setState(() => _isEditing = true)),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Enrolled Students ─────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle('Enrolled Students (${_enrolledStudents.length})'),
                if (widget.subjectId != null)
                  ElevatedButton.icon(
                    onPressed: _showEnrollStudentDialog,
                    icon: const Icon(Icons.person_add, size: 16),
                    label: const Text('Enroll / Manage'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.adminPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Search
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black12)),
                    child: TextField(
                      controller: _studentSearchCtrl,
                      onChanged: (_) => _filterEnrolled(),
                      decoration: const InputDecoration(
                        hintText: 'Search student name...',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(onPressed: () { _studentSearchCtrl.clear(); _filterEnrolled(); }, icon: const Icon(Icons.filter_alt_off, color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 12),

            _buildEnrolledStudentsTable(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEnrolledStudentsTable() {
    if (_isLoadingEnrolled) return const Center(child: CircularProgressIndicator());

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFF4F4F4),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                Expanded(flex: 2, child: Text('Course', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                Expanded(flex: 2, child: Text('Year & Section', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                SizedBox(width: 40),
              ],
            ),
          ),
          if (_filteredEnrolled.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('No students enrolled yet.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
            )
          else
            ..._filteredEnrolled.asMap().entries.map((entry) {
              final isEven = entry.key % 2 == 0;
              final student = entry.value;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: isEven ? Colors.white : const Color(0xFFF9F9F9),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(student.name, style: const TextStyle(fontSize: 13))),
                    Expanded(flex: 2, child: Text(student.course, style: const TextStyle(fontSize: 13, color: Colors.black54))),
                    Expanded(flex: 2, child: Text(student.yearSection, style: const TextStyle(fontSize: 13, color: Colors.black54))),
                    IconButton(
                      icon: const Icon(Icons.person, size: 18, color: Colors.blue),
                      tooltip: 'View Profile',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => context.pushNamed(
                        AppRoutes.adminStudentsProfile,
                        pathParameters: {'profileId': student.profileId},
                        extra: {'student': student},
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF800000))),
    );
  }

  Widget _buildField(String hint, TextEditingController controller, {bool enabled = true}) {
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
        style: TextStyle(fontSize: 13, color: enabled ? Colors.black87 : Colors.black54),
      ),
    );
  }

  Widget _buildBtn(String label, Color color, IconData icon, VoidCallback onTap) {
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
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingRequestBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade200)),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pending Request', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                Text(widget.pendingRequest!, style: TextStyle(fontSize: 13, color: Colors.orange.shade900)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              AppDialog.confirm(
                context,
                title: 'Complete Request',
                message: 'Mark this request as done?',
                type: DialogType.success,
                confirmLabel: 'Done',
                onConfirm: () {
                  context.read<AppState>().removeSubjectRequest(widget.subjectName, widget.pendingRequest!);
                  setState(() => _isRequestHandled = true);
                },
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 20)),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
