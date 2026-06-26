import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/utils/upper_case_text_formatter.dart';
import '../../domain/models/instructor.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../auth/domain/models/auth_exception.dart' as app_auth;
import '../widgets/admin_floating_nav_bar.dart';

class AdminInstructorScreen extends StatefulWidget {
  const AdminInstructorScreen({super.key});

  @override
  State<AdminInstructorScreen> createState() => _AdminInstructorScreenState();
}

class _AdminInstructorScreenState extends State<AdminInstructorScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String? _selectedDepartment;
  late ScrollController _scrollController;
  bool _showStickyFilter = false;
  int _currentPage = 0;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      final double offset = _scrollController.offset;
      final bool shouldShow = offset > 240; // threshold when top filters scroll out
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
    _searchCtrl.dispose();
    super.dispose();
  }

  void _filterList() {
    setState(() {
      _currentPage = 0;
    });
  }

  void _clearFilters() {
    _searchCtrl.clear();
    setState(() {
      _selectedDepartment = null;
      _currentPage = 0;
    });
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
      pathParameters: {'profileId': instructor.profileId},
      extra: {'instructor': instructor, 'request': null},
    );
  }

  Future<void> _resolveRequest({required String requestId, required bool approve, required String action}) async {
    try {
      await context.read<AppState>().resolveInstructorRequest(requestId: requestId, approve: approve);
      if (!mounted) return;
      String pastTense = action;
      if (action.toLowerCase() == 'confirm') {
        pastTense = 'confirmed';
      } else if (action.toLowerCase() == 'deny') {
        pastTense = 'denied';
      } else if (action.toLowerCase() == 'approve') {
        pastTense = 'approved';
      } else if (action.toLowerCase() == 'reject') {
        pastTense = 'rejected';
      }
      await AppDialog.result(context, type: approve ? DialogType.success : DialogType.error, message: 'Request $pastTense successfully.');
    } on app_auth.AuthException catch (e) {
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
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
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
                          'Instructor Directory',
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
                                    '${filtered.length} Total',
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
                              onPressed: _showAddDialog,
                              icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 18),
                              label: const Text('Add Instructor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

                    // Pending requests section
                    _sectionLabel('Pending Requests'),
                    const SizedBox(height: 8),
                    _buildPendingRequests(appState),
                    const SizedBox(height: 28),

                    // Filter Card
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
                                flex: 2,
                                child: Container(
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F6F9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: TextField(
                                    controller: _searchCtrl,
                                    onChanged: (_) => _filterList(),
                                    decoration: InputDecoration(
                                      hintText: 'Search by instructor name...',
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
                                child: DropdownButtonFormField<String>(
                                  value: _selectedDepartment,
                                  hint: const Text('Filter by Department', style: TextStyle(fontSize: 13)),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xFFF5F6F9),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  items: deptList.map((dept) {
                                    return DropdownMenuItem(
                                      value: dept,
                                      child: Text(dept, style: const TextStyle(fontSize: 13)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedDepartment = val;
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

                    // Instructor list
                    _buildInstructorList(filtered),
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
                                controller: _searchCtrl,
                                onChanged: (_) => _filterList(),
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
                                  value: _selectedDepartment,
                                  hint: const Text('Department', style: TextStyle(fontSize: 12)),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedDepartment = val;
                                    });
                                    _filterList();
                                  },
                                  items: [
                                    const DropdownMenuItem<String>(value: null, child: Text('All Departments', style: TextStyle(fontSize: 12))),
                                    ...deptList.map((dept) => DropdownMenuItem<String>(
                                      value: dept,
                                      child: Text(dept, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                                    )),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: _clearFilters,
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
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.adminPrimary,
          ),
        ),
      );

  Widget _buildPendingRequests(AppState appState) {
    return ValueListenableBuilder<List<Map<String, String>>>(
      valueListenable: appState.pendingInstructorRequestsNotifier,
      builder: (context, requests, _) {
        if (requests.isEmpty) {
          return Container(
            width: 450,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 36, color: Colors.green.shade300),
                const SizedBox(height: 8),
                Text(
                  'All instructor requests resolved',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
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
    final kind = r['kind'] ?? '';
    final isUnenroll = kind == 'student_unenroll';
    final requesterName = r['requester_name'] ?? 'Professor';
    
    final displayTitle = isUnenroll ? requesterName : name;
    final displaySubtitle = isUnenroll ? 'Request (un-enrol student)' : status;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _showRequestDetailsDialog(r),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.adminPrimary.withValues(alpha: 0.08),
                    child: const Icon(Icons.person, color: AppColors.adminPrimary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(displaySubtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        if (isUnenroll) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Student: $name',
                            style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: const Text(
                      'Pending Approval',
                      style: TextStyle(color: Color(0xFFB8860B), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (isUnenroll) ...[
                    Expanded(
                      child: _actionBtn(
                        'Confirm',
                        Icons.check,
                        Colors.green,
                        () => _resolveRequest(
                          requestId: requestId,
                          approve: true,
                          action: 'Confirm',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _actionBtn(
                        'Deny',
                        Icons.close,
                        Colors.red,
                        () async {
                          await AppDialog.password(
                            context,
                            title: 'Authorize Denial',
                            message: 'Please enter your password to deny the unenrollment request.',
                            onConfirm: (enteredPassword) async {
                              if (enteredPassword.isEmpty) {
                                throw Exception('Password cannot be empty');
                              }
                              try {
                                final adminEmail = Supabase.instance.client.auth.currentUser?.email;
                                if (adminEmail == null) {
                                  throw Exception('Admin email not found. Please log in again.');
                                }
                                // Re-authenticate current admin
                                await Supabase.instance.client.auth.signInWithPassword(
                                  email: adminEmail,
                                  password: enteredPassword,
                                );
                                // Resolve the request as denied
                                await _resolveRequest(
                                  requestId: requestId,
                                  approve: false,
                                  action: 'Deny',
                                );
                              } on AuthException catch (e) {
                                if (context.mounted) {
                                  await AppDialog.result(
                                    context,
                                    type: DialogType.error,
                                    message: e.message,
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  await AppDialog.result(
                                    context,
                                    type: DialogType.error,
                                    message: e.toString().replaceAll('Exception: ', ''),
                                  );
                                }
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: _actionBtn(
                        'Approve',
                        Icons.check,
                        Colors.green,
                        () => _resolveRequest(
                          requestId: requestId,
                          approve: true,
                          action: 'Approve',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _actionBtn(
                        'Reject',
                        Icons.close,
                        Colors.red,
                        () => _resolveRequest(
                          requestId: requestId,
                          approve: false,
                          action: 'Reject',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _actionBtn(
                        'View Profile',
                        Icons.arrow_forward_rounded,
                        AppColors.adminPrimary,
                        () {
                          final instructors = context.read<AppState>().instructors;
                          if (instructors.isEmpty) return;
                          final instructor = instructors.firstWhere((i) => i.name == name, orElse: () => instructors.first);
                          _goToProfile(instructor);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRequestDetailsDialog(Map<String, String> r) {
    final kind = r['kind'] ?? '';
    final isUnenroll = kind == 'student_unenroll';
    final name = r['name'] ?? '';
    final requesterName = r['requester_name'] ?? 'Professor';
    final details = r['details'] ?? '';
    final reason = r['reason'] ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFF8F9FC),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.adminPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.info_outline_rounded, color: AppColors.adminPrimary, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Request Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Requester', isUnenroll ? requesterName : name),
            const SizedBox(height: 12),
            _buildDetailRow('Request Type', isUnenroll ? 'Un-enrol student' : r['status'] ?? ''),
            if (isUnenroll) ...[
              const SizedBox(height: 12),
              _buildDetailRow('Student Name', name),
            ],
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'Message / Reason:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 450,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                isUnenroll 
                    ? (reason.isNotEmpty ? reason : 'No reason provided.')
                    : (details.isNotEmpty ? details : 'No details provided.'),
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Color(0xFF334155),
                ),
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: 450,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.adminPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 38,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructorList(List<Instructor> instructors) {
    if (instructors.isEmpty) {
      return Container(
        width: 450,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No instructors found',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    final int totalItems = instructors.length;
    final int pageCount = (totalItems / _pageSize).ceil();
    final int safePage = _currentPage.clamp(0, pageCount > 0 ? pageCount - 1 : 0);
    final pagedInstructors = instructors.skip(safePage * _pageSize).take(_pageSize).toList();

    return Column(
      children: [
        ...pagedInstructors.map((instructor) => _buildInstructorCard(instructor)),
        const SizedBox(height: 16),
        _buildPagination(
          totalItems: totalItems,
          pageCount: pageCount,
          currentPage: safePage,
        ),
      ],
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
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
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

  Widget _buildInstructorCard(Instructor instructor) {
    final String initials = instructor.name.isNotEmpty
        ? instructor.name.trim().split(' ').map((e) => e[0]).take(2).join('').toUpperCase()
        : 'I';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _goToProfile(instructor),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.adminPrimary.withValues(alpha: 0.08),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppColors.adminPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      instructor.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
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
                            instructor.course,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            instructor.subject,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddDialog() {
    final firstNameCtrl = TextEditingController();
    final lastNameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String? selectedDept;
    final deptList = context.read<AppState>().instructors.map((i) => i.course).toSet().where((c) => c.isNotEmpty).toList()..sort();
    if (!deptList.contains('BSIT')) deptList.add('BSIT');
    if (!deptList.contains('BSCS')) deptList.add('BSCS');
    if (!deptList.contains('BSCPE')) deptList.add('BSCPE');
    deptList.sort();
    bool isLoading = false;

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
                      color: AppColors.adminPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.adminPrimary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Add New Instructor',
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
                'Enter the instructor\'s credentials and department assignment details.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.normal),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
            ],
          ),
          content: Container(
            width: 450,
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
                    value: selectedDept,
                    hint: Text('Select Department', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    decoration: InputDecoration(
                      labelText: 'Department',
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
                    items: deptList.map((dept) {
                      return DropdownMenuItem(
                        value: dept,
                        child: Text(dept, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedDept = val;
                      });
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
                       if (firstNameCtrl.text.trim().isEmpty || lastNameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty || selectedDept == null) {
                        AppDialog.result(ctx, type: DialogType.error, message: 'Please fill in all required fields.');
                        return;
                      }
                      setDialogState(() => isLoading = true);
                      try {
                        final password = await context.read<AppState>().createInstructor(
                              firstName: firstNameCtrl.text,
                              lastName: lastNameCtrl.text,
                              email: emailCtrl.text,
                              department: selectedDept!,
                              instructorId: null,
                            );
                        if (!mounted) return;
                        final email = emailCtrl.text.trim();
                        Navigator.pop(ctx);
                        await AppDialog.result(
                          context,
                          type: DialogType.success,
                          message: 'Instructor created!\n\nEmail: $email\nPassword: $password',
                        );
                      } on app_auth.AuthException catch (e) {
                        setDialogState(() => isLoading = false);
                        await AppDialog.result(ctx, type: DialogType.error, message: e.message ?? 'Failed to create instructor.');
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        await AppDialog.result(ctx, type: DialogType.error, message: e.toString());
                      }
                    },
              child: isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('Create Instructor', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
