import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/app_state.dart';
import '../../data/repositories/student_repository.dart';
import '../../domain/models/student_subject.dart';
import '../../../professor/domain/models/professor_subject.dart';
import '../widgets/student_floating_nav_bar.dart';
import 'student_assignment_detail_screen.dart';
import 'student_quiz_screen.dart';

class StudentTodoScreen extends StatefulWidget {
  const StudentTodoScreen({super.key});

  @override
  State<StudentTodoScreen> createState() => _StudentTodoScreenState();
}

class _StudentTodoScreenState extends State<StudentTodoScreen> with SingleTickerProviderStateMixin {
  final StudentRepository _repo = const StudentRepository();
  late TabController _tabController;
  bool _loading = true;
  List<StudentSubject> _subjects = [];
  Map<String, dynamic>? _studentProfile;

  // Track state of assignment submissions
  final Map<String, bool> _submittedAssignments = {};
  final Map<String, List<SubjectAssignment>> _subjectAssignments = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final profile = await _repo.fetchStudentProfile();
      final subjects = await _repo.fetchEnrolledSubjects();
      
      // Fetch submissions status
      for (final sub in subjects) {
        final assignments = await _repo.fetchAssignments(sub.id);
        final filtered = assignments.where((a) => !(a.description ?? '').startsWith('[MATERIAL]')).toList();
        _subjectAssignments[sub.id] = filtered;
        for (final ass in filtered) {
          final isSubmitted = await _repo.checkSubmission(ass.id);
          _submittedAssignments[ass.id] = isSubmitted;
        }
      }

      if (!mounted) return;
      setState(() {
        _studentProfile = profile;
        _subjects = subjects;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appUser = context.watch<AppState>().currentUser;
    final String studentName = appUser?.displayName ?? 'Ayisha Romulo';
    final String courseSection = _studentProfile?['year_section'] ?? 'BSIT 3-1';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: AppBar(
          backgroundColor: const Color(0xFF0A5C36),
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
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        studentName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        courseSection,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Section title
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'To Do',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A5C36),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Custom Tab Bar matching styling in Screenshot 2
                TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF0A5C36),
                  labelColor: const Color(0xFF0A5C36),
                  unselectedLabelColor: Colors.black54,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  tabs: const [
                    Tab(text: 'Active'),
                    Tab(text: 'Missing'),
                    Tab(text: 'Done'),
                  ],
                ),

                // Tab Content
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildActiveList(),
                            _buildMissingList(),
                            _buildDoneList(),
                          ],
                        ),
                ),
              ],
            ),
          ),
          const StudentFloatingNavBar(currentIndex: 1),
        ],
      ),
    );
  }

  Widget _buildActiveList() {
    final active = _getAssignments(isDone: false, isMissing: false);
    if (active.isEmpty) {
      return const Center(child: Text('No active assignments. All caught up!', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: active.length,
      itemBuilder: (context, index) {
        final item = active[index];
        return _buildAssignmentCard(item['subject'] as StudentSubject, item['assignment'] as SubjectAssignment);
      },
    );
  }

  Widget _buildMissingList() {
    final missing = _getAssignments(isDone: false, isMissing: true);
    if (missing.isEmpty) {
      return const Center(child: Text('No missing assignments. Good job!', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: missing.length,
      itemBuilder: (context, index) {
        final item = missing[index];
        return _buildAssignmentCard(item['subject'] as StudentSubject, item['assignment'] as SubjectAssignment, isMissing: true);
      },
    );
  }

  Widget _buildDoneList() {
    final done = _getAssignments(isDone: true, isMissing: false);
    if (done.isEmpty) {
      return const Center(child: Text('No completed assignments yet. Get started!', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: done.length,
      itemBuilder: (context, index) {
        final item = done[index];
        return _buildAssignmentCard(item['subject'] as StudentSubject, item['assignment'] as SubjectAssignment, isDone: true);
      },
    );
  }

  List<Map<String, dynamic>> _getAssignments({required bool isDone, required bool isMissing}) {
    final List<Map<String, dynamic>> results = [];
    final now = DateTime.now();

    for (final sub in _subjects) {
      final List<SubjectAssignment> list = _subjectAssignments[sub.id] ?? [];

      for (final ass in list) {
        final bool submitted = _submittedAssignments[ass.id] ?? false;
        final bool isPastDeadline = ass.deadline != null && ass.deadline!.isBefore(now);

        if (isDone && submitted) {
          results.add({'subject': sub, 'assignment': ass});
        } else if (isMissing && !submitted && isPastDeadline) {
          results.add({'subject': sub, 'assignment': ass});
        } else if (!isDone && !isMissing && !submitted && !isPastDeadline) {
          results.add({'subject': sub, 'assignment': ass});
        }
      }
    }
    return results;
  }

  Widget _buildAssignmentCard(StudentSubject sub, SubjectAssignment ass, {bool isDone = false, bool isMissing = false}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFEEEEEE)),
      ),
      child: InkWell(
        onTap: () => _handleAssignmentTap(sub, ass),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon Container matching Screenshot 2 style (edit/clipboard icon)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isMissing ? Colors.red : const Color(0xFF0A5C36),
                    width: 2,
                  ),
                ),
                child: Icon(
                  ass.id.contains('quiz') ? Icons.quiz_rounded : Icons.edit_note_rounded,
                  color: isMissing ? Colors.red : const Color(0xFF0A5C36),
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),

              // Title and Subject
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sub.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isMissing ? Colors.red : const Color(0xFF0A5C36),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ass.title,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Due Date label
              Text(
                ass.deadline != null ? 'May 09' : 'May 09', // Static like the design
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleAssignmentTap(StudentSubject sub, SubjectAssignment ass) async {
    if (ass.id.contains('quiz')) {
      // Open Quiz Screen
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudentQuizScreen(subject: sub, assignment: ass),
        ),
      );
    } else {
      // Open Assignment Detail / Submission Screen
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudentAssignmentDetailScreen(subject: sub, assignment: ass),
        ),
      );
    }
    _loadData(); // Reload submissions
  }

}
