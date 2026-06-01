import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:html' as html;

import '../../../../core/state/app_state.dart';
import '../../data/repositories/student_repository.dart';
import '../../domain/models/student_subject.dart';
import '../../../professor/domain/models/professor_subject.dart';
import '../widgets/student_floating_nav_bar.dart';
import 'student_assignment_detail_screen.dart';
import 'student_quiz_screen.dart';

class StudentModulesScreen extends StatefulWidget {
  const StudentModulesScreen({super.key});

  @override
  State<StudentModulesScreen> createState() => _StudentModulesScreenState();
}

class _StudentModulesScreenState extends State<StudentModulesScreen> {
  final StudentRepository _repo = const StudentRepository();
  bool _loading = true;
  List<StudentSubject> _subjects = [];
  Map<String, dynamic>? _studentProfile;

  // Selected subject for detail view (Screenshot 4 right)
  StudentSubject? _selectedSubject;
  List<SubjectModule> _selectedModules = [];
  List<SubjectQuiz> _quizzes = [];
  List<SubjectAssignment> _assignments = [];
  bool _loadingModules = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final profile = await _repo.fetchStudentProfile();
      final subjects = await _repo.fetchEnrolledSubjects();
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

  Future<void> _handleSubjectSelect(StudentSubject sub) async {
    setState(() {
      _selectedSubject = sub;
      _loadingModules = true;
      _selectedModules = [];
      _quizzes = [];
      _assignments = [];
    });

    try {
      final list = await _repo.fetchModules(sub.id);
      final assignments = await _repo.fetchAssignments(sub.id);
      final quizzes = await _repo.fetchQuizzes(sub.id);
      if (mounted) {
        setState(() {
          _selectedModules = list;
          _assignments = assignments;
          _quizzes = quizzes;
          _loadingModules = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingModules = false);
    }
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

                // Dynamic Header / Breadcrumb title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      if (_selectedSubject != null) ...[
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0A5C36), size: 20),
                          onPressed: () {
                            setState(() {
                              _selectedSubject = null;
                            });
                          },
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        _selectedSubject == null ? 'Learning Modules' : _selectedSubject!.name.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A5C36),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Main body content (List of courses or List of lessons)
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _selectedSubject == null
                          ? _buildSubjectList()
                          : _buildModulesList(),
                ),
              ],
            ),
          ),
          const StudentFloatingNavBar(currentIndex: 2),
        ],
      ),
    );
  }

  Widget _buildSubjectList() {
    if (_subjects.isEmpty) {
      return const Center(child: Text('No courses assigned.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: _subjects.length,
      itemBuilder: (context, index) {
        final dbMatch = _subjects[index];

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFEEEEEE)),
          ),
          child: InkWell(
            onTap: () => _handleSubjectSelect(dbMatch),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Row(
                children: [
                  const Icon(Icons.book_rounded, color: Color(0xFF0A5C36), size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      dbMatch.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModulesList() {
    if (_loadingModules) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_selectedModules.isEmpty && _quizzes.isEmpty && _assignments.isEmpty) {
      return const Center(child: Text('No modules or content uploaded yet.'));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        ..._selectedModules.asMap().entries.map((entry) {
          final i = entry.key;
          final m = entry.value;
          final mQuizzes = _quizzes.where((q) => q.moduleId == m.id).toList();
          final mAssign = _assignments.where((a) => a.moduleId == m.id && !(a.description ?? '').startsWith('[MATERIAL]')).toList();
          final mMaterials = _assignments.where((a) => a.moduleId == m.id && (a.description ?? '').startsWith('[MATERIAL]')).toList();

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Module ${i + 1} - ${m.title}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0A5C36)),
                ),
                if (m.description != null && m.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    m.description!,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
                const SizedBox(height: 12),

                // Legacy module file (if any)
                if (m.fileUrl != null)
                  _buildStudentContentRow(
                    Icons.menu_book_rounded,
                    m.fileName ?? '${m.title} - Document',
                    'Material',
                    () => _openUrl(m.fileUrl!),
                  ),

                // Materials (new style)
                ...mMaterials.map((mat) => _buildStudentContentRow(
                      Icons.menu_book_rounded,
                      mat.fileName ?? '${mat.title} - Document',
                      'Material',
                      () {
                        if (mat.fileUrl != null) _openUrl(mat.fileUrl!);
                      },
                    )),

                // Quizzes
                ...mQuizzes.map((q) => _buildStudentContentRow(
                      Icons.quiz_rounded,
                      q.title,
                      'Quiz',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StudentQuizScreen(
                              subject: _selectedSubject!,
                              assignment: SubjectAssignment(
                                id: q.id,
                                title: q.title,
                                description: q.description,
                                deadline: q.deadline,
                                moduleId: q.moduleId,
                              ),
                            ),
                          ),
                        );
                      },
                    )),

                // Assignments
                ...mAssign.map((a) => _buildStudentContentRow(
                      Icons.assignment_rounded,
                      a.title,
                      'Assignment',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StudentAssignmentDetailScreen(
                              subject: _selectedSubject!,
                              assignment: a,
                            ),
                          ),
                        );
                      },
                    )),
              ],
            ),
          );
        }).toList(),
        // Unlinked quizzes
        ..._quizzes.where((q) => q.moduleId == null).map((q) => _buildStudentContentRow(
              Icons.quiz_rounded,
              q.title,
              'Quiz',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentQuizScreen(
                      subject: _selectedSubject!,
                      assignment: SubjectAssignment(
                        id: q.id,
                        title: q.title,
                        description: q.description,
                        deadline: q.deadline,
                        moduleId: q.moduleId,
                      ),
                    ),
                  ),
                );
              },
            )),
        // Unlinked assignments
        ..._assignments.where((a) => a.moduleId == null && !(a.description ?? '').startsWith('[MATERIAL]')).map((a) => _buildStudentContentRow(
              Icons.assignment_rounded,
              a.title,
              'Assignment',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentAssignmentDetailScreen(
                      subject: _selectedSubject!,
                      assignment: a,
                    ),
                  ),
                );
              },
            )),
        // Unlinked materials
        ..._assignments.where((a) => a.moduleId == null && (a.description ?? '').startsWith('[MATERIAL]')).map((mat) => _buildStudentContentRow(
              Icons.menu_book_rounded,
              mat.fileName ?? '${mat.title} - Document',
              'Material',
              () {
                if (mat.fileUrl != null) _openUrl(mat.fileUrl!);
              },
            )),
      ],
    );
  }

  Widget _buildStudentContentRow(IconData icon, String title, String type, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF0A5C36).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: const Color(0xFF0A5C36)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87))),
            Text(type, style: const TextStyle(fontSize: 11, color: Colors.black38)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, size: 16, color: Colors.black26),
          ]),
        ),
      ),
    );
  }

  void _openUrl(String url) {
    html.window.open(url, '_blank');
  }

}
