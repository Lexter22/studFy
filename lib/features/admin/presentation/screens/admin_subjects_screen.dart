import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/utils/upper_case_text_formatter.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../auth/domain/models/auth_exception.dart';
import '../widgets/admin_floating_nav_bar.dart';

class AdminSubjectsScreen extends StatefulWidget {
  const AdminSubjectsScreen({super.key});

  @override
  State<AdminSubjectsScreen> createState() => _AdminSubjectsScreenState();
}

class _AdminSubjectsScreenState extends State<AdminSubjectsScreen> {
  final TextEditingController _subjectNameController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _professorController = TextEditingController();

  @override
  void dispose() {
    _subjectNameController.dispose();
    _courseController.dispose();
    _professorController.dispose();
    super.dispose();
  }

  void _filterList() {
    setState(() {});
  }

  void _clearFilters() {
    _subjectNameController.clear();
    _courseController.clear();
    _professorController.clear();
    setState(() {});
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
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: ValueListenableBuilder<List<Map<String, String>>>(
                  valueListenable: appState.subjectOfferingsNotifier,
                  builder: (context, subjects, child) {
                    final filteredSubjects = _filterSubjects(subjects);

                    return Column(
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
                                  'Subject Directory',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.adminPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Manage class offerings, schedules, and faculty',
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
                                      const Icon(Icons.book_rounded, color: AppColors.adminPrimary, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${filteredSubjects.length} Total',
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
                                  onPressed: _showCreateSubjectDialog,
                                  icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                                  label: const Text('Add Subject', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                        const SizedBox(height: 24),

                        _buildSectionTitle('Pending Requests'),
                        const SizedBox(height: 8),

                        ValueListenableBuilder<List<Map<String, String>>>(
                          valueListenable: appState.pendingSubjectRequestsNotifier,
                          builder: (context, pendingRequests, child) {
                            if (pendingRequests.isEmpty) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'No pending requests',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }
                            return Column(
                              children: pendingRequests
                                  .map((s) => _buildSubjectItem(s['name']!, s['status']!))
                                  .toList(),
                            );
                          },
                        ),

                        const SizedBox(height: 28),

                        _buildSectionTitle('Subject Offerings'),
                        const SizedBox(height: 8),

                        // Search and Filter Card
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
                                        controller: _subjectNameController,
                                        onChanged: (_) => _filterList(),
                                        decoration: InputDecoration(
                                          hintText: 'Search by subject name...',
                                          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                                          border: InputBorder.none,
                                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  IconButton(
                                    onPressed: _clearFilters,
                                    icon: const Icon(Icons.filter_alt_off_rounded, color: Colors.black54),
                                    tooltip: 'Clear filters',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildComboField(
                                      'Filter by Course',
                                      _courseController,
                                      subjects.map((s) => s['course'] ?? '').where((v) => v.isNotEmpty).toSet().toList()..sort(),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildComboField(
                                      'Filter by Professor',
                                      _professorController,
                                      subjects.map((s) => s['professor'] ?? '').where((v) => v.isNotEmpty).toSet().toList()..sort(),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        _buildSubjectListArea(filteredSubjects, subjects),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          const AdminFloatingNavBar(currentIndex: 4),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.adminPrimary,
        ),
      ),
    );
  }

  Widget _buildSubjectItem(String name, String status) {
    return _PendingSubjectCard(name: name, status: status);
  }

  List<Map<String, String>> _filterSubjects(List<Map<String, String>> subjects) {
    return subjects.where((subject) {
      final nameMatch = (subject['name'] ?? '').toLowerCase().contains(_subjectNameController.text.toLowerCase());
      final courseMatch = (subject['course'] ?? '').toLowerCase().contains(_courseController.text.toLowerCase());
      final professorMatch = (subject['professor'] ?? '').toLowerCase().contains(_professorController.text.toLowerCase());
      return nameMatch && courseMatch && professorMatch;
    }).toList();
  }

  Widget _buildComboField(String hint, TextEditingController controller, List<String> items) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (_) => _filterList(),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
            onSelected: (val) {
              controller.text = val;
              _filterList();
            },
            itemBuilder: (ctx) => items
                .map((choice) => PopupMenuItem(value: choice, child: Text(choice)))
                .toList(),
          ),
        ],
      ),
    );
  }

  List<String> _getCoursesForSubject(String subjectName, List<Map<String, String>> subjects) {
    final courses = subjects
        .where((s) => s['name'] == subjectName)
        .map((s) => '${s['course'] ?? ''} ${s['section'] ?? ''}'.trim())
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList();
    return courses.isEmpty ? ['—'] : courses;
  }

