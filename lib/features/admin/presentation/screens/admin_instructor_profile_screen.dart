import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../domain/models/instructor.dart';
import '../widgets/admin_floating_nav_bar.dart';

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Instructor', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Delete "${widget.instructor.name}"? This will revoke their access and cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Assign Subject to ${widget.instructor.name}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: SizedBox(
            width: 450,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: subjects.length,
              itemBuilder: (_, index) {
                final subject = subjects[index];
                final isAssigned = _assignedSubjects.any((s) => s['id'] == subject['id']);
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.adminPrimary.withOpacity(0.08),
                    child: const Icon(Icons.book_rounded, color: AppColors.adminPrimary, size: 18),
                  ),
                  title: Text(subject['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('${subject['course'] ?? ''} ${subject['section'] ?? ''}'),
                  trailing: Icon(
                    isAssigned ? Icons.check_circle : Icons.add_circle_outline,
                    color: isAssigned ? Colors.green : Colors.grey,
                  ),
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
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
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
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBackButton(),
                    const SizedBox(height: 12),
                    _sectionTitle('Instructor Information'),
                    _buildProfileCard(),
                    const SizedBox(height: 28),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        _sectionTitle('Assigned Subjects (${_assignedSubjects.length})'),
                        ElevatedButton.icon(
                          onPressed: _showAssignSubjectDialog,
                          icon: const Icon(Icons.assignment_rounded, size: 16, color: Colors.white),
                          label: const Text('Assign Subject', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.adminPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSubjectsList(),
                  ],
                ),
              ),
            ),
          ),
          const AdminFloatingNavBar(currentIndex: 0),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return TextButton.icon(
      onPressed: () => context.pop(),
      icon: const Icon(Icons.arrow_back_rounded, color: AppColors.adminPrimary, size: 18),
      label: const Text('Back to Directory', style: TextStyle(color: AppColors.adminPrimary, fontWeight: FontWeight.bold)),
      style: TextButton.styleFrom(padding: EdgeInsets.zero),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.adminPrimary),
    );
  }

  Widget _buildProfileCard() {
    final String initials = widget.instructor.name.isNotEmpty
        ? widget.instructor.name.trim().split(' ').map((e) => e[0]).take(2).join('').toUpperCase()
        : 'I';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.adminPrimary.withOpacity(0.08),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppColors.adminPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isEditing) ...[
                      _buildEditField('Instructor Name', _nameCtrl, Icons.person_outline_rounded),
                      const SizedBox(height: 12),
                      _buildEditField('Department (e.g. BSIT)', _deptCtrl, Icons.school_outlined),
                    ] else ...[
                      Text(
                        widget.instructor.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F6F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Text(
                              widget.instructor.course,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_isEditing) ...[
                _buildActionButton('Cancel', Colors.grey.shade600, Icons.close_rounded, () => setState(() => _isEditing = false)),
                const SizedBox(width: 8),
                _buildActionButton('Save Changes', Colors.green, Icons.save_rounded, _saveEdits),
              ] else ...[
                _buildActionButton('Delete Instructor', const Color(0xFF8B0000), Icons.delete_rounded, _showDeleteDialog),
                const SizedBox(width: 8),
                _buildActionButton('Edit Details', const Color(0xFF2B67E1), Icons.edit_rounded, () => setState(() => _isEditing = true)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.adminPrimary.withOpacity(0.7), size: 20),
        filled: true,
        fillColor: const Color(0xFFF5F6F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.adminPrimary, width: 1.5),
        ),
      ),
      style: const TextStyle(fontSize: 14),
    );
  }

  Widget _buildActionButton(String label, Color color, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15, color: Colors.white),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
    );
  }

  Widget _buildSubjectsList() {
    if (_isLoadingSubjects) {
      return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
    }

    if (_assignedSubjects.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No subjects assigned yet',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _assignedSubjects.map((subject) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.adminPrimary.withOpacity(0.08),
                  child: const Icon(Icons.book_rounded, color: AppColors.adminPrimary, size: 18),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject['name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F6F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Text(
                              '${subject['course'] ?? ''} ${subject['section'] ?? ''}'.trim(),
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
