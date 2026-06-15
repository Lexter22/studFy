import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../auth/domain/models/auth_exception.dart';
import '../../domain/models/student.dart';
import '../widgets/admin_floating_nav_bar.dart';

class AdminStudentsScreen extends StatefulWidget {
  const AdminStudentsScreen({super.key});

  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCourse;
  static const int _pageSize = 8; // Showing 8 items per page for a cleaner layout
  int _currentPage = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter() => setState(() {});

  void _clearFilter() {
    _searchController.clear();
    setState(() {
      _selectedCourse = null;
      _currentPage = 0;
    });
  }

  List<String> _courseSectionList(List<StudentData> students) {
    return students
        .map((s) => '${s.course} ${s.yearSection}')
        .toSet()
        .toList()
      ..sort();
  }

  List<StudentData> _filterStudents(List<StudentData> students) {
    return students.where((student) {
      final courseSection = '${student.course} ${student.yearSection}';
      final nameMatch = student.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          student.profileId.toLowerCase().contains(_searchController.text.toLowerCase());
      final courseMatch = _selectedCourse == null || courseSection == _selectedCourse;
      return nameMatch && courseMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

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
        actions: const [
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Admin 1',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          ValueListenableBuilder<List<StudentData>>(
            valueListenable: appState.studentsNotifier,
            builder: (context, students, _) {
              final filteredStudents = _filterStudents(students);
              final courseSectionList = _courseSectionList(students);
              final pageCount = math.max(1, (filteredStudents.length / _pageSize).ceil());
              final safePage = _currentPage.clamp(0, pageCount - 1);
              if (safePage != _currentPage) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _currentPage = safePage);
                });
              }
              final pagedStudents = filteredStudents.skip(safePage * _pageSize).take(_pageSize).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header panel
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 16,
                          runSpacing: 12,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Student Directory',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.adminPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Manage and view all registered students',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.adminPrimary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.people_alt_rounded, color: AppColors.adminPrimary, size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${filteredStudents.length} Total',
                                        style: const TextStyle(
                                          color: AppColors.adminPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  onPressed: _showCreateStudentDialog,
                                  icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 18),
                                  label: const Text('Add Student', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.adminPrimary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    elevation: 0,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Search and Filter area card
                        Container(
                          padding: const EdgeInsets.all(16),
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
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5F6F9),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: TextField(
                                        controller: _searchController,
                                        onChanged: (_) => _applyFilter(),
                                        decoration: InputDecoration(
                                          hintText: 'Search by student name or ID...',
                                          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                                          suffixIcon: _searchController.text.isNotEmpty
                                              ? IconButton(
                                                  icon: const Icon(Icons.clear, size: 18),
                                                  onPressed: () {
                                                    _searchController.clear();
                                                    _applyFilter();
                                                  },
                                                )
                                              : null,
                                          border: InputBorder.none,
                                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  IconButton(
                                    onPressed: _clearFilter,
                                    icon: const Icon(Icons.filter_alt_off_rounded, color: Colors.black54),
                                    tooltip: 'Clear filters',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedCourse,
                                      hint: const Text('Filter by Course & Section', style: TextStyle(fontSize: 13)),
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: const Color(0xFFF5F6F9),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                      items: courseSectionList.map((sec) {
                                        return DropdownMenuItem(
                                          value: sec,
                                          child: Text(sec, style: const TextStyle(fontSize: 13)),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedCourse = val;
                                          _currentPage = 0;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Student grid/list
                        _buildStudentList(pagedStudents),

                        const SizedBox(height: 16),

                        // Pagination UI
                        _buildPagination(
                          totalItems: filteredStudents.length,
                          pageCount: pageCount,
                          currentPage: safePage,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const AdminFloatingNavBar(currentIndex: 3),
        ],
      ),
    );
  }

  Widget _buildPagination({required int totalItems, required int pageCount, required int currentPage}) {
    if (totalItems == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page ${currentPage + 1} of $pageCount',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
          Row(
            children: [
              IconButton(
                onPressed: currentPage > 0
                    ? () => setState(() => _currentPage = currentPage - 1)
                    : null,
                icon: const Icon(Icons.chevron_left_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: currentPage > 0 ? const Color(0xFFF5F6F9) : Colors.transparent,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: currentPage < pageCount - 1
                    ? () => setState(() => _currentPage = currentPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: currentPage < pageCount - 1 ? const Color(0xFFF5F6F9) : Colors.transparent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList(List<StudentData> students) {
    if (students.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 60),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No students match your filter criteria',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return Column(
      children: students.map((student) => _buildStudentCard(student)).toList(),
    );
  }

  Widget _buildStudentCard(StudentData student) {
    final String displayName = student.name;
    final String courseSection = '${student.course} ${student.yearSection}';
    final String initials = displayName.isNotEmpty
        ? displayName.trim().split(' ').map((e) => e[0]).take(2).join('').toUpperCase()
        : 'S';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => context.pushNamed(
          AppRoutes.adminStudentsProfile,
          pathParameters: {'profileId': student.profileId},
          extra: {'student': student},
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.adminPrimary.withOpacity(0.08),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppColors.adminPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
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
                            courseSection,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ID: ${student.profileId.substring(0, math.min(student.profileId.length, 12))}...',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
                    onPressed: () => _showEditStudentDialog(student),
                    tooltip: 'Edit details',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                    onPressed: () => _showDeleteStudentDialog(student),
                    tooltip: 'Delete student',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditStudentDialog(StudentData student) {
    final nameCtrl = TextEditingController(text: student.name);
    final courseCtrl = TextEditingController(text: student.course);
    final yearSecCtrl = TextEditingController(text: student.yearSection);
    bool isLoading = false;

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
                      color: AppColors.adminPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.edit_rounded, color: AppColors.adminPrimary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Edit Student Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.adminPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Modify student\'s core profile information.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.normal),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
            ],
          ),
          content: Container(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      floatingLabelStyle: const TextStyle(color: AppColors.adminPrimary, fontWeight: FontWeight.bold),
                      prefixIcon: Icon(Icons.person_outline, color: AppColors.adminPrimary.withOpacity(0.7), size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.adminPrimary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: courseCtrl,
                    decoration: InputDecoration(
                      labelText: 'Course (e.g. BSIT)',
                      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      floatingLabelStyle: const TextStyle(color: AppColors.adminPrimary, fontWeight: FontWeight.bold),
                      prefixIcon: Icon(Icons.school_outlined, color: AppColors.adminPrimary.withOpacity(0.7), size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.adminPrimary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: yearSecCtrl,
                    decoration: InputDecoration(
                      labelText: 'Year & Section (e.g. 2-A)',
                      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      floatingLabelStyle: const TextStyle(color: AppColors.adminPrimary, fontWeight: FontWeight.bold),
                      prefixIcon: Icon(Icons.grid_view_outlined, color: AppColors.adminPrimary.withOpacity(0.7), size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.adminPrimary, width: 2),
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
                backgroundColor: AppColors.adminPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      setDialogState(() => isLoading = true);
                      try {
                        await context.read<AppState>().updateStudent(
                              profileId: student.profileId,
                              name: nameCtrl.text,
                              course: courseCtrl.text,
                              yearSection: yearSecCtrl.text,
                            );
                        if (!mounted) return;
                        Navigator.pop(dialogCtx);
                        await AppDialog.result(context, type: DialogType.success, message: 'Student updated successfully.');
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        if (!mounted) return;
                        await AppDialog.alert(context, title: 'Error', message: e.toString());
                      }
                    },
              child: isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteStudentDialog(StudentData student) {
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
                'Delete "${student.name}"? This will revoke their access and delete their profiles permanently.',
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
                        await context.read<AppState>().deleteProfile(student.profileId);
                        if (!mounted) return;
                        Navigator.pop(dialogCtx);
                        await AppDialog.result(context, type: DialogType.success, message: 'Student deleted successfully.');
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

  void _showCreateStudentDialog() {
    final emailCtrl = TextEditingController();
    final firstNameCtrl = TextEditingController();
    final lastNameCtrl = TextEditingController();
    final courseCtrl = TextEditingController();
    final yearSecCtrl = TextEditingController();
    final studentNumCtrl = TextEditingController();
    bool isLoading = false;

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
                      color: AppColors.adminPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.adminPrimary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Add New Student',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.adminPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Enter the student\'s academic details and initial credentials here.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.normal),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
            ],
          ),
          content: Container(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  TextField(
                    controller: emailCtrl,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      floatingLabelStyle: const TextStyle(color: AppColors.adminPrimary, fontWeight: FontWeight.bold),
                      prefixIcon: Icon(Icons.email_outlined, color: AppColors.adminPrimary.withOpacity(0.7), size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.adminPrimary, width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: firstNameCtrl,
                    decoration: InputDecoration(
                      labelText: 'First Name',
                      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      floatingLabelStyle: const TextStyle(color: AppColors.adminPrimary, fontWeight: FontWeight.bold),
                      prefixIcon: Icon(Icons.person_outline, color: AppColors.adminPrimary.withOpacity(0.7), size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.adminPrimary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: lastNameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Last Name',
                      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      floatingLabelStyle: const TextStyle(color: AppColors.adminPrimary, fontWeight: FontWeight.bold),
                      prefixIcon: Icon(Icons.person_outline, color: AppColors.adminPrimary.withOpacity(0.7), size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.adminPrimary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: studentNumCtrl,
                    decoration: InputDecoration(
                      labelText: 'Student Number (Optional)',
                      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      floatingLabelStyle: const TextStyle(color: AppColors.adminPrimary, fontWeight: FontWeight.bold),
                      prefixIcon: Icon(Icons.badge_outlined, color: AppColors.adminPrimary.withOpacity(0.7), size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.adminPrimary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: courseCtrl,
                    decoration: InputDecoration(
                      labelText: 'Course (e.g. BSIT)',
                      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      floatingLabelStyle: const TextStyle(color: AppColors.adminPrimary, fontWeight: FontWeight.bold),
                      prefixIcon: Icon(Icons.school_outlined, color: AppColors.adminPrimary.withOpacity(0.7), size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.adminPrimary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: yearSecCtrl,
                    decoration: InputDecoration(
                      labelText: 'Year & Section (e.g. 2-A)',
                      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      floatingLabelStyle: const TextStyle(color: AppColors.adminPrimary, fontWeight: FontWeight.bold),
                      prefixIcon: Icon(Icons.grid_view_outlined, color: AppColors.adminPrimary.withOpacity(0.7), size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.adminPrimary, width: 2),
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
                backgroundColor: AppColors.adminPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      setDialogState(() => isLoading = true);
                      try {
                        final defaultPassword = await context.read<AppState>().createStudent(
                              firstName: firstNameCtrl.text,
                              lastName: lastNameCtrl.text,
                              email: emailCtrl.text,
                              courseCode: courseCtrl.text,
                              yearSection: yearSecCtrl.text,
                              studentNumber: studentNumCtrl.text,
                            );
                        if (!mounted) return;
                        Navigator.pop(dialogCtx);
                        await AppDialog.result(
                          context,
                          type: DialogType.success,
                          message: 'Account created successfully.\n\nEmail: ${emailCtrl.text.trim()}\nDefault Password: $defaultPassword\n\nShare these credentials with the student.',
                        );
                      } on AuthException catch (e) {
                        setDialogState(() => isLoading = false);
                        if (!mounted) return;
                        await AppDialog.alert(context, title: 'Error', message: e.message ?? 'Failed to create student.');
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        if (!mounted) return;
                        await AppDialog.alert(context, title: 'Error', message: e.toString());
                      }
                    },
              child: isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('Create Student', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
