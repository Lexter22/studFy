import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../domain/models/instructor.dart';
import '../widgets/admin_drawer.dart';

class AdminInstructorProfileScreen extends StatefulWidget {
  final Instructor instructor;
  final String? initialRequest;

  const AdminInstructorProfileScreen({
    super.key,
    required this.instructor,
    this.initialRequest,
  });

  @override
  State<AdminInstructorProfileScreen> createState() => _AdminInstructorProfileScreenState();
}

class _AdminInstructorProfileScreenState extends State<AdminInstructorProfileScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _deptCtrl;
  bool _isEditing = false;
  bool _isLoadingSubjects = true;
  List<Map<String, String>> _assignedSubjects = [];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.instructor.name);
    _deptCtrl = TextEditingController(text: widget.instructor.course);
    _loadAssignedSubjects();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _deptCtrl.dispose();
    super.dispose();
  }

  void _loadAssignedSubjects() {
    final subjects = context.read<AppState>().subjectOfferings;
    setState(() {
      _assignedSubjects = subjects
          .where((s) => s['professor'] == widget.instructor.name)
          .toList();
      _isLoadingSubjects = false;
    });
  }

  Future<void> _saveEdits() async {
    try {
      await context.read<AppState>().updateInstructor(
        profileId: widget.instructor.profileId,
        name: _nameCtrl.text.trim(),
        department: _deptCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() => _isEditing = false);
      await AppDialog.result(context, type: DialogType.success, message: 'Instructor updated successfully.');
    } catch (e) {
      if (!mounted) return;
      await AppDialog.result(context, type: DialogType.error, message: e.toString());
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Instructor'),
        content: Text('Delete "${widget.instructor.name}"? This will revoke their access and cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await context.read<AppState>().deleteProfile(widget.instructor.profileId);
                if (!mounted) return;
                context.pop();
              } catch (e) {
                if (!mounted) return;
                await AppDialog.result(context, type: DialogType.error, message: e.toString());
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAssignSubjectDialog() {
    final subjects = context.read<AppState>().subjectOfferings;
    if (subjects.isEmpty) {
      AppDialog.result(context, type: DialogType.info, message: 'No subjects available to assign.');
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Assign Subject to ${widget.instructor.name}'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: subjects.length,
              itemBuilder: (_, index) {
                final subject = subjects[index];
                final isAssigned = _assignedSubjects.any((s) => s['id'] == subject['id']);
                return ListTile(
                  title: Text(subject['name'] ?? ''),
                  subtitle: Text('${subject['course'] ?? ''} ${subject['section'] ?? ''}'),
                  trailing: isAssigned
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.add_circle_outline, color: Colors.grey),
                  onTap: isAssigned ? null : () async {
                    Navigator.pop(ctx);
                    try {
                      await context.read<AppState>().assignProfessorToSubject(
                        subjectId: subject['id']!,
                        profileId: widget.instructor.profileId,
                      );
                      if (!mounted) return;
                      // Reload subjects from updated AppState
                      final updated = context.read<AppState>().subjectOfferings;
                      setState(() {
                        _assignedSubjects = updated
                            .where((s) => s['professor'] == _nameCtrl.text.trim())
                            .toList();
                      });
                      await AppDialog.result(context, type: DialogType.success, message: 'Subject assigned successfully.');
                    } catch (e) {
                      if (!mounted) return;
                      await AppDialog.result(context, type: DialogType.error, message: e.toString());
                    }
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
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
        title: const Row(children: [
          Icon(Icons.school, color: Colors.white, size: 28),
          SizedBox(width: 8),
          Text('STUDFY', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
        ]),
        actions: const [
          Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Admin 1', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)))),
        ],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const AdminDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Instructor Information'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
              child: Column(
                children: [
                  _field('Name', _nameCtrl, enabled: _isEditing),
                  const SizedBox(height: 8),
                  _field('Department', _deptCtrl, enabled: _isEditing),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: _isEditing
                        ? [
                            _btn('Discard', Colors.grey, Icons.close, () => setState(() => _isEditing = false)),
                            const SizedBox(width: 8),
                            _btn('Save', const Color(0xFF1E63D2), Icons.save, _saveEdits),
                          ]
                        : [
                            _btn('Delete', const Color(0xFF801E1E), Icons.delete, _showDeleteDialog),
                            const SizedBox(width: 8),
                            _btn('Edit', const Color(0xFF1E63D2), Icons.edit, () => setState(() => _isEditing = true)),
                          ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionTitle('Assigned Subjects (${_assignedSubjects.length})'),
                ElevatedButton.icon(
                  onPressed: _showAssignSubjectDialog,
                  icon: const Icon(Icons.assignment, size: 16),
                  label: const Text('Assign Subject'),
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
            _buildSubjectsTable(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectsTable() {
    if (_isLoadingSubjects) return const Center(child: CircularProgressIndicator());

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFF4F4F4),
            child: const Row(children: [
              Expanded(flex: 3, child: Text('Subject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
              Expanded(flex: 2, child: Text('Course', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
              Expanded(flex: 2, child: Text('Section', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
            ]),
          ),
          if (_assignedSubjects.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('No subjects assigned yet.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
            )
          else
            ..._assignedSubjects.asMap().entries.map((entry) {
              final isEven = entry.key % 2 == 0;
              final s = entry.value;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: isEven ? Colors.white : const Color(0xFFF9F9F9),
                child: Row(children: [
                  Expanded(flex: 3, child: Text(s['name'] ?? '', style: const TextStyle(fontSize: 13))),
                  Expanded(flex: 2, child: Text(s['course'] ?? '', style: const TextStyle(fontSize: 13, color: Colors.black54))),
                  Expanded(flex: 2, child: Text(s['section'] ?? '', style: const TextStyle(fontSize: 13, color: Colors.black54))),
                ]),
              );
            }),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF800000))),
  );

  Widget _field(String hint, TextEditingController ctrl, {bool enabled = true}) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: enabled ? Colors.white : const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: ctrl,
        enabled: enabled,
        style: TextStyle(fontSize: 13, color: enabled ? Colors.black87 : Colors.black54),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _btn(String label, Color color, IconData icon, VoidCallback onTap) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          ]),
        ),
      ),
    );
  }
}
