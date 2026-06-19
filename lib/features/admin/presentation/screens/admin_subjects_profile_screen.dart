import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../widgets/admin_floating_nav_bar.dart';
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
                    'Delete Subject',
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
                'Delete "${widget.subjectName}"? This cannot be undone.',
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
                        await context.read<AppState>().deleteSubject(widget.subjectId!);
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
                  : const Text('Delete Subject', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignProfessorDialog() {
    if (widget.subjectId == null) {
      AppDialog.alert(context, title: 'Notice', message: 'Cannot assign a professor to a pending subject. Please create the subject first.');
      return;
    }
    final instructors = context.read<AppState>().instructors;
    if (instructors.isEmpty) {
      AppDialog.alert(context, title: 'Notice', message: 'No instructors available. Please add an instructor first.');
      return;
    }

    String searchQuery = '';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final filtered = instructors
              .where((i) => i.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                  i.course.toLowerCase().contains(searchQuery.toLowerCase()))
              .toList();

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Assign Professor', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by name or department...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                    ),
                    onChanged: (val) => setDialogState(() => searchQuery = val),
                  ),
                  const SizedBox(height: 12),
                  if (filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No instructors found.', style: TextStyle(color: Colors.grey)),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        itemBuilder: (ctx, index) {
                          final instructor = filtered[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.adminPrimary.withOpacity(0.08),
                              child: const Icon(Icons.person, color: AppColors.adminPrimary, size: 20),
                            ),
                            title: Text(instructor.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(instructor.course, style: const TextStyle(fontSize: 12)),
                            onTap: () async {
                              Navigator.pop(dialogCtx);
                              final currentProfessor = _professorNameCtrl.text.trim();
                              final newProfessor = instructor.name;

                              Future<void> executeAssign() async {
                                try {
                                  await context.read<AppState>().assignProfessorToSubject(
                                    subjectId: widget.subjectId!,
                                    profileId: instructor.profileId,
                                  );
                                  if (!mounted) return;
                                  setState(() => _professorNameCtrl.text = instructor.name);
                                  await AppDialog.result(context, type: DialogType.success, message: '${instructor.name} has been assigned as professor.');
                                } catch (e) {
                                  if (!mounted) return;
                                  await AppDialog.alert(context, title: 'Error', message: e.toString());
                                }
                              }

                              if (currentProfessor.isNotEmpty && currentProfessor != newProfessor) {
                                AppDialog.confirm(
                                  context,
                                  title: 'Reassign Professor',
                                  message: 'This subject is currently assigned to $currentProfessor. Are you sure you want to reassign it to $newProfessor?',
                                  confirmLabel: 'Reassign',
                                  type: DialogType.warning,
                                  onConfirm: executeAssign,
                                );
                              } else {
                                await executeAssign();
                              }
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEnrollStudentDialog() {
    final allStudents = context.read<AppState>().students;
    if (allStudents.isEmpty) {
      AppDialog.alert(context, title: 'Notice', message: 'No students available.');
      return;
    }

    String searchQuery = '';
    String? selectedSection;

    final uniqueSections = allStudents
        .map((s) => s.yearSection.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    uniqueSections.sort();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final filteredStudents = allStudents.where((student) {
            final nameMatch = student.name.toLowerCase().contains(searchQuery.toLowerCase());
            final courseMatch = student.course.toLowerCase().contains(searchQuery.toLowerCase());
            final sectionMatch = student.yearSection.toLowerCase().contains(searchQuery.toLowerCase());
            return nameMatch || courseMatch || sectionMatch;
          }).toList();

          return Dialog(
            backgroundColor: const Color(0xFFF8F9FC),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
              width: 500,
              height: 600,
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
                          color: AppColors.adminPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.group_add_rounded, color: AppColors.adminPrimary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Enroll Students',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search student by name or section...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.adminPrimary, width: 2),
                      ),
                    ),
                    onChanged: (val) {
                      setDialogState(() {
                        searchQuery = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  if (uniqueSections.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.adminPrimary.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.adminPrimary.withOpacity(0.08), width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bulk Section Enrollment',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.adminPrimary),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: selectedSection,
                                  decoration: InputDecoration(
                                    hintText: 'Select Section',
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: AppColors.adminPrimary, width: 2),
                                    ),
                                    fillColor: Colors.white,
                                    filled: true,
                                  ),
                                  items: uniqueSections.map((sec) {
                                    return DropdownMenuItem(value: sec, child: Text(sec, style: const TextStyle(fontSize: 13)));
                                  }).toList(),
                                  onChanged: (val) {
                                    setDialogState(() {
                                      selectedSection = val;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.adminPrimary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  elevation: 0,
                                ),
                                onPressed: selectedSection == null
                                    ? null
                                    : () async {
                                        final studentsInSection = allStudents
                                            .where((s) => s.yearSection == selectedSection)
                                            .toList();
                                        
                                        for (final s in studentsInSection) {
                                          if (!_enrolledStudentIds.contains(s.profileId)) {
                                            await context.read<AppState>().enrollStudentInSubject(
                                              studentProfileId: s.profileId,
                                              subjectOfferingId: widget.subjectId!,
                                            );
                                            setDialogState(() {
                                              _enrolledStudentIds.add(s.profileId);
                                            });
                                          }
                                        }
                                        await _loadEnrolledStudents();
                                        if (mounted) {
                                          await AppDialog.result(
                                            context,
                                            type: DialogType.success,
                                            message: 'Successfully enrolled all students from $selectedSection!',
                                          );
                                        }
                                      },
                                icon: const Icon(Icons.group_add_rounded, size: 16),
                                label: const Text('Enroll All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filteredStudents.isEmpty
                        ? const Center(child: Text('No students found.', style: TextStyle(color: Color(0xFF64748B))))
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filteredStudents.length,
                            itemBuilder: (ctx, index) {
                              final student = filteredStudents[index];
                              final isEnrolled = _enrolledStudentIds.contains(student.profileId);
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
                                    backgroundColor: Colors.grey.shade100,
                                    child: const Icon(Icons.person, color: Colors.grey),
                                  ),
                                  title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                                  subtitle: Text('${student.course} - ${student.yearSection}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                  trailing: InkWell(
                                    onTap: () async {
                                      if (isEnrolled) {
                                        AppDialog.confirm(
                                          context,
                                          title: 'Remove Student',
                                          message: 'Are you sure you want to remove ${student.name} from ${_subjectNameCtrl.text}?',
                                          confirmLabel: 'Remove',
                                          type: DialogType.warning,
                                          onConfirm: () async {
                                            await context.read<AppState>().unenrollStudentFromSubject(
                                              studentProfileId: student.profileId,
                                              subjectOfferingId: widget.subjectId!,
                                            );
                                            setDialogState(() {
                                              _enrolledStudentIds.remove(student.profileId);
                                            });
                                            await _loadEnrolledStudents();
                                          },
                                        );
                                      } else {
                                        await context.read<AppState>().enrollStudentInSubject(
                                          studentProfileId: student.profileId,
                                          subjectOfferingId: widget.subjectId!,
                                        );
                                        setDialogState(() {
                                          _enrolledStudentIds.add(student.profileId);
                                        });
                                        await _loadEnrolledStudents();
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isEnrolled
                                            ? const Color(0xFFE8F5E9)
                                            : AppColors.adminPrimary.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isEnrolled
                                              ? Colors.green.shade200
                                              : AppColors.adminPrimary.withOpacity(0.2),
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
                                  ),
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
                        onPressed: () => Navigator.pop(dialogCtx),
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
          );
        },
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
                    if (widget.pendingRequest != null && !_isRequestHandled) ...[
                      _buildPendingRequestBanner(),
                      const SizedBox(height: 16),
                    ],

                    _buildSectionTitle('Subject Information'),
                    _buildProfileCard(),
                    const SizedBox(height: 28),

                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        _buildSectionTitle('Enrolled Students (${_enrolledStudents.length})'),
                        if (widget.subjectId != null)
                          ElevatedButton.icon(
                            onPressed: _showEnrollStudentDialog,
                            icon: const Icon(Icons.person_add_rounded, size: 16, color: Colors.white),
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

                    // Search panel
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: TextField(
                              controller: _studentSearchCtrl,
                              onChanged: (_) => _filterEnrolled(),
                              decoration: const InputDecoration(
                                hintText: 'Search student name...',
                                hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                                prefixIcon: Icon(Icons.search_rounded, size: 18, color: Colors.grey),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            _studentSearchCtrl.clear();
                            _filterEnrolled();
                          },
                          icon: const Icon(Icons.filter_alt_off_rounded, color: Colors.black54),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildEnrolledStudentsList(),
                  ],
                ),
              ),
            ),
          ),
          const AdminFloatingNavBar(currentIndex: 4),
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
                child: const Icon(
                  Icons.book_rounded,
                  color: AppColors.adminPrimary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isEditing) ...[
                      _buildEditField('Subject Name', _subjectNameCtrl),
                      const SizedBox(height: 8),
                      _buildEditField('Course & Section (e.g. BSIT 1-1)', _courseSectionCtrl),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _buildEditField('Schedule', _scheduleCtrl)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildEditField('Room', _roomCtrl)),
                        ],
                      ),
                    ] else ...[
                      Text(
                        _subjectNameCtrl.text,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F6F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Text(
                              _courseSectionCtrl.text,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F6F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.person_outline_rounded, size: 12, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  _professorNameCtrl.text.isNotEmpty ? _professorNameCtrl.text : 'Unassigned Professor',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_scheduleCtrl.text.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F6F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 12, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    _scheduleCtrl.text,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_roomCtrl.text.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F6F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.meeting_room_rounded, size: 12, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Room ${_roomCtrl.text}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
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
                _buildActionButton('Delete Subject', const Color(0xFF8B0000), Icons.delete_rounded, _showDeleteDialog),
                if (widget.subjectId != null) ...[
                  const SizedBox(width: 8),
                  _buildActionButton('Assign Professor', const Color(0xFF1E63D2), Icons.person_add_rounded, _showAssignProfessorDialog),
                ],
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

  Widget _buildEnrolledStudentsList() {
    if (_isLoadingEnrolled) {
      return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
    }

    if (_filteredEnrolled.isEmpty) {
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
            Icon(Icons.people_outline_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No enrolled students found',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _filteredEnrolled.map((student) {
        final initials = student.name.isNotEmpty
            ? student.name.trim().split(' ').map((e) => e[0]).take(2).join('').toUpperCase()
            : 'S';

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
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: AppColors.adminPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
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
                              '${student.course} ${student.yearSection}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  tooltip: 'View Profile',
                  onPressed: () => context.pushNamed(
                    AppRoutes.adminStudentsProfile,
                    pathParameters: {'profileId': student.profileId},
                    extra: {'student': student},
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPendingRequestBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
