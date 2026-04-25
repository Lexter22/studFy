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
  final TextEditingController _searchCtrl = TextEditingController();
  String? _selectedDepartment;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _filterList() => setState(() {});

  void _clearFilters() {
    _searchCtrl.clear();
    setState(() => _selectedDepartment = null);
  }

  List<Instructor> _filtered(List<Instructor> source) {
    return source.where((i) {
      final nameMatch = i.name.toLowerCase().contains(_searchCtrl.text.toLowerCase());
      final deptMatch = _selectedDepartment == null || i.course == _selectedDepartment;
      return nameMatch && deptMatch;
    }).toList();
  }

  void _goToProfile(Instructor instructor) {
    context.pushNamed(
      AppRoutes.adminInstructorProfile,
      extra: {'instructor': instructor, 'request': null},
    );
  }

  Future<void> _resolveRequest({required String requestId, required bool approve, required String action}) async {
    try {
      await context.read<AppState>().resolveInstructorRequest(requestId: requestId, approve: approve);
      if (!mounted) return;
      await AppDialog.result(context, type: approve ? DialogType.success : DialogType.error, message: 'Request ${action.toLowerCase()}d successfully.');
    } on AuthException catch (e) {
      if (!mounted) return;
      await AppDialog.result(context, type: DialogType.error, message: e.message ?? 'Unable to process request.');
    } catch (e) {
      if (!mounted) return;
      await AppDialog.result(context, type: DialogType.error, message: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final filtered = _filtered(appState.instructors);
    final deptList = appState.instructors.map((i) => i.course).toSet().toList()..sort();

    return Scaffold(
      backgroundColor: AppColors.adminPageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.adminPrimary,
        elevation: 0,
        toolbarHeight: 70,
        title: const Row(children: [
          Icon(Icons.school, color: Colors.white, size: 28),
          SizedBox(width: 8),
          Text('STUDFY', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        ]),
        actions: const [
          Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Admin 1', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)))),
        ],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const AdminDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.adminPrimary,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Pending Requests'),
            _buildPendingRequests(appState),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Instructor List', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF800000))),
                  RichText(text: TextSpan(children: [
                    const TextSpan(text: 'Total: ', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    TextSpan(text: '${filtered.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF800000))),
                  ])),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildFilters(deptList),
            const SizedBox(height: 16),
            _buildTable(filtered),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(text, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF800000))),
  );

  Widget _buildPendingRequests(AppState appState) {
    return ValueListenableBuilder<List<Map<String, String>>>(
      valueListenable: appState.pendingInstructorRequestsNotifier,
      builder: (context, requests, _) {
        if (requests.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
            child: const Center(child: Text('No pending requests', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))),
          );
        }
        return Column(children: requests.map((r) => _buildRequestCard(r)).toList());
      },
    );
  }

  Widget _buildRequestCard(Map<String, String> r) {
    final requestId = r['id'] ?? '';
    final name = r['name'] ?? '';
    final status = r['status'] ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: Colors.grey.shade100, child: const Icon(Icons.person, color: Colors.grey)),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(status, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.amber.shade200)),
                child: const Text('Pending', style: TextStyle(color: Color(0xFFB8860B), fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _actionBtn('Approve', Icons.check, const Color(0xFF28A745), () => _resolveRequest(requestId: requestId, approve: true, action: 'Approve'))),
            const SizedBox(width: 8),
            Expanded(child: _actionBtn('Reject', Icons.close, const Color(0xFFDC3545), () => _resolveRequest(requestId: requestId, approve: false, action: 'Reject'))),
            const SizedBox(width: 8),
            Expanded(child: _actionBtn('View', Icons.chevron_right, AppColors.adminPrimary, () {
              final instructors = context.read<AppState>().instructors;
              if (instructors.isEmpty) return;
              final instructor = instructors.firstWhere((i) => i.name == name, orElse: () => instructors.first);
              _goToProfile(instructor);
            })),
          ]),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 36,
          alignment: Alignment.center,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ]),
        ),
      ),
    );
  }

  Widget _buildFilters(List<String> deptList) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 42,
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => _filterList(),
                decoration: InputDecoration(
                  hintText: 'Search by name...',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(8)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  hint: const Text('Department', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  value: _selectedDepartment,
                  isExpanded: true,
                  items: deptList.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (val) => setState(() { _selectedDepartment = val; }),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(onPressed: _clearFilters, icon: const Icon(Icons.filter_alt_off, color: Colors.black54), tooltip: 'Clear filters'),
        ],
      ),
    );
  }

  Widget _buildTable(List<Instructor> instructors) {
    if (instructors.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
        child: const Center(child: Text('No instructors found', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))),
      );
    }
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFF4F4F4),
            child: const Row(children: [
              Expanded(flex: 3, child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
              Expanded(flex: 2, child: Text('Department', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
              Expanded(flex: 3, child: Text('Subject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
              SizedBox(width: 24),
            ]),
          ),
          ...instructors.asMap().entries.map((e) {
            final isEven = e.key % 2 == 0;
            final i = e.value;
            return InkWell(
              onTap: () => _goToProfile(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: isEven ? Colors.white : const Color(0xFFF9F9F9),
                child: Row(children: [
                  Expanded(flex: 3, child: Text(i.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.adminPrimary))),
                  Expanded(flex: 2, child: Text(i.course, style: const TextStyle(fontSize: 13, color: Colors.black54))),
                  Expanded(flex: 3, child: Text(i.subject, style: const TextStyle(fontSize: 13, color: Colors.black54))),
                  const Icon(Icons.chevron_right, size: 18, color: Colors.black38),
                ]),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showAddDialog() {
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
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: firstNameCtrl, decoration: const InputDecoration(labelText: 'First Name')),
              TextField(controller: lastNameCtrl, decoration: const InputDecoration(labelText: 'Last Name')),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
              TextField(controller: deptCtrl, decoration: const InputDecoration(labelText: 'Department')),
              TextField(controller: instructorIdCtrl, decoration: const InputDecoration(labelText: 'Instructor ID (Optional)')),
            ]),
          ),
          actions: [
            TextButton(onPressed: isLoading ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (firstNameCtrl.text.trim().isEmpty || lastNameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty || deptCtrl.text.trim().isEmpty) {
                  AppDialog.result(ctx, type: DialogType.error, message: 'Please fill in all required fields.');
                  return;
                }
                setDialogState(() => isLoading = true);
                try {
                  final password = await context.read<AppState>().createInstructor(
                    firstName: firstNameCtrl.text,
                    lastName: lastNameCtrl.text,
                    email: emailCtrl.text,
                    department: deptCtrl.text,
                    instructorId: instructorIdCtrl.text,
                  );
                  if (!mounted) return;
                  final email = emailCtrl.text.trim();
                  Navigator.pop(ctx);
                  AppDialog.result(
                    context,
                    type: DialogType.success,
                    message: 'Instructor created!\n\nEmail: $email\nPassword: $password',
                  );
                } on AuthException catch (e) {
                  setDialogState(() => isLoading = false);
                  AppDialog.result(ctx, type: DialogType.error, message: e.message ?? 'Failed to create instructor.');
                } catch (e) {
                  setDialogState(() => isLoading = false);
                  AppDialog.result(ctx, type: DialogType.error, message: e.toString());
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
