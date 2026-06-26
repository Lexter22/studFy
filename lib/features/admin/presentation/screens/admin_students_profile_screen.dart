import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/utils/upper_case_text_formatter.dart';
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
    _currentStudent = widget.student ??
        context.read<AppState>().students.where((s) => s.profileId == widget.profileId).firstOrNull;
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
        builder: (dialogContext, setDialogState) => Dialog(
          backgroundColor: const Color(0xFFF8F9FC),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            width: MediaQuery.of(dialogContext).size.width * 0.9 > 500 ? 500 : MediaQuery.of(dialogContext).size.width * 0.9,
            height: MediaQuery.of(dialogContext).size.height * 0.8 > 550 ? 550 : MediaQuery.of(dialogContext).size.height * 0.8,
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
                        'Manage Subjects for ${_currentStudent!.name}',
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
                    shrinkWrap: true,
                    itemCount: allSubjects.length,
                    itemBuilder: (ctx, index) {
                      final subject = allSubjects[index];
                      final isEnrolled = _enrolledSubjectIds.contains(subject['id']);
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
                          subtitle: Text('${subject['course']} ${subject['section']} · ${subject['professor']}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isEnrolled
                                  ? const Color(0xFFE8F5E9)
                                  : AppColors.adminPrimary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isEnrolled
                                    ? Colors.green.shade200
                                    : AppColors.adminPrimary.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isEnrolled ? Icons.check_circle_rounded : Icons.add_circle_rounded,
                                  color: isEnrolled ? Colors.green.shade700 : AppColors.adminPrimary,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isEnrolled ? 'Enrolled' : 'Enroll',
                                  style: TextStyle(
                                    color: isEnrolled ? Colors.green.shade700 : AppColors.adminPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
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
                      onPressed: () => Navigator.pop(dialogContext),
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
                      color: Colors.red.withValues(alpha: 0.1),
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
    final appState = context.watch<AppState>();
    final student = appState.students.where((s) => s.profileId == widget.profileId).firstOrNull ?? _currentStudent;
    if (student != null && _currentStudent == null) {
      _currentStudent = student;
      _nameController.text = student.name;
      _courseController.text = student.course;
      _yearSectionController.text = student.yearSection;
      Future.microtask(() => _loadEnrolledSubjects());
    }

    return Scaffold(
      backgroundColor: AppColors.adminPageBackground,
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSectionTitle('Student Profile'),
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

    final courseList = context.read<AppState>().students.map((s) => s.course).toSet().where((c) => c.isNotEmpty).toList()..sort();
    if (!courseList.contains('BSIT')) courseList.add('BSIT');
    if (!courseList.contains('BSCS')) courseList.add('BSCS');
    if (!courseList.contains('BSCPE')) courseList.add('BSCPE');
    courseList.sort();

    final yearSecList = context.read<AppState>().students.map((s) => s.yearSection).toSet().where((y) => y.isNotEmpty).toList()..sort();
    for (final def in ['1-1', '1-2', '1-3', '2-1', '2-2', '2-3', '3-1', '3-2', '3-3', '4-1', '4-2', '4-3']) {
      if (!yearSecList.contains(def)) yearSecList.add(def);
    }
    yearSecList.sort();

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
                      _buildEditField('Full Name', _nameController),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: courseList.contains(_courseController.text) ? _courseController.text : null,
                        decoration: InputDecoration(
                          labelText: 'Course',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: courseList.map((course) {
                          return DropdownMenuItem(
                            value: course,
                            child: Text(course, style: const TextStyle(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            _courseController.text = val;
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: yearSecList.contains(_yearSectionController.text) ? _yearSectionController.text : null,
                        decoration: InputDecoration(
                          labelText: 'Year & Section',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: yearSecList.map((ys) {
                          return DropdownMenuItem(
                            value: ys,
                            child: Text(ys, style: const TextStyle(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            _yearSectionController.text = val;
                          }
                        },
                      ),
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (_isEditing) ...[
                _buildActionButton('Cancel', Colors.grey.shade600, Icons.close_rounded, () => setState(() => _isEditing = false)),
                _buildActionButton('Save Changes', Colors.green, Icons.save_rounded, () => _saveEdits()),
              ] else ...[
                _buildActionButton('Delete Student', const Color(0xFF8B0000), Icons.delete_rounded, _showDeleteDialog),
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

  Widget _buildEnrolledSubjectsList() {
    if (_isLoadingSubjects) {
      return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
    }

    if (_enrolledSubjects.isEmpty) {
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
                              '${subject['course']} ${subject['section']}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person_outline_rounded,
                                  size: 14,
                                  color: (subject['professor'] ?? 'unassigned').trim().toLowerCase() == 'unassigned'
                                      ? Colors.red.shade700
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    subject['professor'] ?? 'Unassigned',
                                    style: TextStyle(
                                      color: (subject['professor'] ?? 'unassigned').trim().toLowerCase() == 'unassigned'
                                          ? Colors.red.shade700
                                          : Colors.grey.shade600,
                                      fontSize: 12,
                                      fontWeight: (subject['professor'] ?? 'unassigned').trim().toLowerCase() == 'unassigned'
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
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
