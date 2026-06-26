import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/utils/upper_case_text_formatter.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../domain/models/instructor.dart';
import '../widgets/admin_floating_nav_bar.dart';

class AdminInstructorProfileScreen extends StatefulWidget {
  final String profileId;
  final Instructor? instructor;
  final String? initialRequest;

  const AdminInstructorProfileScreen({
    super.key,
    required this.profileId,
    this.instructor,
    this.initialRequest,
  });

  @override
  State<AdminInstructorProfileScreen> createState() => _AdminInstructorProfileScreenState();
}

class _AdminInstructorProfileScreenState extends State<AdminInstructorProfileScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _deptCtrl;
  bool _isEditing = false;
  Instructor? _currentInstructor;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    _currentInstructor = widget.instructor ??
        appState.instructors.where((i) => i.profileId == widget.profileId).firstOrNull;

    _nameCtrl = TextEditingController(text: _currentInstructor?.name ?? '');
    _deptCtrl = TextEditingController(text: _currentInstructor?.course ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _deptCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveEdits() async {
    try {
      await context.read<AppState>().updateInstructor(
        profileId: widget.profileId,
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
    final passwordCtrl = TextEditingController();
    bool isLoading = false;
    bool obscurePassword = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Delete Instructor',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Delete "${_currentInstructor?.name ?? ''}"? This will revoke their access and cannot be undone.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.normal),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
            ],
          ),
          content: Container(
            width: MediaQuery.of(dialogCtx).size.width * 0.9,
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  TextField(
                    controller: passwordCtrl,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm Admin Password',
                      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      floatingLabelStyle: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      prefixIcon: Icon(Icons.lock_outline_rounded, color: Colors.red.withValues(alpha: 0.7), size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.grey.shade600,
                          size: 20,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isLoading ? null : () => Navigator.pop(dialogCtx),
              child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      final enteredPassword = passwordCtrl.text.trim();
                      if (enteredPassword.isEmpty) {
                        AppDialog.alert(dialogCtx, title: 'Required', message: 'Please enter your admin password.');
                        return;
                      }

                      setDialogState(() => isLoading = true);
                      try {
                        final adminEmail = Supabase.instance.client.auth.currentUser?.email;
                        if (adminEmail != null && !adminEmail.startsWith('mock')) {
                          await Supabase.instance.client.auth.signInWithPassword(
                            email: adminEmail,
                            password: enteredPassword,
                          );
                        } else {
                          if (enteredPassword.isEmpty) {
                            throw Exception('Password cannot be empty');
                          }
                        }

                        // Password verified, proceed with deletion
                        await context.read<AppState>().deleteProfile(widget.profileId);
                        if (!mounted) return;
                        Navigator.pop(dialogCtx);
                        context.pop();
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        if (!mounted) return;
                        await AppDialog.alert(dialogCtx, title: 'Error', message: 'Verification failed: Incorrect password.');
                      }
                    },
              child: isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('Delete Instructor', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignSubjectDialog(List<Map<String, String>> assignedSubjects) {
    final subjects = context.read<AppState>().subjectOfferings;
    if (subjects.isEmpty) {
      AppDialog.result(context, type: DialogType.info, message: 'No subjects available to assign.');
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: const Color(0xFFF8F9FC),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            width: MediaQuery.of(ctx).size.width * 0.9 > 500 ? 500 : MediaQuery.of(ctx).size.width * 0.9,
            height: MediaQuery.of(ctx).size.height * 0.8 > 550 ? 550 : MediaQuery.of(ctx).size.height * 0.8,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.adminPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.bookmark_outline_rounded, color: AppColors.adminPrimary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Assign Subject to ${_currentInstructor?.name ?? ''}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: subjects.length,
                    itemBuilder: (_, index) {
                      final subject = subjects[index];
                      final isAssigned = assignedSubjects.any((s) => s['id'] == subject['id']);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.adminPrimary.withValues(alpha: 0.08),
                            child: const Icon(Icons.book_rounded, color: AppColors.adminPrimary, size: 18),
                          ),
                          title: Text(subject['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                          subtitle: Text('${subject['course'] ?? ''} ${subject['section'] ?? ''}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isAssigned
                                  ? const Color(0xFFE8F5E9)
                                  : AppColors.adminPrimary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isAssigned
                                    ? Colors.green.shade200
                                    : AppColors.adminPrimary.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isAssigned ? Icons.check_circle_rounded : Icons.add_circle_rounded,
                                  color: isAssigned ? Colors.green.shade700 : AppColors.adminPrimary,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isAssigned ? 'Assigned' : 'Assign',
                                  style: TextStyle(
                                    color: isAssigned ? Colors.green.shade700 : AppColors.adminPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onTap: isAssigned ? null : () async {
                            Navigator.pop(ctx);
                            try {
                              await context.read<AppState>().assignProfessorToSubject(
                                subjectId: subject['id']!,
                                profileId: widget.profileId,
                              );
                              if (!mounted) return;
                              await AppDialog.result(context, type: DialogType.success, message: 'Subject assigned successfully.');
                            } catch (e) {
                              if (!mounted) return;
                              await AppDialog.result(context, type: DialogType.error, message: e.toString());
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        backgroundColor: Colors.white,
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Close',
                        style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final instructor = appState.instructors.where((i) => i.profileId == widget.profileId).firstOrNull ?? _currentInstructor;
    if (instructor != null && instructor != _currentInstructor) {
      _currentInstructor = instructor;
      if (!_isEditing) {
        _nameCtrl.text = instructor.name;
        _deptCtrl.text = instructor.course;
      }
    }

    if (_currentInstructor == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final assignedSubjects = appState.subjectOfferings
        .where((s) => s['professor'] == _currentInstructor!.name)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.adminPageBackground,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _sectionTitle('Instructor Information'),
                        _buildBackButton(),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildProfileCard(),
                    const SizedBox(height: 28),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        _sectionTitle('Assigned Subjects (${assignedSubjects.length})'),
                        ElevatedButton.icon(
                          onPressed: () => _showAssignSubjectDialog(assignedSubjects),
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
                    _buildSubjectsList(assignedSubjects),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return InkWell(
      onTap: () => context.pop(),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.adminPrimary, width: 1.5),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_back, color: AppColors.adminPrimary, size: 18),
            SizedBox(width: 8),
            Text(
              'Back',
              style: TextStyle(
                color: AppColors.adminPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.adminPrimary),
    );
  }

  Widget _buildProfileCard() {
    final String initials = _currentInstructor?.name.isNotEmpty == true
        ? _currentInstructor!.name.trim().split(' ').map((e) => e[0]).take(2).join('').toUpperCase()
        : 'I';

    final deptList = context.read<AppState>().instructors.map((i) => i.course).toSet().where((c) => c.isNotEmpty).toList();
    if (_currentInstructor != null && _currentInstructor!.course.isNotEmpty && !deptList.contains(_currentInstructor!.course)) {
      deptList.add(_currentInstructor!.course);
    }
    if (!deptList.contains('BSIT')) deptList.add('BSIT');
    if (!deptList.contains('BSCS')) deptList.add('BSCS');
    if (!deptList.contains('BSCPE')) deptList.add('BSCPE');
    deptList.sort();

    return Container(
      width: 450,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
                backgroundColor: AppColors.adminPrimary.withValues(alpha: 0.08),
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
                      _buildEditField('Instructor Name', _nameCtrl),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: deptList.contains(_deptCtrl.text) ? _deptCtrl.text : null,
                        decoration: InputDecoration(
                          labelText: 'Department',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: deptList.map((dept) {
                          return DropdownMenuItem(
                            value: dept,
                            child: Text(dept, style: const TextStyle(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            _deptCtrl.text = val;
                          }
                        },
                      ),
                    ] else ...[
                      Text(
                        _currentInstructor?.name ?? '',
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
                              _currentInstructor?.course ?? '',
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (_isEditing) ...[
                _buildActionButton('Cancel', Colors.grey.shade600, Icons.close_rounded, () => setState(() => _isEditing = false)),
                _buildActionButton('Save Changes', Colors.green, Icons.save_rounded, _saveEdits),
              ] else ...[
                _buildActionButton('Delete Instructor', const Color(0xFF8B0000), Icons.delete_rounded, _showDeleteDialog),
                _buildActionButton('Edit Details', const Color(0xFF2B67E1), Icons.edit_rounded, () => setState(() => _isEditing = true)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller, {bool uppercase = false}) {
    return TextField(
      controller: controller,
      textCapitalization: uppercase ? TextCapitalization.characters : TextCapitalization.none,
      inputFormatters: uppercase ? const [UpperCaseTextFormatter()] : null,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      style: const TextStyle(fontSize: 14),
    );
  }

  Widget _buildActionButton(String label, Color color, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: Colors.white),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
    );
  }

  Widget _buildSubjectsList(List<Map<String, String>> assignedSubjects) {
    if (assignedSubjects.isEmpty) {
      return Container(
        width: 450,
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
      children: assignedSubjects.map((subject) {
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
                  backgroundColor: AppColors.adminPrimary.withValues(alpha: 0.08),
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
