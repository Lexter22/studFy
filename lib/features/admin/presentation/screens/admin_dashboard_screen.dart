import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/state/app_state.dart';
import '../../../auth/domain/models/auth_exception.dart';
import '../../../auth/domain/services/auth_service.dart';
import '../../domain/models/instructor.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../widgets/admin_floating_nav_bar.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {

  // ── Pop-up Helpers ──────────────────────────────────────────────────────

  void _showResolveDialog({
    required String requestId,
    required String name,
    required bool approve,
  }) {
    AppDialog.confirm(
      context,
      title: approve ? 'Approve Request' : 'Reject Request',
      message:
          'Are you sure you want to ${approve ? 'approve' : 'reject'} the request from "$name"?',
      type: approve ? DialogType.success : DialogType.error,
      confirmLabel: approve ? 'Approve' : 'Reject',
      onConfirm: () =>
          _resolveRequest(requestId: requestId, name: name, approve: approve),
    );
  }

  Future<void> _resolveRequest({
    required String requestId,
    required String name,
    required bool approve,
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
        message:
            'Request from "$name" has been ${approve ? 'approved' : 'rejected'}.',
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
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 16.0,
              bottom: 100.0,
            ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF800000),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // OVERVIEW CARDS
                      _buildOverviewCards(appState),

                      const SizedBox(height: 24),
                      _buildSectionTitle('Instructor'),

                      ValueListenableBuilder<List<Map<String, String>>>(
                        valueListenable:
                            appState.pendingInstructorRequestsNotifier,
                        builder: (context, pendingRequests, child) {
                          if (pendingRequests.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 24),
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

                          return _buildFixedList(
                            pendingRequests.map((request) {
                              final requestId = request['id'] ?? '';
                              final name = request['name'] ?? '';
                              final status = request['status'] ?? '';
                              return _buildActionListItem(
                                requestId,
                                name,
                                status,
                              );
                            }).toList(),
                          );
                        },
                      ),

                      const SizedBox(height: 24),
                      _buildSectionTitle('Subjects'),
                      // SUBJECTS LIST (Pending Requests)
                      ValueListenableBuilder<List<Map<String, String>>>(
                        valueListenable: context
                            .read<AppState>()
                            .pendingSubjectRequestsNotifier,
                        builder: (context, pendingRequests, child) {
                          if (pendingRequests.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 24),
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
                          return _buildFixedList(
                            pendingRequests.map((request) {
                              final name = request['name'] ?? '';
                              final status = request['status'] ?? '';
                              return _buildSimpleListItem(
                                name,
                                status,
                                onTap: () {
                                  context.pushNamed(
                                    AppRoutes.adminSubjectsProfile,
                                    extra: {
                                      'subjectName': name,
                                      'courseSection': 'Pending',
                                      'professor': 'Admin',
                                      'pendingRequest': status,
                                    },
                                  );
                                },
                              );
                            }).toList(),
                          );
                        },
                      ),


                    ],
                  ),
                ),
                const AdminFloatingNavBar(currentIndex: 0),
              ],
            ),
          );
        }

  // --- OVERVIEW WIDGETS ---
  Widget _buildOverviewCards(AppState appState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatCard(
          Icons.assignment_ind,
          'Total\nInstructor',
          '${appState.instructors.length}',
          Colors.blue,
        ),
        _buildStatCard(
          Icons.book,
          'Total\nSubjects',
          '${appState.subjectOfferings.length}',
          Colors.orange,
        ),
        _buildStatCard(
          Icons.group,
          'Total\nStudents',
          '${appState.students.length}',
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String label,
    String count,
    Color color,
  ) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.30,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                count,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- LIST WIDGETS ---
  Widget _buildFixedList(List<Widget> children) {
    return Column(children: children);
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF800000),
        ),
      ),
    );
  }

  // UPDATED ACTION ITEM (Matching Image 2 Style)
  Widget _buildActionListItem(String requestId, String name, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                backgroundColor: Colors.grey.shade100,
                child: Icon(Icons.person, color: Colors.grey.shade400),
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
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      status,
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
                  () => _showResolveDialog(
                    requestId: requestId,
                    name: name,
                    approve: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionBtn(
                  'Reject',
                  Icons.close,
                  const Color(0xFFF8D7DA),
                  const Color(0xFFDC3545),
                  () => _showResolveDialog(
                    requestId: requestId,
                    name: name,
                    approve: false,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildViewDetailsBtn(() {
                  context.goNamed(
                    AppRoutes.adminInstructorProfile,
                    extra: <String, dynamic>{
                      'instructor': Instructor(
                        profileId: '', // Pending instructors have no assigned ID yet
                        name: name,
                        course: 'Pending',
                        subject: status,
                      ),
                      'request': status,
                    },
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleListItem(
    String name,
    String status, {
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.account_circle, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        status,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- SMALLER UI COMPONENTS ---
  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2EECF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        '● Pending',
        style: TextStyle(
          color: Color(0xFFBDA702),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // UPDATED BUTTON HELPERS (Matching Image 2 Layout)
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

}
