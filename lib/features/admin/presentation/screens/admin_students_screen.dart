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
import '../widgets/admin_drawer.dart';

class AdminStudentsScreen extends StatefulWidget {
  const AdminStudentsScreen({super.key});

  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> {
  int? _hoveredStudentIndex;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCourse;
  String? _selectedSubject;
  static const int _pageSize = 20;
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
      _selectedSubject = null;
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

  List<String> _subjectOptions(List<Map<String, String>> subjects) {
    final options = subjects
        .map((s) => s['name'] ?? '')
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return options.isEmpty ? ['No subjects available'] : options;
  }

  List<StudentData> _filterStudents(List<StudentData> students) {
    return students.where((student) {
      final courseSection = '${student.course} ${student.yearSection}';
      final nameMatch = student.name.toLowerCase().contains(_searchController.text.toLowerCase());
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
            Text('STUDFY', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.white),
            tooltip: 'Add Student',
            onPressed: _showCreateStudentDialog,
          ),
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Admin 1', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const AdminDrawer(),
      body: ValueListenableBuilder<List<StudentData>>(
        valueListenable: appState.studentsNotifier,
        builder: (context, students, _) {
          final subjectOptions = _subjectOptions(appState.subjectOfferings);
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

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Student List', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.adminPrimary)),
                    Row(
                      children: [
                        const Text('Total: ', style: TextStyle(fontSize: 14, color: Colors.grey)),
                        Text('${filteredStudents.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.adminPrimary)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSearchArea(courseSectionList, subjectOptions),
                const SizedBox(height: 12),
                Expanded(child: _buildStudentList(pagedStudents)),
                _buildPagination(totalItems: filteredStudents.length, pageCount: pageCount, currentPage: safePage),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchArea(List<String> courseSectionList, List<String> subjectOptions) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 42,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black12)),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => _applyFilter(),
                  decoration: const InputDecoration(
                    hintText: 'Student Name / Student Number',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: const Color(0xFF1A46A0),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: _applyFilter,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: Colors.white, size: 18),
                      SizedBox(width: 4),
                      Text('Search', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(onPressed: _clearFilter, icon: const Icon(Icons.filter_alt_off, color: Colors.black54)),
          ],
        ),
        const SizedBox(height: 8),
        _buildFilterDropdown(hint: 'Course & Section', value: _selectedCourse, items: courseSectionList, onChanged: (val) => setState(() { _selectedCourse = val; _applyFilter(); })),
      ],
    );
  }

  Widget _buildFilterDropdown({required String hint, required String? value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return DropdownMenu<String>(
      expandedInsets: EdgeInsets.zero,
      initialSelection: value,
      hintText: hint,
      enableSearch: true,
      enableFilter: true,
      requestFocusOnTap: true,
      menuHeight: 300,
      onSelected: onChanged,
      dropdownMenuEntries: items.map((e) => DropdownMenuEntry(value: e, label: e, style: MenuItemButton.styleFrom(visualDensity: VisualDensity.compact))).toList(),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        constraints: const BoxConstraints(maxHeight: 42),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.adminPrimary, width: 1)),
      ),
    );
  }

