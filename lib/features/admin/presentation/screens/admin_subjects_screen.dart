import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../auth/domain/models/auth_exception.dart';
import '../widgets/admin_drawer.dart';

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
    setState(() {
      // Rebuild against the latest AppState data.
    });
  }

  void _clearFilters() {
    _subjectNameController.clear();
    _courseController.clear();
    _professorController.clear();
    setState(() {
      // Rebuild against the latest AppState data.
    });
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
        actions: [
          const Center(
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
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const AdminDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateSubjectDialog,
        backgroundColor: AppColors.adminPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  child: ValueListenableBuilder<List<Map<String, String>>>(
                    valueListenable: appState.subjectOfferingsNotifier,
                    builder: (context, subjects, child) {
                      final filteredSubjects = _filterSubjects(subjects);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Pending Requests', null),

                          ValueListenableBuilder<List<Map<String, String>>>(
                            valueListenable:
                                appState.pendingSubjectRequestsNotifier,
                            builder: (context, pendingRequests, child) {
                              if (pendingRequests.isEmpty) {
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 24,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.black12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'No pending request',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                );
                              }
                              return ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxHeight: 350,
                                ),
                                child: SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: Column(
                                    children: pendingRequests
                                        .map(
                                          (s) => _buildSubjectItem(
                                            s['name']!,
                                            s['status']!,
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildSectionTitle('Subject List', null),
                                Row(
                                  children: [
                                    const Text(
                                      'Total: ',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '${filteredSubjects.length}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.adminPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          _buildSearchArea(subjects),
                          const SizedBox(height: 16),
                          _buildSubjectListArea(filteredSubjects, subjects),
                        ],
                      );
                    },
                  ),
        ),
    );
  }

  Widget _buildSectionTitle(String title, String? trailingText) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.adminPrimary,
            ),
          ),
          if (trailingText != null)
            Text(
              trailingText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.adminPrimary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubjectItem(String name, String status) {
    return _PendingSubjectCard(name: name, status: status);
  }

  List<Map<String, String>> _filterSubjects(
    List<Map<String, String>> subjects,
  ) {
    return subjects.where((subject) {
      final nameMatch = (subject['name'] ?? '').toLowerCase().contains(
        _subjectNameController.text.toLowerCase(),
      );
      final courseMatch = (subject['course'] ?? '').toLowerCase().contains(
        _courseController.text.toLowerCase(),
      );
      final professorMatch = (subject['professor'] ?? '').toLowerCase().contains(
        _professorController.text.toLowerCase(),
      );
      return nameMatch && courseMatch && professorMatch;
    }).toList();
  }

  Widget _buildSearchArea(List<Map<String, String>> subjects) {
    final courseList =
        subjects
            .map((subject) => subject['course'] ?? '')
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final professorList =
        subjects
            .map((subject) => subject['professor'] ?? '')
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 45,
                  child: TextField(
                    controller: _subjectNameController,
                    onChanged: (_) => _filterList(),
                    decoration: InputDecoration(
                      hintText: 'Subject Name',
                      hintStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildSearchButton(),
              const SizedBox(width: 8),
              _buildClearFilterButton(),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildComboField(
                  'Course',
                  _courseController,
                  courseList,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildComboField(
                  'Professor',
                  _professorController,
                  professorList,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchButton() {
    return Material(
      color: const Color(0xFF1A46A0),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: _filterList,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: const Row(
            children: [
              Icon(Icons.search, color: Colors.white, size: 18),
              SizedBox(width: 4),
              Text(
                'Search',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClearFilterButton() {
    return Material(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: _clearFilters,
        borderRadius: BorderRadius.circular(8),
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.filter_alt_off, color: Colors.black54),
        ),
      ),
    );
  }

  Widget _buildComboField(
    String hint,
    TextEditingController controller,
    List<String> items,
  ) {
    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (_) => _filterList(),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
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
                .map(
                  (choice) => PopupMenuItem(value: choice, child: Text(choice)),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  List<String> _getCoursesForSubject(
    String subjectName,
    List<Map<String, String>> subjects,
  ) {
    final courses = subjects
        .where((s) => s['name'] == subjectName)
        .map((s) => '${s['course'] ?? ''} ${s['section'] ?? ''}'.trim())
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList();
    return courses.isEmpty ? ['—'] : courses;
  }

  Widget _buildSubjectListArea(
    List<Map<String, String>> filteredSubjects,
    List<Map<String, String>> subjects,
  ) {
    if (filteredSubjects.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No subjects in the list',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Column(
      children: List.generate(filteredSubjects.length, (index) {
        final subject = filteredSubjects[index];
        final courses = _getCoursesForSubject(subject['name'] ?? '', subjects);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Material(
            color: Colors.transparent,
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
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        subject['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: _buildTableDropdown(
                        '${subject['course'] ?? ''} ${subject['section'] ?? ''}'.trim(),
                        courses,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: Container(
                        height: 32,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Text(
                          subject['professor'] ?? '',
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                          overflow: TextOverflow.visible,
                        ),
                      ),
                    ),
                  ],
                ),
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
          color: Colors.white,
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.centerLeft,
        child: const Text('—', style: TextStyle(fontSize: 12, color: Colors.black54)),
      );
    }
    final currentValue = items.contains(value) ? value : items.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, size: 18, color: Colors.black54),
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          onChanged: (val) {},
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        ),
      ),
    );
  }

  void _showCreateSubjectDialog() {
    final subjectNameCtrl = TextEditingController();
    final courseCodeCtrl = TextEditingController();
    final sectionCtrl = TextEditingController();
    final yearLevelCtrl = TextEditingController();
    final semesterCtrl = TextEditingController();
    final roomCtrl = TextEditingController();
    final scheduleCtrl = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Subject'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: subjectNameCtrl, decoration: const InputDecoration(labelText: 'Subject Name')),
                TextField(controller: courseCodeCtrl, decoration: const InputDecoration(labelText: 'Course Code')),
                TextField(controller: sectionCtrl, decoration: const InputDecoration(labelText: 'Section')),
                TextField(controller: yearLevelCtrl, decoration: const InputDecoration(labelText: 'Year Level (1-4)'), keyboardType: TextInputType.number),
                TextField(controller: semesterCtrl, decoration: const InputDecoration(labelText: 'Semester (1 or 2)'), keyboardType: TextInputType.number),
                TextField(controller: roomCtrl, decoration: const InputDecoration(labelText: 'Room (Optional)')),
                TextField(controller: scheduleCtrl, decoration: const InputDecoration(labelText: 'Schedule (Optional)')),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final yearLevel = int.tryParse(yearLevelCtrl.text.trim());
                      final semester = int.tryParse(semesterCtrl.text.trim());
                      if (subjectNameCtrl.text.trim().isEmpty ||
                          courseCodeCtrl.text.trim().isEmpty ||
                          sectionCtrl.text.trim().isEmpty ||
                          yearLevel == null) {
                        AppDialog.alert(ctx, title: 'Error', message: 'Please fill in all required fields.');
                        return;
                      }
                      setDialogState(() => isLoading = true);
                      try {
                        await context.read<AppState>().createSubject(
                          subjectName: subjectNameCtrl.text,
                          courseCode: courseCodeCtrl.text,
                          section: sectionCtrl.text,
                          yearLevel: yearLevel,
                          semester: semester,
                          room: roomCtrl.text,
                          scheduleLabel: scheduleCtrl.text,
                        );
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        AppDialog.result(context, type: DialogType.success, message: 'Subject created successfully.');
                      } on AuthException catch (e) {
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        AppDialog.alert(context, title: 'Error', message: e.message ?? 'Failed to create subject.');
                      } catch (e) {
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        AppDialog.alert(context, title: 'Error', message: e.toString());
                      }
                    },
              child: isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create'),
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
