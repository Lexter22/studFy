import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/state/app_state.dart';
import '../../domain/models/instructor.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../auth/domain/models/auth_exception.dart';
import '../widgets/admin_drawer.dart';

class AdminInstructorScreen extends StatefulWidget {
  const AdminInstructorScreen({super.key});

  @override
  State<AdminInstructorScreen> createState() => _AdminInstructorScreenState();
}

class _AdminInstructorScreenState extends State<AdminInstructorScreen> {

  // Controllers & State for Filtering
  final TextEditingController _profNameController = TextEditingController();
  String? _selectedCourse;
  String? _selectedSubject;

  @override
  void dispose() {
    _profNameController.dispose();
    super.dispose();
  }

  // --- CORE FILTER LOGIC ---
  void _filterList() {
    setState(() {
      // Rebuild against the latest AppState data.
    });
  }

  List<Instructor> _filteredInstructors(List<Instructor> source) {
    return source.where((instructor) {
      final nameMatch = instructor.name.toLowerCase().contains(
        _profNameController.text.toLowerCase(),
      );

      final courseMatch =
          _selectedCourse == null ||
          _selectedCourse!.isEmpty ||
          instructor.course == _selectedCourse;

      final subjectMatch =
          _selectedSubject == null ||
          _selectedSubject!.isEmpty ||
          instructor.subject == _selectedSubject;

      return nameMatch && courseMatch && subjectMatch;
    }).toList();
  }

  void _clearFilters() {
    _profNameController.clear();
    setState(() {
      _selectedCourse = null;
      _selectedSubject = null;
    });
  }

  void _navigateToInstructorProfile(String name, String? request) {
    final instructors = context.read<AppState>().instructors;
    final instructor = instructors.firstWhere(
      (i) => i.name == name,
      orElse: () => instructors.first,
    );

    context.pushNamed(
      AppRoutes.adminInstructorProfile,
      extra: {'instructor': instructor, 'request': request},
    );
  }

  void _showActionDialog(
    String action,
    String requestId,
    String name,
    String request,
  ) {
    final isApprove = action == 'Approve';
    AppDialog.confirm(
      context,
      title: '$action Request?',
      message: 'Are you sure you want to $action the "$request" from $name?',
      type: isApprove ? DialogType.success : DialogType.error,
      confirmLabel: action,
      onConfirm: () => _resolveRequest(
        requestId: requestId,
        approve: isApprove,
        action: action,
      ),
    );
  }

