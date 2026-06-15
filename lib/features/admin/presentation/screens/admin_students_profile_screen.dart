import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../widgets/admin_floating_nav_bar.dart';
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.bookmark_outline_rounded, color: AppColors.adminPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Manage Subjects for ${_currentStudent!.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 450,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: allSubjects.length,
              itemBuilder: (ctx, index) {
                final subject = allSubjects[index];
                final isEnrolled = _enrolledSubjectIds.contains(subject['id']);
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.adminPrimary.withOpacity(0.08),
                    child: const Icon(Icons.book_rounded, color: AppColors.adminPrimary, size: 18),
                  ),
                  title: Text(subject['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('${subject['course']} ${subject['section']} · ${subject['professor']}', style: const TextStyle(fontSize: 11)),
                  trailing: Icon(
                    isEnrolled ? Icons.check_circle : Icons.add_circle_outline,
                    color: isEnrolled ? Colors.green : Colors.grey,
                  ),
                  onTap: () async {
                    if (isEnrolled) {
                      AppDialog.confirm(
                        context,
                        title: 'Remove Subject',
                        message: 'Are you sure you want to remove ${_currentStudent!.name} from ${subject['name']}?',
                        confirmLabel: 'Remove',
                        type: DialogType.warning,
                        onConfirm: () async {
                          await context.read<AppState>().unenrollStudentFromSubject(
                            studentProfileId: _currentStudent!.profileId,
                            subjectOfferingId: subject['id']!,
                          );
                          setDialogState(() => _enrolledSubjectIds.remove(subject['id']));
                          await _loadEnrolledSubjects();
                        },
                      );
                    } else {
                      await context.read<AppState>().enrollStudentInSubject(
                        studentProfileId: _currentStudent!.profileId,
                        subjectOfferingId: subject['id']!,
                      );
                      setDialogState(() => _enrolledSubjectIds.add(subject['id']!));
                      await _loadEnrolledSubjects();
                    }
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
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
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Delete Student',
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
                'Delete "${_currentStudent!.name}"? This cannot be undone.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.normal),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
            ],
          ),
          content: Container(
            width: 400,
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
                    prefixIcon: Icon(Icons.lock_outline_rounded, color: Colors.red.withOpacity(0.7), size: 20),
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
                        await context.read<AppState>().deleteProfile(_currentStudent!.profileId);
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
                  : const Text('Delete Student', style: TextStyle(fontWeight: FontWeight.bold)),
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
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          _currentStudent == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBackButton(),
                          const SizedBox(height: 12),
                          _buildSectionTitle('Student Profile'),
                          _buildProfileCard(),
                          const SizedBox(height: 28),
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 16,
                            runSpacing: 12,
                            children: [
                              _buildSectionTitle('Enrolled Subjects'),
                              ElevatedButton.icon(
                                onPressed: _showEnrollDialog,
                                icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                                label: const Text('Enroll / Manage', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
                          _buildEnrolledSubjectsList(),
                        ],
                      ),
                    ),
                  ),
                ),
          const AdminFloatingNavBar(currentIndex: 3),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.adminPrimary),
    );
  }

  Widget _buildProfileCard() {
    final String initials = _currentStudent!.name.isNotEmpty
        ? _currentStudent!.name.trim().split(' ').map((e) => e[0]).take(2).join('').toUpperCase()
        : 'S';

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
                      _buildEditField('Full Name', _nameController),
                      const SizedBox(height: 8),
                      _buildEditField('Course (e.g. BSIT)', _courseController),
                      const SizedBox(height: 8),
                      _buildEditField('Year & Section (e.g. 1-1)', _yearSectionController),
                    ] else ...[
                      Text(
                        _currentStudent!.name,
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
                              _currentStudent!.course,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F6F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Text(
                              'Section ${_currentStudent!.yearSection}',
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
                _buildActionButton('Save Changes', Colors.green, Icons.save_rounded, () => _saveEdits()),
              ] else ...[
                _buildActionButton('Delete Student', const Color(0xFF8B0000), Icons.delete_rounded, _showDeleteDialog),
                const SizedBox(width: 8),
                _buildActionButton('Edit Details', const Color(0xFF2B67E1), Icons.edit_rounded, () => setState(() => _isEditing = true)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
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

  Widget _buildEnrolledSubjectsList() {
    if (_isLoadingSubjects) {
      return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
    }

    if (_enrolledSubjects.isEmpty) {
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
            Icon(Icons.book_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No subjects enrolled yet',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _enrolledSubjects.map((subject) {
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
                              '${subject['course']} ${subject['section']}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.person_outline_rounded, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    subject['professor'] ?? 'Unassigned',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
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