  Widget _buildPagination({required int totalItems, required int pageCount, required int currentPage}) {
    if (totalItems == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Page ${currentPage + 1} of $pageCount', style: const TextStyle(fontSize: 12, color: Colors.black54)),
          Row(
            children: [
              IconButton(onPressed: currentPage > 0 ? () => setState(() => _currentPage = currentPage - 1) : null, icon: const Icon(Icons.chevron_left)),
              IconButton(onPressed: currentPage < pageCount - 1 ? () => setState(() => _currentPage = currentPage + 1) : null, icon: const Icon(Icons.chevron_right)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList(List<StudentData> students) {
    if (students.isEmpty) {
      return const Center(child: Text('No students in the list', style: TextStyle(color: Colors.grey, fontSize: 14, fontStyle: FontStyle.italic)));
    }
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 16),
        itemCount: students.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12, indent: 12, endIndent: 12),
        itemBuilder: (context, index) => _buildStudentRow(students[index]),
      ),
    );
  }

  Widget _buildStudentRow(StudentData student) {
    final rowKey = student.profileId.hashCode;
    final isHovered = _hoveredStudentIndex == rowKey;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredStudentIndex = rowKey),
      onExit: (_) => setState(() => _hoveredStudentIndex = null),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.pushNamed(AppRoutes.adminStudentsProfile, pathParameters: {'profileId': student.profileId}, extra: {'student': student}),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: isHovered ? Colors.grey.shade50 : Colors.transparent,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  student.name,
                  style: TextStyle(fontSize: 13, fontWeight: isHovered ? FontWeight.bold : FontWeight.w500, color: isHovered ? AppColors.adminPrimary : Colors.black87),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: Container(
                  height: 30,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.black12)),
                  child: Text('${student.course} ${student.yearSection}', style: const TextStyle(fontSize: 11, color: Colors.black87)),
                ),
              ),
              if (isHovered) ...[
                const SizedBox(width: 8),
                IconButton(icon: const Icon(Icons.edit, size: 18, color: Colors.blue), onPressed: () => _showEditStudentDialog(student), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                const SizedBox(width: 8),
                IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () => _showDeleteStudentDialog(student), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              ],
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
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: const Text('Edit Student'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: courseCtrl, decoration: const InputDecoration(labelText: 'Course')),
              TextField(controller: yearSecCtrl, decoration: const InputDecoration(labelText: 'Year & Section')),
            ],
          ),
          actions: [
            TextButton(onPressed: isLoading ? null : () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                setDialogState(() => isLoading = true);
                Navigator.pop(dialogCtx);
                try {
                  await context.read<AppState>().updateStudent(
                    profileId: student.profileId,
                    name: nameCtrl.text,
                    course: courseCtrl.text,
                    yearSection: yearSecCtrl.text,
                  );
                  if (!mounted) return;
                  await AppDialog.result(context, type: DialogType.success, message: 'Student updated successfully.');
                } catch (e) {
                  if (!mounted) return;
                  await AppDialog.alert(context, title: 'Error', message: e.toString());
                }
              },
              child: isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteStudentDialog(StudentData student) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text('Are you sure you want to delete ${student.name}? This will revoke their access.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await context.read<AppState>().deleteProfile(student.profileId);
                if (!mounted) return;
                await AppDialog.result(context, type: DialogType.success, message: 'Student deleted successfully.');
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
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: const Text('Add Student'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email Address'), keyboardType: TextInputType.emailAddress),
                TextField(controller: firstNameCtrl, decoration: const InputDecoration(labelText: 'First Name')),
                TextField(controller: lastNameCtrl, decoration: const InputDecoration(labelText: 'Last Name')),
                TextField(controller: studentNumCtrl, decoration: const InputDecoration(labelText: 'Student Number (Optional)')),
                TextField(controller: courseCtrl, decoration: const InputDecoration(labelText: 'Course (e.g. BSIT)')),
                TextField(controller: yearSecCtrl, decoration: const InputDecoration(labelText: 'Year & Section (e.g. 2-A)')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: isLoading ? null : () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                setDialogState(() => isLoading = true);
                Navigator.pop(dialogCtx);
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
                  await AppDialog.result(
                    context,
                    type: DialogType.success,
                    message: 'Account created successfully.\n\nEmail: ${emailCtrl.text.trim()}\nDefault Password: $defaultPassword\n\nShare these credentials with the student.',
                  );
                } on AuthException catch (e) {
                  if (!mounted) return;
                  await AppDialog.alert(context, title: 'Error', message: e.message ?? 'Failed to create student.');
                } catch (e) {
                  if (!mounted) return;
                  await AppDialog.alert(context, title: 'Error', message: e.toString());
                }
              },
              child: isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