  Future<void> _resolveRequest({
    required String requestId,
    required bool approve,
    required String action,
  }) async {
    try {
      await context.read<AppState>().resolveInstructorRequest(
        requestId: requestId,
        approve: approve,
      );

      if (!mounted) {
        return;
      }

      await AppDialog.result(
        context,
        type: approve ? DialogType.success : DialogType.error,
        message: 'Request ${action.toLowerCase()}d successfully.',
      );
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.alert(
        context,
        title: 'Request Error',
        message: error.message ?? 'Unable to process request.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.alert(
        context,
        title: 'Request Error',
        message: 'Unable to process request: $error',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final filteredInstructors = _filteredInstructors(appState.instructors);
    final courseList =
        appState.instructors
            .map((instructor) => instructor.course)
            .toSet()
            .toList()
          ..sort();
    final subjectList =
        appState.instructors
            .map((instructor) => instructor.subject)
            .toSet()
            .toList()
          ..sort();

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
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.white),
            tooltip: 'Add Instructor',
            onPressed: _showCreateInstructorDialog,
          ),
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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel('Pending Requests'),
                      _buildRequestsArea(appState),
                      const SizedBox(height: 20),

                      // UPDATED HEADER: Title and Count inline
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Instructor List',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF800000),
                              ),
                            ),
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
                                  '${filteredInstructors.length}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF800000),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildSearchFilterArea(courseList, subjectList),
                      const SizedBox(height: 16),
                      _buildInstructorTableArea(filteredInstructors),
                    ],
                  ),
        ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFF800000),
        ),
      ),
    );
  }

  Widget _buildRequestsArea(AppState appState) {
    return ValueListenableBuilder<List<Map<String, String>>>(
      valueListenable: appState.pendingInstructorRequestsNotifier,
      builder: (context, pendingRequests, child) {
        if (pendingRequests.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'No pending requests in the list',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          );
        }
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: pendingRequests
                .map(
                  (r) => _buildPendingCard(
                    r['id'] ?? '',
                    r['name']!,
                    r['status']!,
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildPendingCard(String requestId, String name, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              CircleAvatar(
                backgroundColor: Colors.grey.shade200,
                child: const Icon(Icons.person, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionBtn(
                  'Approve',
                  Icons.check,
                  const Color(0xFFD4EDDA),
                  const Color(0xFF28A745),
                  () => _showActionDialog('Approve', requestId, name, subtitle),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionBtn(
                  'Reject',
                  Icons.close,
                  const Color(0xFFF8D7DA),
                  const Color(0xFFDC3545),
                  () => _showActionDialog('Reject', requestId, name, subtitle),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildViewDetailsBtn(
                  () => _navigateToInstructorProfile(name, subtitle),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFilterArea(
    List<String> courseList,
    List<String> subjectList,
  ) {
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
                    controller: _profNameController,
                    onChanged: (_) => _filterList(),
                    decoration: InputDecoration(
                      hintText: 'Professor Name',
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
                child: _buildGlobalDropdown(
                  'Course',
                  courseList,
                  _selectedCourse,
                  (val) => setState(() => _selectedCourse = val),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildGlobalDropdown(
                  'Subject',
                  subjectList,
                  _selectedSubject,
                  (val) => setState(() => _selectedSubject = val),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstructorTableArea(List<Instructor> filteredInstructors) {
    return Column(
      children: filteredInstructors.map((instructor) {
        final specificCourses = [instructor.course];
        final specificSubjects = [instructor.subject];

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _navigateToInstructorProfile(instructor.name, null),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        instructor.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.adminPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: _buildTableDropdown(
                        instructor.course,
                        specificCourses,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: _buildTableDropdown(
                        instructor.subject,
                        specificSubjects,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.assignment, size: 18, color: Colors.green),
                          tooltip: 'Assign Subject',
                          onPressed: () => _showAssignSubjectDialog(instructor),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                          tooltip: 'Edit',
                          onPressed: () => _showEditInstructorDialog(instructor),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                          tooltip: 'Delete',
                          onPressed: () => _showDeleteInstructorDialog(instructor),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- REUSABLE HELPERS ---

  Widget _buildActionBtn(
    String label,
    IconData icon,
    Color bg,
    Color text,
    VoidCallback onTap,
  ) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 38,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: text),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: text,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditInstructorDialog(Instructor instructor) {
    final nameCtrl = TextEditingController(text: instructor.name);
    final deptCtrl = TextEditingController(text: instructor.course);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Instructor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: deptCtrl, decoration: const InputDecoration(labelText: 'Department')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await context.read<AppState>().updateInstructor(
                  profileId: instructor.profileId,
                  name: nameCtrl.text,
                  department: deptCtrl.text,
                );
                if (!mounted) return;
                AppDialog.result(context, type: DialogType.success, message: 'Instructor updated successfully.');
              } catch (e) {
                if (!mounted) return;
                AppDialog.alert(context, title: 'Error', message: e.toString());
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteInstructorDialog(Instructor instructor) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Instructor'),
        content: Text('Are you sure you want to delete ${instructor.name}? This will revoke their access.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await context.read<AppState>().deleteProfile(instructor.profileId);
                if (!mounted) return;
                AppDialog.result(
                  context,
                  type: DialogType.success,
                  message: 'Instructor deleted successfully.',
                );
              } catch (e) {
                if (!mounted) return;
                AppDialog.alert(context, title: 'Error', message: e.toString());
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAssignSubjectDialog(Instructor instructor) {
    final subjects = context.read<AppState>().subjectOfferings;
    if (subjects.isEmpty) {
      AppDialog.alert(context, title: 'Notice', message: 'No subjects available to assign.');
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Assign Subject to ${instructor.name}'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];
                return ListTile(
                  title: Text(subject['name'] ?? 'Unknown Subject'),
                  subtitle: Text('${subject['course'] ?? ''} ${subject['section'] ?? ''}'),
                  onTap: () {
                    context.read<AppState>().assignProfessorToSubject(
                      subjectId: subject['id']!,
                      profileId: instructor.profileId,
                    );
                    Navigator.pop(context);
                    AppDialog.result(
                      context,
                      type: DialogType.success,
                      message: 'Subject assigned successfully.',
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
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
          height: 38,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                'View Details',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 2),
              Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlobalDropdown(
    String hint,
    List<String> items,
    String? currentValue,
    Function(String?) onChanged,
  ) {
    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          hint: Text(
            hint,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          value: currentValue,
          isExpanded: true,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (val) {
            onChanged(val);
            _filterList();
          },
        ),
      ),
    );
  }

  Widget _buildTableDropdown(String value, List<String> items) {
    String currentValue = items.contains(value) ? value : items.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          isExpanded: true,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          onChanged: (val) {},
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
        ),
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
          child: Row(
            children: const [
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

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.yellow.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        '● Pending',
        style: TextStyle(
          color: Color(0xFFB8860B),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showCreateInstructorDialog() {
    final firstNameCtrl = TextEditingController();
    final lastNameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final deptCtrl = TextEditingController();
    final instructorIdCtrl = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Instructor'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: firstNameCtrl,
                  decoration: const InputDecoration(labelText: 'First Name'),
                ),
                TextField(
                  controller: lastNameCtrl,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                ),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email Address'),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: deptCtrl,
                  decoration: const InputDecoration(labelText: 'Department'),
                ),
                TextField(
                  controller: instructorIdCtrl,
                  decoration: const InputDecoration(labelText: 'Instructor ID (Optional)'),
                ),
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
                      setDialogState(() => isLoading = true);
                      try {
                        final defaultPassword = await context.read<AppState>().createInstructor(
                          firstName: firstNameCtrl.text,
                          lastName: lastNameCtrl.text,
                          email: emailCtrl.text,
                          department: deptCtrl.text,
                          instructorId: instructorIdCtrl.text,
                        );
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        AppDialog.alert(
                          context,
                          title: 'Instructor Created',
                          message: 'Account created successfully.\n\nEmail: ${emailCtrl.text.trim()}\nDefault Password: $defaultPassword\n\nShare these credentials with the instructor.',
                        );
                      } on AuthException catch (e) {
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        AppDialog.alert(context, title: 'Error', message: e.message ?? 'Failed to create instructor.');
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
