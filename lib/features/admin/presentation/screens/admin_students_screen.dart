import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as xl;
import 'dart:math' as math;

import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/utils/upper_case_text_formatter.dart';
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
  late ScrollController _scrollController;
  bool _showStickyFilter = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      final double offset = _scrollController.offset;
      final bool shouldShow = offset > 180; // threshold when top filters scroll out
      if (shouldShow != _showStickyFilter) {
        setState(() {
          _showStickyFilter = shouldShow;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
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

              return Stack(
                children: [
                  SingleChildScrollView(
                    controller: _scrollController,
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
                                const Text(
                                  'Student Directory',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.adminPrimary,
                                  ),
                                ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.adminPrimary.withValues(alpha: 0.1),
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
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: _handleImportExcel,
                                  icon: const Icon(Icons.upload_file_rounded, color: Colors.white, size: 18),
                                  label: const Text('Import Excel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2E7D32),
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
                                color: Colors.black.withValues(alpha: 0.02),
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
              ),
              Positioned(
                top: 0,
                left: 16,
                right: 16,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 200),
                      offset: _showStickyFilter ? Offset.zero : const Offset(0, -1.5),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _showStickyFilter ? 1.0 : 0.0,
                        child: Container(
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Container(
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F6F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: (_) => _applyFilter(),
                                    decoration: InputDecoration(
                                      hintText: 'Search...',
                                      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                      prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 18),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  height: 38,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F6F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      value: _selectedCourse,
                                      hint: const Text('Course & Sec', style: TextStyle(fontSize: 12)),
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedCourse = val;
                                        });
                                        _applyFilter();
                                      },
                                      items: [
                                        const DropdownMenuItem<String>(value: null, child: Text('All Courses', style: TextStyle(fontSize: 12))),
                                        ...courseSectionList.map((sec) => DropdownMenuItem<String>(
                                          value: sec,
                                          child: Text(sec, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                                        )),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                onPressed: _clearFilter,
                                icon: const Icon(Icons.filter_alt_off_rounded, color: Colors.black54, size: 20),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                tooltip: 'Clear filters',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
          ),
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
                icon: const Icon(Icons.chevron_left_rounded, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: currentPage > 0 ? const Color(0xFFF5F6F9) : Colors.transparent,
                  foregroundColor: currentPage > 0 ? Colors.black87 : Colors.grey.shade300,
                  disabledBackgroundColor: Colors.transparent,
                  disabledForegroundColor: Colors.grey.shade300,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(8),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: currentPage < pageCount - 1
                    ? () => setState(() => _currentPage = currentPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right_rounded, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: currentPage < pageCount - 1 ? const Color(0xFFF5F6F9) : Colors.transparent,
                  foregroundColor: currentPage < pageCount - 1 ? Colors.black87 : Colors.grey.shade300,
                  disabledBackgroundColor: Colors.transparent,
                  disabledForegroundColor: Colors.grey.shade300,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(8),
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
                backgroundColor: AppColors.adminPrimary.withValues(alpha: 0.08),
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
            ],
          ),
        ),
      ),
    );
  }

  void _showEditStudentDialog(StudentData student) {
    final nameCtrl = TextEditingController(text: student.name);
    String? selectedCourse = student.course.isNotEmpty ? student.course : null;
    String? selectedYearSec = student.yearSection.isNotEmpty ? student.yearSection : null;

    final courseList = context.read<AppState>().students.map((s) => s.course).toSet().where((c) => c.isNotEmpty).toList()..sort();
    if (!courseList.contains('BSIT')) courseList.add('BSIT');
    if (!courseList.contains('BSCS')) courseList.add('BSCS');
    if (!courseList.contains('BSCPE')) courseList.add('BSCPE');
    courseList.sort();
    if (selectedCourse != null && !courseList.contains(selectedCourse)) {
      courseList.add(selectedCourse);
      courseList.sort();
    }

    final yearSecList = [
      '1-1', '1-2', '1-3', '2-1', '2-2', '2-3', '3-1', '3-2', '3-3', '4-1', '4-2', '4-3'
    ];
    if (selectedYearSec != null && !yearSecList.contains(selectedYearSec)) {
      yearSecList.add(selectedYearSec);
      yearSecList.sort();
    }

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
                      color: AppColors.adminPrimary.withValues(alpha: 0.1),
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
            width: double.infinity,
            constraints: BoxConstraints(maxWidth: 460),
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
                      prefixIcon: Icon(Icons.person_outline, color: AppColors.adminPrimary.withValues(alpha: 0.7), size: 20),
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
                  DropdownButtonFormField<String>(
                    value: selectedCourse,
                    hint: Text('Select Course', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    decoration: InputDecoration(
                      labelText: 'Course',
                      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      floatingLabelStyle: const TextStyle(color: AppColors.adminPrimary, fontWeight: FontWeight.bold),
                      prefixIcon: Icon(Icons.school_outlined, color: AppColors.adminPrimary.withValues(alpha: 0.7), size: 20),
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
                    items: courseList.map((course) {
                      return DropdownMenuItem(
                        value: course,
                        child: Text(course, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedCourse = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedYearSec,
                    hint: Text('Select Year & Section', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    decoration: InputDecoration(
                      labelText: 'Year & Section',
                      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      floatingLabelStyle: const TextStyle(color: AppColors.adminPrimary, fontWeight: FontWeight.bold),
                      prefixIcon: Icon(Icons.grid_view_outlined, color: AppColors.adminPrimary.withValues(alpha: 0.7), size: 20),
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
                    items: [
                      ...yearSecList.map((ys) {
                        return DropdownMenuItem(
                          value: ys,
                          child: Text(ys, style: const TextStyle(fontSize: 13)),
                        );
                      }),
                      const DropdownMenuItem(
                        value: '__ADD_CUSTOM__',
                        child: Text(
                          '+ Add Custom Section',
                          style: TextStyle(
                            color: AppColors.adminPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (val) async {
                      if (val == '__ADD_CUSTOM__') {
                        final customCtrl = TextEditingController();
                        final newSec = await showDialog<String>(
                          context: dialogCtx,
                          builder: (customCtx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: const Text('New Custom Section', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.adminPrimary)),
                            content: TextField(
                              controller: customCtrl,
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                labelText: 'Section Name (e.g. 1-C)',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(customCtx),
                                child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.adminPrimary),
                                onPressed: () => Navigator.pop(customCtx, customCtrl.text.trim()),
                                child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                        if (newSec != null && newSec.isNotEmpty) {
                          setDialogState(() {
                            if (!yearSecList.contains(newSec)) {
                              yearSecList.add(newSec);
                              yearSecList.sort();
                            }
                            selectedYearSec = newSec;
                          });
                        }
                      } else {
                        setDialogState(() {
                          selectedYearSec = val;
                        });
                      }
                    },
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
                      if (nameCtrl.text.trim().isEmpty || selectedCourse == null || selectedYearSec == null) {
                        AppDialog.result(dialogCtx, type: DialogType.error, message: 'Please fill in all required fields.');
                        return;
                      }
                      setDialogState(() => isLoading = true);
                      try {
                        await context.read<AppState>().updateStudent(
                              profileId: student.profileId,
                              name: nameCtrl.text,
                              course: selectedCourse!,
                              yearSection: selectedYearSec!,
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
                'Delete "${student.name}"? This will revoke their access and delete their profiles permanently.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.normal),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
            ],
          ),
          content: Container(
            width: double.infinity,
            constraints: BoxConstraints(maxWidth: 400),
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
    String? selectedCourse;
    String? selectedYearSec;

    final courseList = context.read<AppState>().students.map((s) => s.course).toSet().where((c) => c.isNotEmpty).toList()..sort();
    if (!courseList.contains('BSIT')) courseList.add('BSIT');
    if (!courseList.contains('BSCS')) courseList.add('BSCS');
    if (!courseList.contains('BSCPE')) courseList.add('BSCPE');
    courseList.sort();

    final yearSecList = [
      '1-1', '1-2', '1-3', '2-1', '2-2', '2-3', '3-1', '3-2', '3-3', '4-1', '4-2', '4-3'
    ];

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
                      color: AppColors.adminPrimary.withValues(alpha: 0.1),
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
            width: double.infinity,
            constraints: BoxConstraints(maxWidth: 460),
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
                      prefixIcon: Icon(Icons.email_outlined, color: AppColors.adminPrimary.withValues(alpha: 0.7), size: 20),
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
                      prefixIcon: Icon(Icons.person_outline, color: AppColors.adminPrimary.withValues(alpha: 0.7), size: 20),
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
                      prefixIcon: Icon(Icons.person_outline, color: AppColors.adminPrimary.withValues(alpha: 0.7), size: 20),
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
                  DropdownButtonFormField<String>(
                    value: selectedCourse,
                    hint: Text('Select Course', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    decoration: InputDecoration(
                      labelText: 'Course',
                      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      floatingLabelStyle: const TextStyle(color: AppColors.adminPrimary, fontWeight: FontWeight.bold),
                      prefixIcon: Icon(Icons.school_outlined, color: AppColors.adminPrimary.withValues(alpha: 0.7), size: 20),
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
                    items: courseList.map((course) {
                      return DropdownMenuItem(
                        value: course,
                        child: Text(course, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedCourse = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedYearSec,
                    hint: Text('Select Year & Section', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    decoration: InputDecoration(
                      labelText: 'Year & Section',
                      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      floatingLabelStyle: const TextStyle(color: AppColors.adminPrimary, fontWeight: FontWeight.bold),
                      prefixIcon: Icon(Icons.grid_view_outlined, color: AppColors.adminPrimary.withValues(alpha: 0.7), size: 20),
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
                    items: [
                      ...yearSecList.map((ys) {
                        return DropdownMenuItem(
                          value: ys,
                          child: Text(ys, style: const TextStyle(fontSize: 13)),
                        );
                      }),
                      const DropdownMenuItem(
                        value: '__ADD_CUSTOM__',
                        child: Text(
                          '+ Add Custom Section',
                          style: TextStyle(
                            color: AppColors.adminPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (val) async {
                      if (val == '__ADD_CUSTOM__') {
                        final customCtrl = TextEditingController();
                        final newSec = await showDialog<String>(
                          context: dialogCtx,
                          builder: (customCtx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: const Text('New Custom Section', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.adminPrimary)),
                            content: TextField(
                              controller: customCtrl,
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                labelText: 'Section Name (e.g. 1-C)',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(customCtx),
                                child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.adminPrimary),
                                onPressed: () => Navigator.pop(customCtx, customCtrl.text.trim()),
                                child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                        if (newSec != null && newSec.isNotEmpty) {
                          setDialogState(() {
                            if (!yearSecList.contains(newSec)) {
                              yearSecList.add(newSec);
                              yearSecList.sort();
                            }
                            selectedYearSec = newSec;
                          });
                        }
                      } else {
                        setDialogState(() {
                          selectedYearSec = val;
                        });
                      }
                    },
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
                      if (firstNameCtrl.text.trim().isEmpty || lastNameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty || selectedCourse == null || selectedYearSec == null) {
                        AppDialog.result(dialogCtx, type: DialogType.error, message: 'Please fill in all required fields.');
                        return;
                      }
                      setDialogState(() => isLoading = true);
                      try {
                        final defaultPassword = await context.read<AppState>().createStudent(
                              firstName: firstNameCtrl.text,
                              lastName: lastNameCtrl.text,
                              email: emailCtrl.text,
                              courseCode: selectedCourse!,
                              yearSection: selectedYearSec!,
                              studentNumber: null,
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

  /// Safely extract a string value from an excel Data cell.
  String _cellValue(dynamic cell) {
    if (cell == null) return '';
    try {
      final value = cell.value;
      if (value == null) return '';
      return value.toString().trim();
    } catch (_) {
      return '';
    }
  }

  Future<void> _handleImportExcel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final Uint8List? bytes = file.bytes;

      if (bytes == null) {
        if (!mounted) return;
        await AppDialog.alert(context, title: 'Error', message: 'Could not read the selected file.');
        return;
      }

      // Parse Excel — convert to List<int> for web compatibility
      final xl.Excel excel = xl.Excel.decodeBytes(bytes.toList());

      if (excel.tables.isEmpty) {
        if (!mounted) return;
        await AppDialog.alert(context, title: 'Empty File', message: 'The Excel file contains no sheets.');
        return;
      }

      final sheet = excel.tables.values.first;
      if (sheet.rows.length < 2) {
        if (!mounted) return;
        await AppDialog.alert(context, title: 'Empty File', message: 'The Excel file has no data rows.');
        return;
      }

      // Get headers (row 0)
      final headers = sheet.rows.first
          .map((cell) => _cellValue(cell).toLowerCase())
          .toList();

      final nameIdx = headers.indexOf('name');
      final emailIdx = headers.indexOf('email');
      final courseIdx = headers.indexOf('course');
      final yearSecIdx = headers.indexOf('yearsection');
      final studentNumIdx = headers.indexOf('studentnumber');

      if (nameIdx == -1 || emailIdx == -1 || courseIdx == -1 || yearSecIdx == -1) {
        if (!mounted) return;
        await AppDialog.alert(
          context,
          title: 'Invalid Format',
          message: 'The Excel file must have columns: name, email, course, yearSection.\n\nstudentNumber is optional.\n\nFound headers: ${headers.where((h) => h.isNotEmpty).join(", ")}',
        );
        return;
      }

      // Parse data rows
      final List<Map<String, String>> students = [];
      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        final name = row.length > nameIdx ? _cellValue(row[nameIdx]) : '';
        final email = row.length > emailIdx ? _cellValue(row[emailIdx]) : '';
        final course = row.length > courseIdx ? _cellValue(row[courseIdx]) : '';
        final yearSec = row.length > yearSecIdx ? _cellValue(row[yearSecIdx]) : '';
        final studentNum = studentNumIdx >= 0 && row.length > studentNumIdx
            ? _cellValue(row[studentNumIdx])
            : '';

        if (name.isEmpty && email.isEmpty) continue; // skip empty rows

        students.add({
          'name': name,
          'email': email,
          'course': course,
          'yearSection': yearSec,
          'studentNumber': studentNum,
        });
      }

      if (students.isEmpty) {
        if (!mounted) return;
        await AppDialog.alert(context, title: 'No Data', message: 'No valid student rows found in the file.');
        return;
      }

      // Show confirmation dialog
      if (!mounted) return;
      _showImportConfirmation(students, file.name);
    } catch (e) {
      if (!mounted) return;
      await AppDialog.alert(context, title: 'Error', message: 'Failed to read file: $e');
    }
  }

  void _showImportConfirmation(List<Map<String, String>> students, String fileName) {
    bool isImporting = false;

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
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.upload_file_rounded, color: Color(0xFF2E7D32), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Import Students',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.adminPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'File: $fileName',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.normal),
              ),
              const SizedBox(height: 4),
              Text(
                '${students.length} student(s) found. Default password: Studfy@123',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.normal),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
            ],
          ),
          content: SizedBox(
            width: double.infinity,
            height: 300,
            child: ListView.separated(
              itemCount: students.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final s = students[i];
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.adminPrimary.withValues(alpha: 0.08),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.adminPrimary),
                    ),
                  ),
                  title: Text(s['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text(
                    '${s['email']}  •  ${s['course']} ${s['yearSection']}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isImporting ? null : () => Navigator.pop(dialogCtx),
              child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isImporting
                  ? null
                  : () async {
                      setDialogState(() => isImporting = true);
                      try {
                        final result = await context.read<AppState>().bulkImportStudents(students);
                        if (!mounted) return;
                        Navigator.pop(dialogCtx);
                        _showImportResults(result);
                      } catch (e) {
                        setDialogState(() => isImporting = false);
                        if (!mounted) return;
                        await AppDialog.alert(dialogCtx, title: 'Import Failed', message: e.toString());
                      }
                    },
              icon: isImporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Icon(Icons.upload_rounded, size: 18),
              label: Text(
                isImporting ? 'Importing...' : 'Import ${students.length} Students',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImportResults(Map<String, dynamic> result) {
    final summary = result['summary'] as Map<String, dynamic>? ?? {};
    final results = (result['results'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    final int total = (summary['total'] as num?)?.toInt() ?? 0;
    final int created = (summary['created'] as num?)?.toInt() ?? 0;
    final int skipped = (summary['skipped'] as num?)?.toInt() ?? 0;
    final int errors = (summary['errors'] as num?)?.toInt() ?? 0;

    final successList = results.where((r) => r['status'] == 'created').toList();
    final skippedList = results.where((r) => r['status'] == 'skipped').toList();
    final errorList = results.where((r) => r['status'] == 'error').toList();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
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
                    color: created > 0
                        ? const Color(0xFF2E7D32).withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    created > 0 ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                    color: created > 0 ? const Color(0xFF2E7D32) : Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Import Results',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.adminPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Summary chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _summaryChip('Total', total, Colors.grey),
                _summaryChip('Created', created, const Color(0xFF2E7D32)),
                _summaryChip('Already Exist', skipped, Colors.orange),
                if (errors > 0) _summaryChip('Errors', errors, Colors.red),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
          ],
        ),
        content: SizedBox(
          width: double.infinity,
          height: 350,
          child: ListView(
            children: [
              if (successList.isNotEmpty) ...[
                _resultSectionHeader('Successfully Imported', Icons.check_circle_outline, const Color(0xFF2E7D32)),
                ...successList.map((r) => _resultTile(
                  r['name']?.toString() ?? r['email']?.toString() ?? '',
                  r['email']?.toString() ?? '',
                  Icons.check_circle_rounded,
                  const Color(0xFF2E7D32),
                )),
                const SizedBox(height: 12),
              ],
              if (skippedList.isNotEmpty) ...[
                _resultSectionHeader('Already Exist in System', Icons.info_outline, Colors.orange),
                ...skippedList.map((r) => _resultTile(
                  r['name']?.toString() ?? r['email']?.toString() ?? '',
                  r['reason']?.toString() ?? 'Already registered',
                  Icons.info_rounded,
                  Colors.orange,
                )),
                const SizedBox(height: 12),
              ],
              if (errorList.isNotEmpty) ...[
                _resultSectionHeader('Failed to Import', Icons.error_outline, Colors.red),
                ...errorList.map((r) => _resultTile(
                  r['name']?.toString() ?? r['email']?.toString() ?? '',
                  r['reason']?.toString() ?? 'Unknown error',
                  Icons.error_rounded,
                  Colors.red,
                )),
              ],
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.adminPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _resultSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
          ),
        ],
      ),
    );
  }

  Widget _resultTile(String name, String subtitle, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
