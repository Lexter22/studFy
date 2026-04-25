import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../widgets/admin_drawer.dart';
import '../../domain/models/student.dart';

class AdminStudentsProfileScreen extends StatefulWidget {
  final String profileId;
  final StudentData? student;

  const AdminStudentsProfileScreen({super.key, required this.profileId, this.student});

  @override
  State<AdminStudentsProfileScreen> createState() => _AdminStudentsProfileScreenState();
}

class _AdminStudentsProfileScreenState extends State<AdminStudentsProfileScreen> {
  bool _isEditing = false;
  bool _isLoadingSubjects = true;
  StudentData? _currentStudent;
  late TextEditingController _nameController;
  late TextEditingController _courseController;
  late TextEditingController _yearSectionController;
  List<Map<String, String>> _enrolledSubjects = [];
  List<String> _enrolledSubjectIds = [];

  @override
  void initState() {
    super.initState();
    _currentStudent = widget.student;
    // If student passed via extra, use it; otherwise find from AppState
    if (_currentStudent == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final found = context.read<AppState>().students.where((s) => s.profileId == widget.profileId).firstOrNull;
        if (found != null && mounted) {
          setState(() => _currentStudent = found);
          _nameController.text = found.name;
          _courseController.text = found.course;
          _yearSectionController.text = found.yearSection;
          _loadEnrolledSubjects();
        }
      });
    }
    _nameController = TextEditingController(text: _currentStudent?.name ?? '');
    _courseController = TextEditingController(text: _currentStudent?.course ?? '');
    _yearSectionController = TextEditingController(text: _currentStudent?.yearSection ?? '');
    if (_currentStudent != null) _loadEnrolledSubjects();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _courseController.dispose();
    _yearSectionController.dispose();
    super.dispose();
  }

  Future<void> _loadEnrolledSubjects() async {
    if (_currentStudent == null) return;
    setState(() => _isLoadingSubjects = true);
    try {
      final ids = await context.read<AppState>().fetchEnrolledSubjectIds(_currentStudent!.profileId);
      final allSubjects = context.read<AppState>().subjectOfferings;
      setState(() {
        _enrolledSubjectIds = ids;
        _enrolledSubjects = allSubjects
            .where((s) => ids.contains(s['id']))
            .map((s) => Map<String, String>.from(s))
            .toList();
        _isLoadingSubjects = false;
      });
    } catch (_) {
      setState(() => _isLoadingSubjects = false);
    }
  }

  void _showEnrollDialog() {
    if (_currentStudent == null) return;
    final allSubjects = context.read<AppState>().subjectOfferings;
    if (allSubjects.isEmpty) {
      AppDialog.alert(context, title: 'Notice', message: 'No subjects available.');
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text('Manage Subjects for ${_currentStudent!.name}'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: allSubjects.length,
              itemBuilder: (ctx, index) {
                final subject = allSubjects[index];
                final isEnrolled = _enrolledSubjectIds.contains(subject['id']);
                return ListTile(
                  title: Text(subject['name'] ?? ''),
                  subtitle: Text('${subject['course']} ${subject['section']} · ${subject['professor']}'),
                  trailing: isEnrolled
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.add_circle_outline, color: Colors.grey),
                  onTap: () async {
                    if (isEnrolled) {
                      await context.read<AppState>().unenrollStudentFromSubject(
                        studentProfileId: _currentStudent!.profileId,
                        subjectOfferingId: subject['id']!,
                      );
                      setDialogState(() => _enrolledSubjectIds.remove(subject['id']));
                    } else {
                      await context.read<AppState>().enrollStudentInSubject(
                        studentProfileId: _currentStudent!.profileId,
                        subjectOfferingId: subject['id']!,
                      );
                      setDialogState(() => _enrolledSubjectIds.add(subject['id']!));
                    }
                    if (!mounted) return;
                    await _loadEnrolledSubjects();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveEdits() async {
    if (_currentStudent == null) return;
    try {
      await context.read<AppState>().updateStudent(
        profileId: _currentStudent!.profileId,
        name: _nameController.text,
        course: _courseController.text,
        yearSection: _yearSectionController.text,
      );
      if (!mounted) return;
      setState(() {
        _currentStudent = StudentData(
          profileId: _currentStudent!.profileId,
          name: _nameController.text,
          course: _courseController.text,
          yearSection: _yearSectionController.text,
          subjects: _currentStudent!.subjects,
        );
        _isEditing = false;
      });
      await AppDialog.result(context, type: DialogType.success, message: 'Student updated successfully.');
    } catch (e) {
      if (!mounted) return;
      await AppDialog.alert(context, title: 'Error', message: e.toString());
    }
  }

  void _showDeleteDialog() {
    if (_currentStudent == null) return;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text('Delete ${_currentStudent!.name}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await context.read<AppState>().deleteProfile(_currentStudent!.profileId);
                if (!mounted) return;
                context.pop();
              } catch (e) {
                if (!mounted) return;
                AppDialog.alert(context, title: 'Error', message: e.toString());
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
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
      body: _currentStudent == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Student Profile'),
            _buildProfileCard(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle('Enrolled Subjects'),
                ElevatedButton.icon(
                  onPressed: _showEnrollDialog,
                  icon: const Icon(Icons.add, size: 16),
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
            _buildEnrolledSubjectsTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.adminPrimary),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
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
              color: Colors.grey.shade100,
            ),
            child: const Icon(Icons.person_outline, size: 50, color: Colors.black87),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isEditing) ...[
                  _buildEditField('Name', _nameController),
                  _buildEditField('Course', _courseController),
                  _buildEditField('Year & Section', _yearSectionController),
                ] else ...[
                  Text(_currentStudent!.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${_currentStudent!.course} ${_currentStudent!.yearSection}',
                      style: const TextStyle(fontSize: 14, color: Colors.black54)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              if (_isEditing)
                _buildActionButton('Save', Colors.green.shade600, Icons.save, () => _saveEdits())
              else
                _buildActionButton('Edit', const Color(0xFF2B67E1), Icons.edit, () => setState(() => _isEditing = true)),
              const SizedBox(height: 8),
              if (_isEditing)
                _buildActionButton('Cancel', Colors.grey, Icons.close, () => setState(() => _isEditing = false))
              else
                _buildActionButton('Delete', const Color(0xFF8B0000), Icons.delete, _showDeleteDialog),
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
        color: Colors.grey.shade50,
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

  Widget _buildActionButton(String label, Color color, IconData icon, VoidCallback onTap) {
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
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildEnrolledSubjectsTable() {
    if (_isLoadingSubjects) {
      return const Center(child: CircularProgressIndicator());
    }

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
                Expanded(flex: 3, child: Text('Subject', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text('Professor', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Course & Section', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          if (_enrolledSubjects.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('No subjects enrolled yet.',
                  style: TextStyle(color: Colors.grey, fontSize: 14, fontStyle: FontStyle.italic)),
            )
          else
            ..._enrolledSubjects.asMap().entries.map((entry) {
              final isEven = entry.key % 2 == 0;
              final s = entry.value;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: isEven ? Colors.white : const Color(0xFFF9F9F9),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(s['name'] ?? '', style: const TextStyle(fontSize: 13))),
                    Expanded(flex: 3, child: Text(s['professor'] ?? 'Unassigned', style: const TextStyle(fontSize: 13))),
                    Expanded(flex: 2, child: Text('${s['course']} ${s['section']}', style: const TextStyle(fontSize: 13))),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
