import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/state/app_state.dart';
import '../../data/repositories/professor_repository.dart';
import '../../domain/models/professor_subject.dart';
import '../widgets/professor_floating_nav_bar.dart';
import 'assignment_detail_screen.dart';

class ProfessorAssignmentsScreen extends StatefulWidget {
  const ProfessorAssignmentsScreen({super.key});

  @override
  State<ProfessorAssignmentsScreen> createState() => _ProfessorAssignmentsScreenState();
}

class _ProfessorAssignmentsScreenState extends State<ProfessorAssignmentsScreen> {
  final _repo = const ProfessorRepository();
  bool _loading = true;
  List<_AssignmentRowData> _activeAssignments = [];
  List<_AssignmentRowData> _inactiveAssignments = [];
  int _activePage = 0;
  int _inactivePage = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final subjects = await _repo.fetchMySubjects();
      final List<_AssignmentRowData> activeTemp = [];
      final List<_AssignmentRowData> inactiveTemp = [];
      final now = DateTime.now();

      for (final sub in subjects) {
        final assignList = await _repo.fetchAssignments(sub.id);
        for (final a in assignList) {
          final count = await _repo.fetchAssignmentSubmissionCount(a.id);
          final row = _AssignmentRowData(
            subjectId: sub.id,
            subjectName: sub.name,
            classCode: sub.classLabel,
            title: a.title,
            progressText: '$count/${sub.studentCount}',
            progressValue: sub.studentCount > 0 ? count / sub.studentCount : 0.0,
            dueDate: a.deadline != null
                ? '${a.deadline!.month.toString().padLeft(2, '0')}/${a.deadline!.day.toString().padLeft(2, '0')}/${a.deadline!.year}'
                : 'No Deadline',
            assignment: a,
            studentCount: sub.studentCount,
          );

          if (a.deadline == null || !now.isAfter(a.deadline!)) {
            activeTemp.add(row);
          } else {
            inactiveTemp.add(row);
          }
        }
      }

      // Auto-delete inactive assignments past 30 days
      final List<_AssignmentRowData> remainingInactive = [];
      for (final row in inactiveTemp) {
        final deadline = row.assignment.deadline!;
        if (now.difference(deadline).inDays > 30) {
          await _repo.deleteAssignment(row.assignment.id);
        } else {
          remainingInactive.add(row);
        }
      }

      // Limit inactive assignments to 30 (delete oldest if > 30)
      if (remainingInactive.length > 30) {
        remainingInactive.sort((x, y) => x.assignment.deadline!.compareTo(y.assignment.deadline!));
        final toDeleteCount = remainingInactive.length - 30;
        for (int i = 0; i < toDeleteCount; i++) {
          await _repo.deleteAssignment(remainingInactive[i].assignment.id);
        }
        remainingInactive.removeRange(0, toDeleteCount);
      }

      if (mounted) {
        setState(() {
          _activeAssignments = activeTemp;
          _inactiveAssignments = remainingInactive;
          _loading = false;

          final int maxActivePage = (_activeAssignments.length / 5).ceil() - 1;
          if (_activePage > maxActivePage) {
            _activePage = maxActivePage < 0 ? 0 : maxActivePage;
          }
          final int maxInactivePage = (_inactiveAssignments.length / 5).ceil() - 1;
          if (_inactivePage > maxInactivePage) {
            _inactivePage = maxInactivePage < 0 ? 0 : maxInactivePage;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: AppBar(
          backgroundColor: AppColors.authPrimary,
          elevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      Icon(Icons.school, color: Colors.white, size: 28),
                      SizedBox(height: 2),
                      Text(
                        'STUDFY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    user?.displayName ?? 'Archie Arevalo',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      children: [
                        // Title
                        const Text(
                          'Assignments',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.authPrimary,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Active Assignments Title
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.assignment_turned_in_rounded, color: Colors.green, size: 18),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Active Assignments',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildAssignmentTable(
                          _activeAssignments,
                          'No active assignments.',
                          _activePage,
                          (newPage) => setState(() => _activePage = newPage),
                        ),

                        const SizedBox(height: 24),

                        // Inactive Assignments Title
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.assignment_late_rounded, color: Colors.red, size: 18),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Inactive Assignments (Past Deadline)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildAssignmentTable(
                          _inactiveAssignments,
                          'No inactive assignments.',
                          _inactivePage,
                          (newPage) => setState(() => _inactivePage = newPage),
                        ),
                      ],
                    ),
                  ),
          ),
          const ProfessorFloatingNavBar(currentIndex: 3),
        ],
      ),
    );
  }

  Widget _buildAssignmentTable(
    List<_AssignmentRowData> list,
    String emptyMessage,
    int currentPage,
    void Function(int) onPageChanged,
  ) {
    final int itemsPerPage = 5;
    final int totalItems = list.length;
    final int pageCount = (totalItems / itemsPerPage).ceil();
    
    // Paginated list
    final paginatedList = list.skip(currentPage * itemsPerPage).take(itemsPerPage).toList();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Row(
              children: const [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Class',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF1D4E8F),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Assignment',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF1D4E8F),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Progress',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF1D4E8F),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Due Date',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF1D4E8F),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Dynamic or Fallback Rows
          if (paginatedList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  emptyMessage,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else ...[
            ...paginatedList.map((aData) => _buildTableRow(aData)),
            if (pageCount > 1) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: Colors.black12),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Page ${currentPage + 1} of $pageCount',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: currentPage > 0
                            ? () => onPageChanged(currentPage - 1)
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
                            ? () => onPageChanged(currentPage + 1)
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
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildTableRow(_AssignmentRowData aData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          // Navigate to Assignment Detail Screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AssignmentDetailScreen(
                assignment: aData.assignment,
                subjectName: aData.subjectName,
                totalStudents: aData.studentCount,
                courseYearSection: aData.classCode,
              ),
            ),
          ).then((_) => _load());
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              // Class
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      aData.subjectName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      aData.classCode,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              // Assignment Name and subtitle
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      aData.title.split('\n')[0],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    if (aData.title.contains('\n'))
                      Text(
                        aData.title.split('\n')[1],
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),

              // Progress text and green bar
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      aData.progressText,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 80,
                      height: 8,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: aData.progressValue,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Due Date
              Expanded(
                flex: 2,
                child: Text(
                  aData.dueDate,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssignmentRowData {
  final String subjectId;
  final String subjectName;
  final String classCode;
  final String title;
  final String progressText;
  final double progressValue;
  final String dueDate;
  final SubjectAssignment assignment;
  final int studentCount;

  _AssignmentRowData({
    required this.subjectId,
    required this.subjectName,
    required this.classCode,
    required this.title,
    required this.progressText,
    required this.progressValue,
    required this.dueDate,
    required this.assignment,
    required this.studentCount,
  });
}