  Widget _buildSubjectListArea(List<Map<String, String>> filteredSubjects, List<Map<String, String>> subjects) {
    if (filteredSubjects.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No subjects in the list',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return Column(
      children: List.generate(filteredSubjects.length, (index) {
        final subject = filteredSubjects[index];
        final courses = _getCoursesForSubject(subject['name'] ?? '', subjects);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: InkWell(
            onTap: () async {
              await context.pushNamed(
                AppRoutes.adminSubjectsProfile,
                extra: {
                  'subjectId': subject['id'],
                  'subjectName': subject['name'] ?? '',
                  'courseSection': '${subject['course'] ?? ''} ${subject['section'] ?? ''}'.trim(),
                  'professor': subject['professor'] ?? '',
                },
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.adminPrimary.withOpacity(0.08),
                    child: const Icon(Icons.book_rounded, color: AppColors.adminPrimary, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject['name'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Container(
                                height: 32,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F6F9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Text(
                                  '${subject['course'] ?? ''} ${subject['section'] ?? ''}'.trim(),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: Container(
                                height: 32,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F6F9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.person_outline_rounded, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        subject['professor'] ?? 'Unassigned',
                                        style: const TextStyle(fontSize: 11, color: Colors.black87),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTableDropdown(String value, List<String> items) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6F9),
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.centerLeft,
        child: const Text('—', style: TextStyle(fontSize: 11, color: Colors.black54)),
      );
    }
    final currentValue = items.contains(value) ? value : items.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F9),
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, size: 16, color: Colors.black54),
          style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.bold),
          onChanged: (val) {},
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        ),
      ),
    );
  }

  void _showCreateSubjectDialog() {
    final subjectNameCtrl = TextEditingController();
    final courseCodeCtrl = TextEditingController();
    final yearLevelCtrl = TextEditingController();
    final semesterCtrl = TextEditingController();
    final roomCtrl = TextEditingController();
    final scheduleCtrl = TextEditingController();
    
    // Fetch available sections from current state
    final appState = context.read<AppState>();
    final sectionsFromStudents = appState.students.map((s) => s.yearSection).toSet();
    final sectionsFromOfferings = appState.subjectOfferings.map((s) => s['section'] ?? '').toSet();
    final sectionsFromCodes = appState.enrollmentCodes.map((c) => c['year_section']?.toString() ?? '').toSet();
    
    final List<String> allSections = <String>{
      ...sectionsFromStudents, 
      ...sectionsFromOfferings, 
      ...sectionsFromCodes,
      '1-1', '1-2', '2-1', '2-2', '3-1', '3-2', '4-1', '4-2'
    }
        .where((s) => s.isNotEmpty)
        .toList()
      ..sort();

    final List<String> selectedSections = [];
    bool isLoading = false;

    void showMultiSectionSelector(BuildContext parentCtx, void Function(void Function()) setDialogState) {
      final customSectionCtrl = TextEditingController();
      showDialog(
        context: parentCtx,
        builder: (selectCtx) {
          return StatefulBuilder(
            builder: (selectCtx, setSelectState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Text(
                  'Select Sections',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.adminPrimary),
                ),
                content: Container(
                  width: 320,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: customSectionCtrl,
                              textCapitalization: TextCapitalization.characters,
                              inputFormatters: const [UpperCaseTextFormatter()],
                              decoration: InputDecoration(
                                hintText: 'Add custom section...',
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: AppColors.adminPrimary),
                            onPressed: () {
                              final text = customSectionCtrl.text.trim();
                              if (text.isNotEmpty) {
                                setSelectState(() {
                                  if (!allSections.contains(text)) {
                                    allSections.add(text);
                                    allSections.sort();
                                  }
                                  if (!selectedSections.contains(text)) {
                                    selectedSections.add(text);
                                  }
                                  customSectionCtrl.clear();
                                });
                                setDialogState(() {});
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 250),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: allSections.map((sec) {
                              final isSelected = selectedSections.contains(sec);
                              return CheckboxListTile(
                                title: Text(sec, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                value: isSelected,
                                activeColor: AppColors.adminPrimary,
                                contentPadding: EdgeInsets.zero,
                                controlAffinity: ListTileControlAffinity.leading,
                                onChanged: (val) {
                                  setSelectState(() {
                                    if (val == true) {
                                      if (!selectedSections.contains(sec)) {
                                        selectedSections.add(sec);
                                      }
                                    } else {
                                      selectedSections.remove(sec);
                                    }
                                  });
                                  setDialogState(() {});
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(selectCtx),
                    child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.adminPrimary)),
                  ),
                ],
              );
            },
          );
        },
      );
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
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
                    child: const Icon(Icons.add_rounded, color: AppColors.adminPrimary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Add New Subject',
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
                'Enter the details of the subject offering, year level, and schedule.',
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
                    controller: subjectNameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Subject Name',
                      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      floatingLabelStyle: const TextStyle(color: AppColors.adminPrimary, fontWeight: FontWeight.bold),
                      prefixIcon: Icon(Icons.book_outlined, color: AppColors.adminPrimary.withOpacity(0.7), size: 20),
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
                    controller: courseCodeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: const [UpperCaseTextFormatter()],
                    decoration: InputDecoration(
                      labelText: 'Course Code (e.g. BSIT)',
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
                  GestureDetector(
                    onTap: () => showMultiSectionSelector(ctx, setDialogState),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Section(s)',
                        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        floatingLabelStyle: const TextStyle(color: AppColors.adminPrimary, fontWeight: FontWeight.bold),
                        prefixIcon: Icon(Icons.class_outlined, color: AppColors.adminPrimary.withOpacity(0.7), size: 20),
                        suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.adminPrimary, width: 2),
                        ),
                      ),
                      child: selectedSections.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                'Select Section(s)',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: selectedSections.map((sec) => Chip(
                                  label: Text(
                                    sec,
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  backgroundColor: AppColors.adminPrimary,
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  onDeleted: () {
                                    setDialogState(() {
                                      selectedSections.remove(sec);
                                    });
                                  },
                                  deleteIcon: const Icon(Icons.close, size: 12, color: Colors.white),
                                )).toList(),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: yearLevelCtrl,
                    decoration: InputDecoration(
                      labelText: 'Year Level (1-4)',
                      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      floatingLabelStyle: const TextStyle(color: AppColors.adminPrimary, fontWeight: FontWeight.bold),
                      prefixIcon: Icon(Icons.format_list_numbered, color: AppColors.adminPrimary.withOpacity(0.7), size: 20),
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
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: semesterCtrl,
                    decoration: InputDecoration(
                      labelText: 'Semester (1 or 2)',
                      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      floatingLabelStyle: const TextStyle(color: AppColors.adminPrimary, fontWeight: FontWeight.bold),
                      prefixIcon: Icon(Icons.calendar_today_outlined, color: AppColors.adminPrimary.withOpacity(0.7), size: 20),
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
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: roomCtrl,
                    decoration: InputDecoration(
                      labelText: 'Room (Optional)',
                      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      floatingLabelStyle: const TextStyle(color: AppColors.adminPrimary, fontWeight: FontWeight.bold),
                      prefixIcon: Icon(Icons.meeting_room_outlined, color: AppColors.adminPrimary.withOpacity(0.7), size: 20),
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
                    controller: scheduleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Schedule (Optional)',
                      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      floatingLabelStyle: const TextStyle(color: AppColors.adminPrimary, fontWeight: FontWeight.bold),
                      prefixIcon: Icon(Icons.access_time_outlined, color: AppColors.adminPrimary.withOpacity(0.7), size: 20),
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
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
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
                      final yearLevel = int.tryParse(yearLevelCtrl.text.trim());
                      final semester = int.tryParse(semesterCtrl.text.trim());
                      if (subjectNameCtrl.text.trim().isEmpty ||
                          courseCodeCtrl.text.trim().isEmpty ||
                          selectedSections.isEmpty ||
                          yearLevel == null) {
                        AppDialog.alert(ctx, title: 'Error', message: 'Please fill in all required fields.');
                        return;
                      }
                      setDialogState(() => isLoading = true);
                      try {
                        for (final sec in selectedSections) {
                          await context.read<AppState>().createSubject(
                                subjectName: subjectNameCtrl.text,
                                courseCode: courseCodeCtrl.text,
                                section: sec,
                                yearLevel: yearLevel,
                                semester: semester,
                                room: roomCtrl.text,
                                scheduleLabel: scheduleCtrl.text,
                              );
                        }
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        await AppDialog.result(context, type: DialogType.success, message: 'Subjects created successfully.');
                      } on AuthException catch (e) {
                        setDialogState(() => isLoading = false);
                        await AppDialog.alert(context, title: 'Error', message: e.message ?? 'Failed to create subject offerings.');
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        await AppDialog.alert(context, title: 'Error', message: e.toString());
                      }
                    },
              child: isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('Create Subject', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingSubjectCard extends StatefulWidget {
  final String name;
  final String status;

  const _PendingSubjectCard({required this.name, required this.status});

  @override
  State<_PendingSubjectCard> createState() => _PendingSubjectCardState();
}

class _PendingSubjectCardState extends State<_PendingSubjectCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF3E0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bookmark_outline,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 19,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.status,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildViewDetailsBtn(() {
                context.pushNamed(
                  AppRoutes.adminSubjectsProfile,
                  extra: {
                    'subjectName': widget.name,
                    'courseSection': 'Pending',
                    'professor': 'Admin',
                    'pendingRequest': widget.status,
                  },
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF9E7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF7DC6F)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 3.5, backgroundColor: Color(0xFFB8860B)),
          SizedBox(width: 6),
          Text(
            'Pending',
            style: TextStyle(
              color: Color(0xFFB8860B),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewDetailsBtn(VoidCallback onTap) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.center,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'View Details',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
