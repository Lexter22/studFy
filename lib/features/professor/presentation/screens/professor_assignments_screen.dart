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
  List<_AssignmentRowData> _assignments = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final subjects = await _repo.fetchMySubjects();
      final List<_AssignmentRowData> temp = [];

      for (final sub in subjects) {
        final assignList = await _repo.fetchAssignments(sub.id);
        for (final a in assignList) {
          final count = await _repo.fetchAssignmentSubmissionCount(a.id);
          temp.add(_AssignmentRowData(
            subjectId: sub.id,
            subjectName: sub.name,
            classCode: '${sub.courseCode} ${sub.yearLevel}-${sub.section}',
            title: a.title,
            progressText: '$count/${sub.studentCount}',
            progressValue: sub.studentCount > 0 ? count / sub.studentCount : 0.0,
            dueDate: a.deadline != null
                ? '${a.deadline!.month.toString().padLeft(2, '0')}/${a.deadline!.day.toString().padLeft(2, '0')}/${a.deadline!.year}'
                : 'No Deadline',
            assignment: a,
            studentCount: sub.studentCount,
          ));
        }
      }

      if (mounted) {
        setState(() {
          _assignments = temp;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<_AssignmentRowData> get _displayAssignments {
    return _assignments;
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
                          'Assignment',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.authPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Assignment Table Container
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black.withOpacity(0.05)),
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
                              ..._displayAssignments.map((aData) => _buildTableRow(aData)),
                            ],
                          ),
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
                child: Text(
                  aData.classCode,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
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
